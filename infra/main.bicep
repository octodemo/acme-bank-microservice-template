@description('Azure region for the Container App resource.')
param location string = resourceGroup().location

@description('Azure Developer CLI environment name used in resource naming.')
@minLength(1)
@maxLength(32)
param environmentName string

@description('Logical service name used for the Container App name and container name.')
@minLength(1)
@maxLength(32)
param serviceName string = 'myservice'

@description('Full container image reference including tag or digest.')
param imageName string

@description('Resource ID of the existing user-assigned managed identity used by the shared Acme Bank environment.')
param managedIdentityResourceId string

@description('Resource ID of the existing Azure Container Apps managed environment.')
param containerAppsEnvironmentResourceId string

@description('Login server of the existing Azure Container Registry, for example myregistry.azurecr.io.')
param containerRegistryLoginServer string

@description('Application Insights connection string for the shared Acme Bank environment.')
@secure()
param applicationInsightsConnectionString string

@description('Optional SQL connection string. Leave empty to use the service in-memory fallback.')
@secure()
param sqlConnectionString string = ''

var containerApp = 'ca-${environmentName}-${serviceName}'
var hasSqlConnection = !empty(sqlConnectionString)
var secretDefinitions = concat([
  {
    name: 'applicationinsights-connection-string'
    value: applicationInsightsConnectionString
  }
], hasSqlConnection ? [
  {
    name: 'sql-connection-string'
    value: sqlConnectionString
  }
] : [])
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
  name: containerApp
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityResourceId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironmentResourceId
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: containerRegistryLoginServer
          identity: managedIdentityResourceId
        }
      ]
      secrets: [for secret in secretDefinitions: {
        name: secret.name
        value: secret.value
      }]
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
}

output fqdn string = app.properties.configuration.ingress.fqdn
