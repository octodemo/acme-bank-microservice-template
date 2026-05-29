namespace MyService.Data;

/// <summary>
/// Safe non-PII sample entity for demonstrating EF Core queries.
/// </summary>
public sealed class Sample
{
    /// <summary>
    /// Gets or sets the deterministic sample identifier.
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// Gets or sets the sample label.
    /// </summary>
    public required string Label { get; set; }

    /// <summary>
    /// Gets or sets the deterministic creation timestamp.
    /// </summary>
    public DateTimeOffset CreatedAt { get; set; }
}
