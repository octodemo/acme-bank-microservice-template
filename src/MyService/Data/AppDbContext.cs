using Microsoft.EntityFrameworkCore;

namespace MyService.Data;

/// <summary>
/// Entity Framework Core database context for MyService.
/// </summary>
public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    /// <summary>
    /// Gets the sample records used by the template endpoints.
    /// </summary>
    public DbSet<Sample> Samples => Set<Sample>();

    /// <summary>
    /// Seeds deterministic local data when the service is using the in-memory database provider.
    /// </summary>
    public async Task SeedLocalSamplesAsync(CancellationToken ct = default)
    {
        if (!Database.IsInMemory() || await Samples.AnyAsync(ct))
        {
            return;
        }

        Samples.AddRange(
            new Sample
            {
                Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                Label = "starter-sample",
                CreatedAt = DateTimeOffset.Parse("2025-01-01T00:00:00+00:00")
            },
            new Sample
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                Label = "golden-path",
                CreatedAt = DateTimeOffset.Parse("2025-01-02T00:00:00+00:00")
            });

        await SaveChangesAsync(ct);
    }
}
