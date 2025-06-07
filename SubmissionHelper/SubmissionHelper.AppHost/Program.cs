var builder = DistributedApplication.CreateBuilder(args);

var apiService = builder.AddProject<Projects.SubmissionHelper_ApiService>("apiservice");

builder.AddProject<Projects.SubmissionHelper_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithReference(apiService)
    .WaitFor(apiService);

builder.Build().Run();
