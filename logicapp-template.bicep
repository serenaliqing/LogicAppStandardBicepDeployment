@description('The datacenter to use for the deployment.')
param location string = 'eastus'
param environmentName string ='Staging'
param projectName string = 'Exploration'
param logicAppName string ='Bicepdeployment0313'
param appServicePlanName string ='Bicepdeployment0313'

@minLength(3)
@maxLength(24)
param storageName string ='serenabicepdeploy0313'
param kind string = 'StorageV2'
param skuName string = 'Standard_LRS'
param skuTier string = 'Standard'


resource storage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: kind
  name: storageName
  location: location
  tags: {
    Environment: environmentName
    Project: projectName
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: appServicePlanName
  location: location
  tags: {
    Environment: environmentName
    Project: projectName
  }
  sku: {
    name: 'WS1'
    tier: 'WorkflowStandard'
  }
  kind: 'windows'
}

resource logicApp 'Microsoft.Web/sites@2018-11-01' = {
  name: logicAppName
  location: location
  kind: 'workflowapp,functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    Environment: environmentName
    Project: projectName
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      netFrameworkVersion: 'v4.6'
      appSettings: [
        {
          name: 'APP_KIND'
          value: 'workflowApp'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__version'
          value: '[1.*, 2.0.0)'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys('${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${storageName}','2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_V2_COMPATIBILITY_MODE'
          value: 'true'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageName};AccountKey=${listKeys('${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${storageName}','2019-06-01').keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: 'test'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
        {
          name: 'WORKFLOWS_SUBSCRIPTION_ID'
          value: subscription().subscriptionId
        }
        {
          name: 'WORKFLOWS_LOCATION_NAME'
          value: location
        }
        {
          name: 'storage_account_name'
          value: 'sa4ym6uzg74dchk'
        }
        {
          name: 'WORKFLOWS_RESOURCE_GROUP_NAME'
          value: ''
        }
        {
          name: 'BLOB_CONNECTION_RUNTIMEURL'
          value: ''
        }
      ]
    }
    clientAffinityEnabled: false
  }
  dependsOn: [
    storage
  ]
}

output logicAppSystemAssignedIdentityTenantId string = subscription().tenantId
output logicAppSystemAssignedIdentityObjectId string = reference(logicApp.id, '2019-08-01', 'full').identity.principalId
output LAname string = logicAppName
