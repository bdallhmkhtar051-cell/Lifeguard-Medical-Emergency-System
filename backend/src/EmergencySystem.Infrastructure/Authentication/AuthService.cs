using EmergencySystem.Application.Authentication;
using EmergencySystem.Infrastructure.Identity;
using EmergencySystem.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace EmergencySystem.Infrastructure.Authentication;

internal sealed class AuthService(
    UserManager<ApplicationUser> userManager,
    SignInManager<ApplicationUser> signInManager,
    ApplicationDbContext dbContext,
    IJwtTokenService jwtTokenService)
    : IAuthService
{
    public async Task<LoginResponse?> LoginAsync(
        string email,
        string password,
        CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();

        var user = await userManager.FindByEmailAsync(email.Trim());
        if (user is null || !user.IsActive)
        {
            return null;
        }

        var signInResult = await signInManager.CheckPasswordSignInAsync(
            user,
            password,
            lockoutOnFailure: true);
        if (!signInResult.Succeeded)
        {
            return null;
        }

        var roles = (await userManager.GetRolesAsync(user))
            .Order(StringComparer.Ordinal)
            .ToArray();
        var token = jwtTokenService.Create(user, roles);
        var hasEmergencyProfile = await dbContext.PatientProfiles
            .AsNoTracking()
            .AnyAsync(profile => profile.UserId == user.Id, cancellationToken);

        return new LoginResponse(
            token.Value,
            "Bearer",
            token.ExpiresInSeconds,
            MapUser(user, roles, hasEmergencyProfile));
    }

    public async Task<CurrentUserResponse?> GetCurrentUserAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var user = await userManager.FindByIdAsync(userId.ToString());
        if (user is null || !user.IsActive)
        {
            return null;
        }

        var roles = (await userManager.GetRolesAsync(user))
            .Order(StringComparer.Ordinal)
            .ToArray();
        var hasEmergencyProfile = await dbContext.PatientProfiles
            .AsNoTracking()
            .AnyAsync(profile => profile.UserId == user.Id, cancellationToken);

        return MapUser(user, roles, hasEmergencyProfile);
    }

    private static CurrentUserResponse MapUser(
        ApplicationUser user,
        IReadOnlyList<string> roles,
        bool hasEmergencyProfile) =>
        new(
            user.Id,
            user.Email ?? string.Empty,
            user.DisplayName,
            roles,
            hasEmergencyProfile);
}
