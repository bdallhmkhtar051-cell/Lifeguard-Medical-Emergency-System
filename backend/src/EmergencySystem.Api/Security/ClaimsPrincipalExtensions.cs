using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace EmergencySystem.Api.Security;

public static class ClaimsPrincipalExtensions
{
    public static bool TryGetUserId(
        this ClaimsPrincipal principal,
        out Guid userId) =>
        Guid.TryParse(
            principal.FindFirstValue(JwtRegisteredClaimNames.Sub),
            out userId);
}
