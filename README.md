# Acme Bank microservice template

This repository is an `azd`-compatible paved-road template for adding a single .NET 10 microservice to an existing Acme Bank Azure environment. It gives teams the same service shape, container conventions, Bicep deployment model, and GitHub Advanced Security guardrails used by the Acme Bank retirement planner demo.

## Use the template

```bash
azd init -t octodemo/acme-bank-microservice-template
```

After initialization, rename the placeholder service from `MyService` to your real service name, run `azd pipeline config`, and push the repository to GitHub. The template deliberately uses the literal placeholder `MyService` in code and `myservice` in deployment configuration so developers and Copilot can perform an explicit, reviewable rename after init.

## Joining the existing Acme Bank environment

The template joins an existing Acme Bank Azure environment. It does not create Azure Container Registry, Container Apps Environment, or Application Insights — it looks them up by name using Bicep `existing` resources. The Container Apps Environment and Application Insights names are derived from `AZURE_ENV_NAME` and the resource group ID, matching the convention used by [`octodemo/acme-bank`](https://github.com/octodemo/acme-bank).

The new service does create its own user-assigned managed identity (`id-${AZURE_ENV_NAME}-${SERVICE_NAME}`) and grants it `AcrPull` on the shared registry, mirroring the per-service identity pattern used by acme-bank.

### One-time bootstrap

Set the azd environment to point at the existing Acme Bank resource group, then import the two values that aren't derivable from convention (the ACR name and the BFF base URL) from acme-bank's azd environment:

```bash
azd env new <existing-acme-env-name>
azd env get-values --cwd ../acme-bank | grep ^ACME_ >> .azure/<existing-acme-env-name>/.env
```

That populates `ACME_CONTAINER_REGISTRY_NAME` (and `ACME_BFF_BASE_URL` for the frontend template). Everything else — `AZURE_LOCATION`, `AZURE_ENV_NAME`, `SERVICE_<NAME>_IMAGE_NAME` — is set automatically by azd.

Then deploy:

```bash
azd up
```

`azd up` packages the image, sets `SERVICE_MYSERVICE_IMAGE_NAME`, runs `azd provision` against `infra/main.bicep`, and deploys the new Container App into the shared environment.

### Optional SQL

To wire the service to the platform's SQL Server, set `ACME_SQL_CONNECTION_STRING` on the new service's azd env. Leaving it empty keeps the EF Core in-memory fallback used for local dev and demos.

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
