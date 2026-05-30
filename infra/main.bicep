@description('Azure region for the Container App resource. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Acme Bank azd environment name. Must match the existing environment you are joining (for example, dev).')
@minLength(1)
@maxLength(32)
param environmentName string

@description('Logical service name. Used for the Container App name, managed identity name, and image name. Rename from myservice when adopting the template.')
@minLength(1)
@maxLength(32)
param serviceName string = 'myservice'

@description('Full container image reference including tag or digest. Set automatically by azd during the package phase as SERVICE_<NAME>_IMAGE_NAME. The default placeholder lets the first `azd up` provision succeed before the real image is built.')
param imageName string = 'mcr.microsoft.com/k8se/quickstart:latest'

@description('Name of the shared Azure Container Registry created by the Acme Bank platform bootstrap. Defaulted to the demo registry; override when reusing the template against a different platform.')
param containerRegistryName string = 'acmebanke40394e9'

@description('Optional SQL connection string. Leave empty to use the EF Core in-memory fallback.')
@secure()
param sqlConnectionString string = ''

// Shared-resource names follow the same convention used by the Acme Bank
// platform repo so this template can locate them with `existing` lookups.
var namePrefix = take(replace(toLower(environmentName), '-', ''), 12)
var suffix = uniqueString(resourceGroup().id, environmentName)
var containerAppsEnvironmentName = 'cae-${namePrefix}-${suffix}'
var appInsightsName = 'appi-${namePrefix}-${suffix}'
var containerAppName = 'ca-${environmentName}-${serviceName}'
var managedIdentityName = 'id-${environmentName}-${serviceName}'

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: containerAppsEnvironmentName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}

var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.properties.principalId, 'acr-pull')
  scope: containerRegistry
  properties: {
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleDefinitionId
  }
}

var hasSqlConnection = !empty(sqlConnectionString)

var baseSecrets = [
  {
    name: 'applicationinsights-connection-string'
    value: appInsights.properties.ConnectionString
  }
]

var sqlSecrets = hasSqlConnection ? [
  {
    name: 'sql-connection-string'
    value: sqlConnectionString
  }
] : []

var environmentVariables = concat([
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    secretRef: 'applicationinsights-connection-string'
  }
], hasSqlConnection ? [
  {
    name: 'ConnectionStrings__Sql'
    secretRef: 'sql-connection-string'
  }
] : [])

resource app 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  tags: {
    'azd-service-name': 'myservice'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
      secrets: concat(baseSecrets, sqlSecrets)
      ingress: {
        external: false
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          name: serviceName
          image: imageName
          env: [for environmentVariable in environmentVariables: {
            name: environmentVariable.name
            secretRef: environmentVariable.secretRef
          }]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
  dependsOn: [
    acrPullAssignment
  ]
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output fqdn string = app.properties.configuration.ingress.fqdn
output serviceUrl string = 'https://${app.properties.configuration.ingress.fqdn}'
