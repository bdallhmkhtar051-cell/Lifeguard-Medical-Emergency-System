using System.IdentityModel.Tokens.Jwt;
using System.Text;
using EmergencySystem.Application.Administration;
using EmergencySystem.Application.Access;
using EmergencySystem.Application.Authentication;
using EmergencySystem.Application.Clinical;
using EmergencySystem.Application.Profiles;
using EmergencySystem.Application.Security;
using EmergencySystem.Domain.Identity;
using EmergencySystem.Infrastructure.Administration;
using EmergencySystem.Infrastructure.Access;
using EmergencySystem.Infrastructure.Authentication;
using EmergencySystem.Infrastructure.Clinical;
using EmergencySystem.Infrastructure.Configuration;
using EmergencySystem.Infrastructure.Identity;
using EmergencySystem.Infrastructure.Persistence;
using EmergencySystem.Infrastructure.Profiles;
using EmergencySystem.Infrastructure.Seeding;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace EmergencySystem.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:DefaultConnection must be configured.");
        }

        services
            .AddOptions<JwtOptions>()
            .Bind(configuration.GetRequiredSection(JwtOptions.SectionName))
            .Validate(
                options =>
                    !string.IsNullOrWhiteSpace(options.Issuer) &&
                    !string.IsNullOrWhiteSpace(options.Audience),
                "Jwt:Issuer and Jwt:Audience must be configured.")
            .Validate(
                options => Encoding.UTF8.GetByteCount(options.SigningKey) >= 32,
                "Jwt:SigningKey must contain at least 32 bytes and must be supplied through secrets or environment configuration.")
            .Validate(
                options => options.AccessTokenMinutes is >= 5 and <= 60,
                "Jwt:AccessTokenMinutes must be between 5 and 60.")
            .ValidateOnStart();
        services.Configure<DemoSeedOptions>(
            configuration.GetRequiredSection(DemoSeedOptions.SectionName));
        services.TryAddSingleton(TimeProvider.System);

        services.AddDbContext<ApplicationDbContext>(options =>
            options.UseSqlServer(connectionString));

        services
            .AddIdentityCore<ApplicationUser>(options =>
            {
                options.User.RequireUniqueEmail = true;
                options.Password.RequiredLength = 12;
                options.Password.RequireDigit = true;
                options.Password.RequireLowercase = true;
                options.Password.RequireUppercase = true;
                options.Password.RequireNonAlphanumeric = true;
                options.Lockout.AllowedForNewUsers = true;
                options.Lockout.MaxFailedAccessAttempts = 5;
                options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
            })
            .AddRoles<IdentityRole<Guid>>()
            .AddEntityFrameworkStores<ApplicationDbContext>()
            .AddSignInManager()
            .AddDefaultTokenProviders();

        services
            .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer();
        services
            .AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
            .Configure<IOptions<JwtOptions>>((options, jwtOptionsAccessor) =>
            {
                var jwtOptions = jwtOptionsAccessor.Value;
                var signingKey = new SymmetricSecurityKey(
                    Encoding.UTF8.GetBytes(jwtOptions.SigningKey));
                options.MapInboundClaims = false;
                options.RequireHttpsMetadata = true;
                options.SaveToken = false;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = jwtOptions.Issuer,
                    ValidateAudience = true,
                    ValidAudience = jwtOptions.Audience,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = signingKey,
                    ValidateLifetime = true,
                    RequireExpirationTime = true,
                    RequireSignedTokens = true,
                    ClockSkew = TimeSpan.FromSeconds(30),
                    NameClaimType = JwtRegisteredClaimNames.Email,
                    RoleClaimType = "role",
                    ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
                };
                options.Events = new JwtBearerEvents
                {
                    OnTokenValidated = ValidateActiveUserAsync,
                };
            });

        services.AddAuthorization(options =>
        {
            options.AddPolicy(
                AuthorizationPolicyNames.PatientOnly,
                policy => policy
                    .RequireAuthenticatedUser()
                    .RequireRole(RoleNames.Patient));
            options.AddPolicy(
                AuthorizationPolicyNames.DoctorOnly,
                policy => policy
                    .RequireAuthenticatedUser()
                    .RequireRole(RoleNames.Doctor));
            options.AddPolicy(
                AuthorizationPolicyNames.AdministratorOnly,
                policy => policy
                    .RequireAuthenticatedUser()
                    .RequireRole(RoleNames.Administrator));
        });

        services.AddScoped<IJwtTokenService, JwtTokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IEmergencyProfileService, EmergencyProfileService>();
        services.AddScoped<IEmergencyAccessService, EmergencyAccessService>();
        services.AddScoped<IClinicalRecordService, ClinicalRecordService>();
        services.AddScoped<IAdministrationService, AdministrationService>();
        services.AddScoped<IDemoDataSeeder, DemoDataSeeder>();

        return services;
    }

    private static async Task ValidateActiveUserAsync(
        TokenValidatedContext context)
    {
        var subject = context.Principal?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value;
        var securityStamp = context.Principal?.FindFirst("security_stamp")?.Value;
        if (!Guid.TryParse(subject, out var userId))
        {
            context.Fail("The token subject is invalid.");
            return;
        }

        var userManager = context.HttpContext.RequestServices
            .GetRequiredService<UserManager<ApplicationUser>>();
        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user is null ||
            !user.IsActive ||
            !string.Equals(
                user.SecurityStamp ?? string.Empty,
                securityStamp,
                StringComparison.Ordinal))
        {
            context.Fail("The account is no longer active.");
        }
    }
}
