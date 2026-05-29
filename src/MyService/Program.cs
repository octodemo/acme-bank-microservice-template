using Microsoft.EntityFrameworkCore;
using MyService.Data;
using MyService.Endpoints;

var builder = WebApplication.CreateBuilder(args);

// Local run: dotnet run --project src/MyService, then browse http://localhost:5080/health.
var appInsightsConnectionString = builder.Configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
if (!string.IsNullOrWhiteSpace(appInsightsConnectionString))
{
    builder.Services.AddApplicationInsightsTelemetry(options =>
    {
        options.ConnectionString = appInsightsConnectionString;
    });
}

builder.Services.AddOpenApi();

var sqlConnectionString = builder.Configuration.GetConnectionString("Sql");
if (string.IsNullOrWhiteSpace(sqlConnectionString))
{
    builder.Services.AddDbContext<AppDbContext>(options => options.UseInMemoryDatabase("myservice-local"));
}
else
{
    builder.Services.AddDbContext<AppDbContext>(options => options.UseSqlServer(sqlConnectionString));
}

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

if (string.IsNullOrWhiteSpace(sqlConnectionString))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.SeedLocalSamplesAsync(app.Lifetime.ApplicationStopping);
}

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));
app.MapSampleEndpoints();

app.Run();

public partial class Program;
