using Microsoft.Extensions.Configuration;
using SubmissionHelper.Configuration;

namespace SubmissionHelper.ApiService.Config
{
    public class ServiceConfig
    {
        private readonly HostConfig _hostConfig;

        /// <summary>
        /// Initializes a new instance of the <see cref="ServiceConfig"/> class.
        /// </summary>
        /// <param name="configurationManager">The configuration manager.</param>
        public ServiceConfig(ConfigurationManager configurationManager)
        {
            this._hostConfig = new HostConfig(configurationManager);
        }

        /// <summary>
        /// Host configuration.
        /// </summary>
        public HostConfig Host => this._hostConfig;
    }
}
