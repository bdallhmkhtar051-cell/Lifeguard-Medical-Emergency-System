namespace EmergencySystem.Infrastructure.Seeding;

public interface IDemoDataSeeder
{
    Task SeedAsync(CancellationToken cancellationToken = default);
}
