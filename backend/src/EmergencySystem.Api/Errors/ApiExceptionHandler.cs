using EmergencySystem.Application.Common;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace EmergencySystem.Api.Errors;

public sealed class ApiExceptionHandler(
    ILogger<ApiExceptionHandler> logger)
    : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        ProblemDetails problem;
        switch (exception)
        {
            case RequestValidationException validationException:
                problem = new ValidationProblemDetails(
                    validationException.Errors.ToDictionary(
                        item => item.Key,
                        item => item.Value,
                        StringComparer.Ordinal))
                {
                    Status = StatusCodes.Status400BadRequest,
                    Title = "One or more validation errors occurred.",
                };
                break;

            case ProfilePreconditionFailedException:
                problem = new ProblemDetails
                {
                    Status = StatusCodes.Status412PreconditionFailed,
                    Title = "Profile precondition failed",
                    Detail = "Reload the emergency profile and retry with its current ETag.",
                };
                break;

            case AiServiceUnavailableException unavailable:
                problem = new ProblemDetails
                {
                    Status = StatusCodes.Status503ServiceUnavailable,
                    Title = "AI summary unavailable",
                    Detail = unavailable.Message,
                };
                break;

            default:
                logger.LogError(
                    exception,
                    "Unhandled API exception for {Method} {Path}. Trace {TraceIdentifier}",
                    httpContext.Request.Method,
                    httpContext.Request.Path,
                    httpContext.TraceIdentifier);
                problem = new ProblemDetails
                {
                    Status = StatusCodes.Status500InternalServerError,
                    Title = "An unexpected server error occurred.",
                };
                break;
        }

        problem.Instance = httpContext.Request.Path;
        problem.Extensions["traceId"] = httpContext.TraceIdentifier;
        httpContext.Response.StatusCode =
            problem.Status ?? StatusCodes.Status500InternalServerError;
        httpContext.Response.ContentType = "application/problem+json";
        await httpContext.Response.WriteAsJsonAsync(
            problem,
            options: null,
            contentType: "application/problem+json",
            cancellationToken);
        return true;
    }
}
