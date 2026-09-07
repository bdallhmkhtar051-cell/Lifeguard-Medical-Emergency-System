using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using EmergencySystem.Api.Errors;
using EmergencySystem.Api.RateLimiting;
using EmergencySystem.Infrastructure;
using EmergencySystem.Infrastructure.Seeding;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

builder.WebHost.ConfigureKestrel(options =>
{
    // The first slice accepts only small JSON documents; uploads will receive a
    // separate, deliberately bounded endpoint when that feature is introduced.
    options.Limits.MaxRequestBodySize = 64 * 1024;
});

builder.Services
    .AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new JsonStringEnumConverter(allowIntegerValues: false));
    });
builder.Services.AddOpenApi();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<ApiExceptionHandler>();
builder.Services.AddInfrastructure(builder.Configuration);

var allowedOrigins = builder.Configuration
    .GetSection("Cors:AllowedOrigins")
    .Get<string[]>()
    ?? [];
if (allowedOrigins.Length == 0 ||
    allowedOrigins.Any(origin =>
        !Uri.TryCreate(origin, UriKind.Absolute, out var uri) ||
        (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps) ||
        origin.Contains('*', StringComparison.Ordinal)))
{
    throw new InvalidOperationException(
        "Cors:AllowedOrigins must contain explicit HTTP or HTTPS origins without wildcards.");
}

builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "FlutterWeb",
        policy => policy
            .WithOrigins(allowedOrigins)
            .WithMethods("GET", "POST", "PUT", "OPTIONS")
            .WithHeaders("Authorization", "Content-Type", "If-Match", "If-None-Match")
            .WithExposedHeaders("ETag")
            .SetPreflightMaxAge(TimeSpan.FromMinutes(10)));
});

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy(
        RateLimitPolicyNames.Login,
        context => RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
                AutoReplenishment = true,
            }));
    options.AddPolicy(
        RateLimitPolicyNames.EmergencyOverride,
        context => RateLimitPartition.GetFixedWindowLimiter(
            context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 3,
                Window = TimeSpan.FromMinutes(5),
                QueueLimit = 0,
                AutoReplenishment = true,
            }));
    options.OnRejected = async (context, cancellationToken) =>
    {
        context.HttpContext.Response.ContentType = "application/problem+json";
        await context.HttpContext.Response.WriteAsJsonAsync(
            new ProblemDetails
            {
                Status = StatusCodes.Status429TooManyRequests,
                Title = "Too many requests",
                Detail = "Wait before trying again.",
                Instance = context.HttpContext.Request.Path,
            },
            options: null,
            contentType: "application/problem+json",
            cancellationToken);
    };
});

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages(async statusCodeContext =>
{
    var response = statusCodeContext.HttpContext.Response;
    if (!string.IsNullOrEmpty(response.ContentType) || response.ContentLength > 0)
    {
        return;
    }

    response.ContentType = "application/problem+json";
    await response.WriteAsJsonAsync(
        new ProblemDetails
        {
            Status = response.StatusCode,
            Title = response.StatusCode switch
            {
                StatusCodes.Status401Unauthorized => "Authentication required",
                StatusCodes.Status403Forbidden => "Access denied",
                StatusCodes.Status404NotFound => "Resource not found",
                _ => "Request failed",
            },
            Instance = statusCodeContext.HttpContext.Request.Path,
        },
        options: null,
        contentType: "application/problem+json");
});

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}
else if (!app.Environment.IsEnvironment("Testing"))
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseRouting();
app.UseCors("FlutterWeb");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapGet(
        "/health",
        () => Results.Ok(new
        {
            status = "healthy",
            service = "EmergencySystem.Api",
        }))
    .AllowAnonymous();
app.MapControllers();

if (app.Environment.IsDevelopment() &&
    builder.Configuration.GetValue<bool>("DemoSeed:Enabled"))
{
    await using var scope = app.Services.CreateAsyncScope();
    var seeder = scope.ServiceProvider.GetRequiredService<IDemoDataSeeder>();
    await seeder.SeedAsync();
}

app.Run();

// WebApplicationFactory uses this public partial entry point in API tests.
public partial class Program;
