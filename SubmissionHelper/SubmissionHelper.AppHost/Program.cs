using SubmissionHelper.Configuration;

var builder = DistributedApplication.CreateBuilder(args);

// Load host configuration.
var hostConfig = new HostConfig(builder.Configuration);

// Add Api Service AI upstream dependencies
var aiServices = AddAIServices(builder, hostConfig);


var apiService = builder.AddProject<Projects.SubmissionHelper_ApiService>("apiservice");

builder.AddProject<Projects.SubmissionHelper_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithReference(apiService)
    .WaitFor(apiService);

builder.Build().Run();

static List<IResourceBuilder<IResourceWithConnectionString>> AddAIServices(IDistributedApplicationBuilder builder, HostConfig config)
{
    IResourceBuilder<IResourceWithConnectionString>? chatResource = null;
    IResourceBuilder<IResourceWithConnectionString>? embeddingsResource = null;

    // Add Azure OpenAI service and configured AI models
    if (config.AIChatService == AzureOpenAIChatConfig.ConfigSectionName)
    {
        if (builder.ExecutionContext.IsPublishMode)
        {
            // Add Azure OpenAI service
            var azureOpenAI = builder.AddAzureOpenAI(HostConfig.AzureOpenAIConnectionStringName);

            // Add chat deployment
            if (config.AIChatService == AzureOpenAIChatConfig.ConfigSectionName)
            {
                chatResource = azureOpenAI.AddDeployment(new AzureOpenAIDeployment(
                    name: config.AzureOpenAIChat.DeploymentName,
                    modelName: config.AzureOpenAIChat.ModelName,
                    modelVersion: config.AzureOpenAIChat.ModelVersion,
                    skuName: config.AzureOpenAIChat.SkuName,
                    skuCapacity: config.AzureOpenAIChat.SkuCapacity)
                );
            }

        }
        else
        {
            // Use an existing Azure OpenAI service via connection string
            chatResource = embeddingsResource = builder.AddConnectionString(HostConfig.AzureOpenAIConnectionStringName);
        }
    }
    
    if (chatResource is null)
    {
        throw new NotSupportedException($"AI Chat service '{config.AIChatService}' is not supported.");
    }

    return [chatResource, embeddingsResource];
}