
using Azure.Identity;
using Microsoft.Extensions.Azure;
using Microsoft.SemanticKernel;
using Microsoft.SemanticKernel.Agents;
using Microsoft.SemanticKernel.Data;
using SubmissionHelper.ApiService.Config;
using SubmissionHelper.Configuration;
using System.ClientModel.Primitives;

namespace SubmissionHelper.ApiService;

/// <summary>
/// Defines the Program class containing the application's entry point.
/// </summary>
public static class Program
{
    /// <summary>
    /// The main entry point for the application.
    /// </summary>
    /// <param name="args">The command-line arguments.</param>
    public static void Main(string[] args)
    {

        var builder = WebApplication.CreateBuilder(args);

        // Enable diagnostics.
        AppContext.SetSwitch("Microsoft.SemanticKernel.Experimental.GenAI.EnableOTelDiagnostics", true);

        builder.Services.AddOpenTelemetry().WithTracing(b => b.AddSource("Microsoft.SemanticKernel*"));
        builder.Services.AddOpenTelemetry().WithMetrics(b => b.AddMeter("Microsoft.SemanticKernel*"));


        // Add service defaults & Aspire client integrations.
        builder.AddServiceDefaults();

        builder.Services.AddControllers();


        // Add services to the container.
        builder.Services.AddProblemDetails();

        // Add Semantic Kernel services
        // Load the service configuration.
        var config = new ServiceConfig(builder.Configuration);

        // Add Kernel
        builder.Services.AddKernel();


        // Add AI services.
        AddAIServices(builder, config.Host);

        // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
        builder.Services.AddOpenApi();

        var app = builder.Build();

        // Configure the HTTP request pipeline.
        app.UseExceptionHandler();

        if (app.Environment.IsDevelopment())
        {
            app.MapOpenApi();
        }

        app.MapDefaultEndpoints();

        app.MapControllers();

        app.Run();

    }


    /// <summary>
    /// Adds AI services for chat completion.
    /// </summary>
    /// <param name="builder">The web application builder.</param>
    /// <param name="config">Service configuration.</param>
    /// <exception cref="NotSupportedException"></exception>
    private static void AddAIServices(WebApplicationBuilder builder, HostConfig config)
    {
        // Add AzureOpenAI client.
        if (config.AIChatService == AzureOpenAIChatConfig.ConfigSectionName)
        {
            builder.AddAzureOpenAIClient(
                connectionName: HostConfig.AzureOpenAIConnectionStringName,
                configureSettings: (settings) => settings.Credential = builder.Environment.IsProduction()
                    ? new DefaultAzureCredential()
                    : new AzureCliCredential(),
                configureClientBuilder: clientBuilder =>
                {
                    clientBuilder.ConfigureOptions((options) =>
                    {
                        options.RetryPolicy = new ClientRetryPolicy(maxRetries: 3);
                    });
                });
        }
                
        // Add chat completion services.
        switch (config.AIChatService)
        {
            case AzureOpenAIChatConfig.ConfigSectionName:
                {
                    builder.Services.AddAzureOpenAIChatCompletion(config.AzureOpenAIChat.DeploymentName, modelId: config.AzureOpenAIChat.ModelName);
                    break;
                }
            default:
                throw new NotSupportedException($"AI chat service '{config.AIChatService}' is not supported.");
        }
    }
       
}
