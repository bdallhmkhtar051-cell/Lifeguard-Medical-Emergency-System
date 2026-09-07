using System.ComponentModel.DataAnnotations;

namespace EmergencySystem.Application.Authentication;

public sealed class LoginRequest
{
    [Required]
    [EmailAddress]
    [StringLength(256)]
    public string Email { get; init; } = string.Empty;

    [Required]
    [StringLength(200)]
    public string Password { get; init; } = string.Empty;
}

public sealed record CurrentUserResponse(
    Guid Id,
    string Email,
    string DisplayName,
    IReadOnlyList<string> Roles,
    bool HasEmergencyProfile);

public sealed record LoginResponse(
    string AccessToken,
    string TokenType,
    long ExpiresInSeconds,
    CurrentUserResponse User);

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(
        string email,
        string password,
        CancellationToken cancellationToken = default);

    Task<CurrentUserResponse?> GetCurrentUserAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}
