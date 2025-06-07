# Introduction to Script Samples AI processor

THe goal of this tool is NOT to generate new samples, but to take an existing sample the maybe a PowerShell file and convert it into sample for script samples repository. 

What I'm looking to do is to simplify the walls around experience by reducing the amount of contributor needs to make the repository.

So let's workout the process for this:

 - Read this sample with LLM determine what the sample does, and generate a title and description preferrably in JSON format.
 - The author can be inferred from the GitHub handle
 - Convert the title into a folder friendly format
 - Infer the types of tabs needed from the scripts cmdlets
 - Create a scaffolded sample using the PowerShell script
 - Move the original script to the assets folder for original reference
 - Make a reference from the sample into the sample tracker
 - Allow the user to optionally review the sample before going live, auto accept after 7 days

 For development using the sample: https://pnp.github.io/script-samples/spo-modern-page-url-report/README.html

 Example Output

 **Description Result in JSON:**\n```json\n{\n  \"Title\": \"Title of the Script\",\n  \"Purpose\": \"Purpose of the Script\",\n    \"Dependencies\": [\"Connect-PnPOnline\", \"Get-PnPListItem\"],\n  \"Assumptions\": [\n    {\n      \"SourceSitePartURLRequired\": true,\n      \"TenantFilterOptional\": false\n    }\n  ]\n}\n```


 ## Sample Generation

- New-Sample.ps1 comes from the script samples repo and should not be changed.
- scripts/_template-script-submission is the same framework template
- Process-SampleLLM.ps1 - script to analyse the raw PowerShell script
