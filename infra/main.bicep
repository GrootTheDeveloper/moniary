targetScope = 'subscription'

param environmentName string
param location string
param supabaseUrl string
@secure()
param supabaseAnonKey string
@secure()
param geminiApiKey string
param geminiModel string = 'gemini-2.5-flash'
@secure()
param geminiBlockedKeySha256 string = ''

var resourceSuffix = take(uniqueString(subscription().id, environmentName, location), 6)
var tags = {
  'azd-env-name': environmentName
}
var resourceGroupName = 'rg-${environmentName}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module platform './modules/platform.bicep' = {
  name: 'ocrPlatform'
  scope: resourceGroup
  params: {
    location: location
    environmentName: environmentName
    resourceSuffix: resourceSuffix
    tags: tags
    supabaseUrl: supabaseUrl
    supabaseAnonKey: supabaseAnonKey
    geminiApiKey: geminiApiKey
    geminiModel: geminiModel
    geminiBlockedKeySha256: geminiBlockedKeySha256
  }
}

module acrPullRole './modules/acr-pull-role.bicep' = {
  name: 'ocrAcrPullRole'
  scope: resourceGroup
  params: {
    acrName: platform.outputs.containerRegistryName
    principalId: platform.outputs.containerAppPrincipalId
  }
}

output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = platform.outputs.containerRegistryEndpoint
output AZURE_CONTAINER_REGISTRY_NAME string = platform.outputs.containerRegistryName
output AZURE_CONTAINER_APP_NAME string = platform.outputs.containerAppName
output API_URL string = platform.outputs.apiUrl
