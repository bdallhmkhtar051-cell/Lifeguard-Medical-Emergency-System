using EmergencySystem.Application.Access;

namespace EmergencySystem.Application.Tests;

public sealed class PermanentEmergencyQrPayloadTests
{
    [Fact]
    public void Created_payload_round_trips_the_identifier()
    {
        var identifier = Guid.Parse("41f0d2e4-b27d-4a30-927d-84676fe72311");

        var payload = PermanentEmergencyQrPayload.Create(identifier);
        var parsed = PermanentEmergencyQrPayload.TryParse(payload, out var result);

        Assert.True(parsed);
        Assert.Equal(identifier, result);
        Assert.Equal(
            "LIFEGUARD:EMERGENCY:1:41f0d2e4b27d4a30927d84676fe72311",
            payload);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("LIFEGUARD:EMERGENCY:1:")]
    [InlineData("LIFEGUARD:EMERGENCY:2:41f0d2e4b27d4a30927d84676fe72311")]
    [InlineData("LIFEGUARD:EMERGENCY:1:00000000000000000000000000000000")]
    [InlineData("https://example.test/41f0d2e4b27d4a30927d84676fe72311")]
    public void Invalid_or_unsupported_payload_is_rejected(string? payload)
    {
        Assert.False(PermanentEmergencyQrPayload.TryParse(payload, out _));
    }
}
