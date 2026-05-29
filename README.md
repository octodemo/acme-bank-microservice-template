# Acme Bank microservice template

This repository is an `azd`-compatible paved-road template for adding a single .NET 10 microservice to an existing Acme Bank Azure environment. It gives teams the same service shape, container conventions, Bicep deployment model, and GitHub Advanced Security guardrails used by the Acme Bank retirement planner demo.

## Use the template

```bash
mkdir <your-service> && cd <your-service>
azd init -t octodemo/acme-bank-microservice-template . -e dev
azd up
```

That's it. `azd up` packages the image, provisions infra into the existing Acme Bank resource group, and deploys the new Container App. azd will prompt for an Azure subscription on first run.

After deployment, rename the placeholder service from `MyService` to your real service name, run `azd pipeline config`, and push to GitHub. The template deliberately uses the literal placeholder `MyService` in code and `myservice` in deployment configuration so developers and Copilot can perform an explicit, reviewable rename after init.

## How it joins the existing Acme Bank environment

The template does not create Azure Container Registry, Container Apps Environment, or Application Insights — it looks them up by name using Bicep `existing` resources. Container Apps Environment and Application Insights names are derived from `AZURE_ENV_NAME` and the resource group ID, matching the convention used by [`octodemo/acme-bank`](https://github.com/octodemo/acme-bank). The shared ACR name is hardcoded as a default in `infra/main.bicep`.

The new service creates its own user-assigned managed identity (`id-${AZURE_ENV_NAME}-${SERVICE_NAME}`) and grants it `AcrPull` on the shared registry, mirroring the per-service identity pattern used by acme-bank.

The target resource group is set in [`azure.yaml`](./azure.yaml) (`resourceGroup: rg-acmebank`).

### Reusing this template against a different platform

Override the demo defaults to point at a different shared environment:

- `azure.yaml` → change `resourceGroup` to your platform's resource group.
- `infra/main.bicep` → change the `containerRegistryName` parameter default.
- Make sure the platform uses the same naming convention for ACA Env and App Insights, or update the `existing` lookups in `infra/main.bicep`.

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
