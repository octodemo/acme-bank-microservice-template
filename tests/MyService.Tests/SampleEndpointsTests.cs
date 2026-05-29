using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace MyService.Tests;

/// <summary>
/// Integration tests for the sample endpoints.
/// </summary>
public sealed class SampleEndpointsTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> factory;

    /// <summary>
    /// Creates a sample endpoint test fixture.
    /// </summary>
    public SampleEndpointsTests(WebApplicationFactory<Program> factory)
    {
        this.factory = factory;
    }

    /// <summary>
    /// Verifies the static sample payload exposes the template service name.
    /// </summary>
    [Fact]
    public async Task Info_ReturnsTemplatePayload()
    {
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/samples/info");
        var body = await response.Content.ReadFromJsonAsync<InfoResponse>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().BeEquivalentTo(new InfoResponse("MyService", "Replace this safe sample payload with your service contract."));
    }

    /// <summary>
    /// Verifies the EF-backed sample search endpoint returns deterministic local records.
    /// </summary>
    [Fact]
    public async Task Search_ReturnsSeededSamples()
    {
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/samples/search?label=starter");
        var body = await response.Content.ReadFromJsonAsync<SampleResponse[]>();

        response.StatusCode.Should().Be(HttpStatusCode.OK);
        body.Should().ContainSingle(sample => sample.Label == "starter-sample");
    }

    private sealed record InfoResponse(string Service, string Message);

    private sealed record SampleResponse(Guid Id, string Label, DateTimeOffset CreatedAt);
}
