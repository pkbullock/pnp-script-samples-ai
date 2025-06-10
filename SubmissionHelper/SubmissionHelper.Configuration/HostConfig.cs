using System.ComponentModel.DataAnnotations;
using Microsoft.Extensions.Configuration;

namespace SubmissionHelper.Configuration
{
    public sealed class HostConfig
    {
        /// <summary>
        /// The AI services section name.
        /// </summary>
        public const string AIServicesSectionName = "AIServices";

        /// <summary>
        /// The name of the connection string of Azure OpenAI service.
        /// </summary>
        public const string AzureOpenAIConnectionStringName = "AzureOpenAI";

        /// <summary>
        /// Represents the configuration manager used to retrieve and manage application settings.
        /// </summary>
        /// <remarks>This field is read-only and is intended to store an instance of <see
        /// cref="ConfigurationManager"/>  for accessing configuration values. It is typically initialized during the
        /// construction of the containing class.</remarks>
        private readonly ConfigurationManager _configurationManager;

        private readonly AzureOpenAIChatConfig _azureOpenAIChatConfig = new();


        /// <summary>
        /// Initializes a new instance of the <see cref="HostConfig"/> class.
        /// </summary>
        /// <param name="configurationManager">The configuration manager.</param>
        public HostConfig(ConfigurationManager configurationManager)
        {
            configurationManager
                .GetSection($"{AIServicesSectionName}:{AzureOpenAIChatConfig.ConfigSectionName}")
                .Bind(this._azureOpenAIChatConfig);
            configurationManager
                .Bind(this);

            this._configurationManager = configurationManager;
        }

        /// <summary>
        /// The Azure OpenAI chat service configuration.
        /// </summary>
        public AzureOpenAIChatConfig AzureOpenAIChat => this._azureOpenAIChatConfig;

        /// The AI chat service to use.
        /// </summary>
        [Required]
        public string AIChatService { get; set; } = string.Empty;
    }
}
