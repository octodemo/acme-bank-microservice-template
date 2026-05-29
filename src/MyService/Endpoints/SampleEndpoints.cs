using Microsoft.EntityFrameworkCore;
using MyService.Data;

namespace MyService.Endpoints;

/// <summary>
/// Maps safe sample endpoints that demonstrate Minimal APIs and EF Core query patterns.
/// </summary>
public static class SampleEndpoints
{
    /// <summary>
    /// Adds the sample endpoint group to the application route table.
    /// </summary>
    public static void MapSampleEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/samples").WithTags("Samples");

        group.MapGet("/info", () => Results.Ok(new
        {
            service = "MyService",
            message = "Replace this safe sample payload with your service contract."
        }));

        group.MapGet("/search", async (string? label, AppDbContext db, CancellationToken ct) =>
        {
            var query = db.Samples.AsNoTracking();
            if (!string.IsNullOrWhiteSpace(label))
            {
                query = query.Where(sample => sample.Label.Contains(label));
            }

            var samples = await query
                .OrderBy(sample => sample.CreatedAt)
                .Select(sample => new
                {
                    sample.Id,
                    sample.Label,
                    sample.CreatedAt
                })
                .ToListAsync(ct);

            return Results.Ok(samples);
        });
    }
}
