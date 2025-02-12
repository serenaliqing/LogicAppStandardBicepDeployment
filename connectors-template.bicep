@description('The datacenter to use for the deployment.')
param location string
param logicAppSystemAssignedIdentityTenantId string
param logicAppSystemAssignedIdentityObjectId string
param sa_name string = 'sa'
param connections_azureblob_name string = 'azureblob'

var sa_var = concat(toLower(sa_name), uniqueString(resourceGroup().id))

resource sa 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: sa_var
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'Storage'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    allowBlobPublicAccess: true
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource sa_default_blobs 'Microsoft.Storage/storageAccounts/blobServices/containers@2018-02-01' = {
  name: '${sa_var}/default/blobs'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'Container'
  }
  dependsOn: [
    sa
  ]
}

resource connections_azureblob_name_resource 'Microsoft.Web/connections@2016-06-01' = {
  name: connections_azureblob_name
  location: location
  kind: 'V2'
  properties: {
    displayName: 'privatestorage'
    parameterValues: {
      accountName: sa_var
      accessKey: concat(listKeys(
        '${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${sa_var}',
        '2019-06-01'
      ).keys[0].value)
    }
    api: {
      id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/azureblob'
    }
  }
  dependsOn: [
    sa
  ]
}

resource connections_azureblob_name_logicAppSystemAssignedIdentityObjectId 'Microsoft.Web/connections/accessPolicies@2016-06-01' = {
  parent: connections_azureblob_name_resource
  name: '${logicAppSystemAssignedIdentityObjectId}'
  location: location
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        tenantId: logicAppSystemAssignedIdentityTenantId
        objectId: logicAppSystemAssignedIdentityObjectId
      }
    }
  }
}

output blobendpointurl string = reference(connections_azureblob_name_resource.id, '2016-06-01', 'full').properties.connectionRuntimeUrl
