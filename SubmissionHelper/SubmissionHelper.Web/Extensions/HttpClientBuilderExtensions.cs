using Microsoft.Extensions.Http.Resilience;

namespace SubmissionHelper.Web.Extensions
{
    public static class HttpClientBuilderExtensions
    {
#pragma warning disable EXTEXP0001
        public static IHttpClientBuilder ClearResilienceHandlers(this IHttpClientBuilder builder)
        {
            builder.ConfigureAdditionalHttpMessageHandlers(static (handlers, _) =>
            {
                for (int i = 0; i < handlers.Count;)
                {
                    if (handlers[i] is ResilienceHandler)
                    {
                        handlers.RemoveAt(i);
                        continue;
                    }
                    i++;
                }
            });
            return builder;
        }

#pragma warning restore EXTEXP0001

    }
}
