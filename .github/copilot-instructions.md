# Copilot project instructions — Acme Bank microservice template

This is a single-service `azd` template for creating a .NET 10 microservice that joins an existing Acme Bank Azure environment. It is a demo paved road: synthetic data only, no real customers, no real keys, and no government identifiers.

## Repo layout

- `src/MyService` — ASP.NET Core Minimal API service. `MyService` is a required rename placeholder.
- `src/MyService/Endpoints` — endpoint mapping extension methods such as `MapSampleEndpoints()`.
- `src/MyService/Data` — EF Core context and safe sample entities.
- `tests/MyService.Tests` — xUnit integration tests using `WebApplicationFactory<Program>`.
- `infra` — Bicep that provisions only this Container App and joins existing shared Acme Bank resources.
- `.github/workflows` — PR validation, CodeQL, Dependency Review, image build, and deploy workflows.

## Stack and conventions

- Use .NET 10 with central package management in `Directory.Packages.props`. Project `.csproj` files use versionless `<PackageReference Include="..." />` entries.
- `Directory.Build.props` enables nullable reference types, implicit usings, `TreatWarningsAsErrors`, latest language version, and invariant globalization. Clean builds are mandatory.
- Services use top-level statements in `Program.cs` plus `public partial class Program;` for `WebApplicationFactory` testing.
- If `ConnectionStrings:Sql` is unset, the service must use EF Core in-memory storage. If it is set, use SQL Server.
- Register OpenAPI with `Microsoft.AspNetCore.OpenApi`.
- Application Insights reads `APPLICATIONINSIGHTS_CONNECTION_STRING`. When unset, telemetry should no-op.
- Keep endpoints organized in `Endpoints/` and mapped through `Map*Endpoints()` extension methods.

## Hard rules

- No SSNs, taxpayer IDs, government identifiers, real customer data, or real secrets. Keep samples synthetic and non-PII.
- Do not add telemetry properties containing PII. Treat keys containing `name`, `email`, `account`, `balance`, `amount`, `contribution`, `dob`, `prompt`, `completion`, or `response` as sensitive.
- If adding seed data later, keep it deterministic. Do not introduce `DateTime.Now`, `Guid.NewGuid()`, or unseeded random data in seeding paths.
- This service joins the Acme Bank Azure environment. Do not create shared ACR, Container Apps Environment, Application Insights, managed identity, or SQL resources in this template.
- GitHub Actions workflows must pin actions by full commit SHA and request only the permissions they need.
- Dockerfiles must stay multi-stage, run as a non-root user, and use digest-pinned .NET SDK and ASP.NET runtime images.

## Local commands

```bash
dotnet build MyService.slnx
dotnet test MyService.slnx
dotnet run --project src/MyService
```

## When making changes

- Rename `MyService` and lowercase `myservice` deliberately when turning the template into a real service.
- Prefer small Minimal API endpoint groups and EF Core LINQ queries over raw SQL.
- Keep `/health` returning `{ "status": "ok" }` unless the health contract is intentionally changed with tests.
- Keep Bicep focused on this one Container App and role/configuration required for it to run.
