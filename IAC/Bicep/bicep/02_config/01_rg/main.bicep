targetScope = 'subscription'

param environment string
param layerName string
param location string = deployment().location
param deploymentName string = ''
param resourceGroupName string = ''

var _resourceGroupName = empty(deploymentName) ? resourceGroupNameGenerator.outputs.name : resourceGroupName
var _deploymentName = empty(deploymentName)
  ? uniqueString(subscription().subscriptionId, location, environment)
  : deploymentName
var uniqueToken = substring(uniqueString(_deploymentName, layerName), 0, 6)

// Resource Group

module resourceGroupNameGenerator './../../modules/nameGeneratorSubscription.bicep' = {
  name: '${_deploymentName}-resourceGroupNameGenerator'
  params: {
    name: 'rg-config'
    prefix: environment
    uniqueToken: uniqueToken
  }
}

module resourceGroup './../../modules/resourceGroup.bicep' = {
  name: '${_deploymentName}-resourceGroup'
  params: {
    name: _resourceGroupName
    layerName: layerName
    location: location
    environment: environment
  }
}

output resourceGroupId string = resourceGroup.outputs.id
output resourceGroupName string = resourceGroup.outputs.name
