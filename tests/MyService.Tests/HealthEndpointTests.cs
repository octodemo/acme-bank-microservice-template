using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace MyService.Tests;

/// <summary>
/// Integration tests for the health endpoint.
/// </summary>
public sealed class HealthEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> factory;

    /// <summary>
    /// Creates a health endpoint test fixture.
    /// </summary>
    public HealthEndpointTests(WebApplicationFactory<Program> factory)
    {
        this.factory = factory;
    }

    /// <summary>
    /// Verifies the health endpoint returns the expected ok payload.
    /// </summary>
    [Fact]
    public async Task Health_ReturnsOkPayload()
    {
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/health");
        var body = await response.Content.ReadFromJsonAsync<HealthResponse>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().BeEquivalentTo(new HealthResponse("ok"));
    }

    private sealed record HealthResponse(string Status);
}
