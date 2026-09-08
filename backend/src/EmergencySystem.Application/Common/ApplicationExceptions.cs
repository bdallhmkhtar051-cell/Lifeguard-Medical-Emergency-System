namespace EmergencySystem.Application.Common;

public sealed class RequestValidationException(
    IReadOnlyDictionary<string, string[]> errors)
    : Exception("One or more validation errors occurred.")
{
    public IReadOnlyDictionary<string, string[]> Errors { get; } = errors;
}

public sealed class ProfilePreconditionFailedException(
    Exception? innerException = null)
    : Exception(
        "The emergency profile changed or the requested resource state does not match.",
        innerException);

public sealed class AiServiceUnavailableException(string message)
    : Exception(message);
