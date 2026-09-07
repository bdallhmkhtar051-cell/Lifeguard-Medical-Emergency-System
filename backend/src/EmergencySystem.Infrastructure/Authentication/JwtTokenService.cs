using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using EmergencySystem.Infrastructure.Configuration;
using EmergencySystem.Infrastructure.Identity;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace EmergencySystem.Infrastructure.Authentication;

internal sealed record GeneratedAccessToken(
    string Value,
    long ExpiresInSeconds);

internal interface IJwtTokenService
{
    GeneratedAccessToken Create(
        ApplicationUser user,
        IReadOnlyCollection<string> roles);
}

internal sealed class JwtTokenService(
    IOptions<JwtOptions> options,
    TimeProvider timeProvider)
    : IJwtTokenService
{
    private readonly JwtOptions _options = options.Value;

    public GeneratedAccessToken Create(
        ApplicationUser user,
        IReadOnlyCollection<string> roles)
    {
        var now = timeProvider.GetUtcNow();
        var expires = now.AddMinutes(_options.AccessTokenMinutes);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Iat, now.ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
            new("security_stamp", user.SecurityStamp ?? string.Empty),
        };

        claims.AddRange(roles.Select(role => new Claim("role", role)));

        var signingKey = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_options.SigningKey));
        var credentials = new SigningCredentials(
            signingKey,
            SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: now.UtcDateTime,
            expires: expires.UtcDateTime,
            signingCredentials: credentials);

        return new GeneratedAccessToken(
            new JwtSecurityTokenHandler().WriteToken(token),
            (long)(expires - now).TotalSeconds);
    }
}
