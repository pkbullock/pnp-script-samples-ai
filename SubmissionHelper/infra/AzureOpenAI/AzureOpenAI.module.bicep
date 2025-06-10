@description('The location for the resource(s) to be deployed.')
param location string = resourceGroup().location

resource AzureOpenAI 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: take('AzureOpenAI-${uniqueString(resourceGroup().id)}', 64)
  location: location
  kind: 'OpenAI'
  properties: {
    customSubDomainName: toLower(take(concat('AzureOpenAI', uniqueString(resourceGroup().id)), 24))
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
  sku: {
    name: 'S0'
  }
  tags: {
    'aspire-resource-name': 'AzureOpenAI'
  }
}

resource gpt_4o_mini 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: 'gpt-4o-mini'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 20
  }
  parent: AzureOpenAI
}

output connectionString string = 'Endpoint=${AzureOpenAI.properties.endpoint}'

output name string = AzureOpenAI.name