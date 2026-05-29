# Acme Bank microservice template

This repository is an `azd`-compatible paved-road template for adding a single .NET 10 microservice to an existing Acme Bank Azure environment. It gives teams the same service shape, container conventions, Bicep deployment model, and GitHub Advanced Security guardrails used by the Acme Bank retirement planner demo.

## Use the template

```bash
azd init -t octodemo/acme-bank-microservice-template
```

After initialization, rename the placeholder service from `MyService` to your real service name, run `azd pipeline config`, and push the repository to GitHub. The template deliberately uses the literal placeholder `MyService` in code and `myservice` in deployment configuration so developers and Copilot can perform an explicit, reviewable rename after init.

## Shared environment model

The template joins an existing Acme Bank Azure environment. It does not create Azure Container Registry, Container Apps Environment, Application Insights, managed identity, or SQL. Deployment expects these `azd` environment values:

- `AZURE_LOCATION` — Azure region for the Container App resource.
- `AZURE_ENV_NAME` — Acme Bank environment name, such as `dev`.
- `SHARED_MANAGED_IDENTITY_ID` — resource ID of the existing user-assigned managed identity.
- `SHARED_CONTAINER_APPS_ENV_ID` — resource ID of the existing Container Apps Environment.
- `SHARED_ACR_LOGIN_SERVER` — shared ACR login server, such as `myregistry.azurecr.io`.
- `SHARED_APP_INSIGHTS_CONNECTION_STRING` — shared Application Insights connection string.
- `SHARED_SQL_CONNECTION_STRING` — optional SQL Server connection string. Leave empty for the in-memory fallback.
- `SERVICE_MYSERVICE_IMAGE_NAME` — full image reference including tag or digest, set by CI after image publishing.

## Rename guide

Rename `MyService` to `<YourService>` before building real features. Update the `.csproj` filenames, the `MyService` namespace, `Program.cs`, `appsettings`, `Dockerfile`, `azure.yaml`, `infra/main.bicep` parameters or defaults, `infra/main.parameters.json`, and the tests project. Also update lowercase `myservice` values where they represent service names, image names, or workflow artifacts.

## Local development

```bash
dotnet run --project src/MyService
```

Local development works without Azure. When `ConnectionStrings:Sql` is unset, the service uses EF Core in-memory storage and deterministic non-PII seed data. When `APPLICATIONINSIGHTS_CONNECTION_STRING` is unset, telemetry registration is skipped.

## Validation

```bash
dotnet build MyService.slnx
dotnet test MyService.slnx
```

The service exposes `/health`, `/samples/info`, and `/samples/search`. The sample endpoints are intentionally safe, minimal examples for replacing with a real service contract.

## Bundled guardrails

- CodeQL for C#.
- Dependency Review on pull requests.
- Docker image build with digest-pinned .NET base images.
- SBOM generation with `microsoft/sbom-tool`.
- Build provenance attestation for pushed images.
- Azure OIDC login for publishing and deployment.
- Least-privilege GitHub Actions permissions with actions pinned by SHA.
