<# 
----------------------------------------------------------------------------

Created:      Paul Bullock
Date:         27/10/2024
Disclaimer:   

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

.Synopsis

.Example

.Notes

Useful reference: 
      List any useful references

 ----------------------------------------------------------------------------
#>

[CmdletBinding()]
param (
    $Script = "inputs/script.ps1",
    $AuthorFullName = "Paul Bullock",
    $AuthorId = "pkbullock"
)
begin {

    # ------------------------------------------------------------------------------
    # Introduction
    # ------------------------------------------------------------------------------

    Write-Host @"
    _____      _____      _____           _       _      _____                       _           
   |  __ \     |  __ \   / ____|         (_)     | |    / ____|                     | |          
   | |__) | __ | |__) | | (___   ___ _ __ _ _ __ | |_  | (___   __ _ _ __ ___  _ __ | | ___  ___ 
   |  ___/ '_ \|  ___/   \___ \ / __| '__| | '_ \| __|  \___ \ / _` | '_ ` _ \| '_ \| |/ _ \/ __|
   | |   | | | | |       ____) | (__| |  | | |_) | |_   ____) | (_| | | | | | | |_) | |  __/\__ \
   |_|   |_| |_|_|      |_____/ \___|_|  |_| .__/ \__| |_____/ \__,_|_| |_| |_| .__/|_|\___||___/
                                           | |                                | |                
                                           |_|                                |_|                                                                                                                             
"@

    Write-Host " Welcome to PnP Script Samples, this script will generate a new script sample" -ForegroundColor Green
    Write-Host " ---------------------------------------------------------------------------- \n" -ForegroundColor Green
    
    # ------------------------------------------------------------------------------

}
process {

    # ------------------------------------------------------------------------------
    # Checks and validation
    # ------------------------------------------------------------------------------

    #Script file validation
    if (-not (Test-Path -Path $Script)) {
        Write-Host "The script file $Script does not exist" -ForegroundColor Red
        return
    }

    # Checks if the script already has a localModelResults.json file
    $processedLLMLocation = "$(Get-Location)\outputs"
    $outputFile = "localModelResults$(($Script -replace '[^a-zA-Z0-9]', '-'))"
    if (-not (Test-Path -Path "$processedLLMLocation\$outputFile.json")) {
        Write-Host "No $outputFile.json file found" -ForegroundColor Yellow
        
        Write-Host "Running the script Process Sample LLM to generate the localModelResults.json file"
        # Run the script Process Sample LLM to generate the localModelResults.json file
        .\Get-SampleLLMDetails.ps1 -Script $Script
    }

    # ------------------------------------------------------------------------------
    # Process the details from the localModelResults.json file
    # ------------------------------------------------------------------------------

    # Load the file localModelResults.json into a variable and convert it to a PowerShell object
    $localModelResults = Get-Content -Path "$processedLLMLocation\$outputFile.json" | ConvertFrom-Json -Depth 10

    # Check if ModelResultObject contains any values and if the property "processed" is set to false
    if ($localModelResults -eq $null -or $localModelResults.LocalModelResults.ModelResultObject -eq $null -or $localModelResults.processed -eq $true) {
        Write-Host "No new samples to process - either LLM analysis didnt produce suitable result or already processed" -ForegroundColor Yellow
        return
    }

    # Convert the title into a valid foldername
    $sampleFolderName = $localModelResults.LocalModelResults.ModelResultObject.Title -replace '[^a-zA-Z0-9]', '-'
    $sampleFolderName = $sampleFolderName.ToLower()

    # TODO Script tool can be deteremined by analysing the prompt and compare from the help files
    $scriptTool = "PnPPowerShell"

    Write-Host "Running New-Sample.ps1 for $($localModelResults.LocalModelResults.ModelResultObject.Title)" -ForegroundColor Blue

    # Run the script to generate the new sample
    .\New-Sample.ps1 -Title $localModelResults.LocalModelResults.ModelResultObject.Title `
                     -Description $localModelResults.LocalModelResults.ModelResultObject.Purpose `
                     -Author $AuthorFullName `
                     -AuthorId $AuthorId `
                     -Tool $scriptTool `
                     -FolderName $sampleFolderName

    # ------------------------------------------------------------------------------
    # The generated sample will need amending to include the new sample details
    # ------------------------------------------------------------------------------

    Write-Host "Post-Pocessing the generated sample" -ForegroundColor Blue

    # Load the Readme.md file from the $sampleFolderName directory
    $readmeFile = Get-Content -Path ".\scripts\$sampleFolderName\README.md"

    # Remove > [!Note] from the Readme.md file
    $readmeFile = $readmeFile -notmatch "> \[!Note\]"

    #Remove > This is a submission helper template please find the [contributor guidance](/docfx/contribute.md) to help you write this scenario. From the Readme file
    $readmeFile = $readmeFile -notmatch "> This is a submission helper template please find the \[contributor guidance\]\(/docfx/contribute.md\) to help you write this scenario."

    # Remove the ![Example Screenshot](assets/example.png) from the Readme.md file
    $readmeFile = $readmeFile -notmatch "!\[Example Screenshot\]\(assets/example.png\)"

    # Replace the lorem ipsum text in the Readme.md file with the purpose of the script
    # Order is important as the short lorem ipsum text is a subset of the long lorem ipsum text
    $removeLongLoremIpsum = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas porttitor congue massa. Fusce posuere, magna sed pulvinar ultricies, purus lectus malesuada libero, sit amet commodo magna eros quis urna.Nunc viverra imperdiet enim. Fusce est. Vivamus a tellus.Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Proin pharetra nonummy pede. Mauris et orci.Aenean nec lorem. In porttitor. Donec laoreet nonummy augue."
    $readmeFile = $readmeFile -replace $removeLongLoremIpsum, $localModelResults.LocalModelResults.ModelResultObject.LongDescription
    
    $shortLoremIpsum = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas porttitor congue massa. Fusce posuere, magna sed pulvinar ultricies, purus lectus malesuada libero, sit amet commodo magna eros quis urna."
    $readmeFile = $readmeFile -replace $shortLoremIpsum, $localModelResults.LocalModelResults.ModelResultObject.Purpose
    
    # Update the Readme.md file to replace "<your script>" with the contents of the PowerShell script in $Script
    $scriptContent = Get-Content -Path $Script -Raw
    $readmeFile = $readmeFile -replace "<your script>", $scriptContent
    
    
    $readmeFile | Set-Content -Path ".\scripts\$sampleFolderName\README.md"
    Write-Host "Updated the README.md file" -ForegroundColor Yellow
    
    
    # ------------------------------------------------------------------------------
    # When the localModelResults.json processing has finished, update the json file with the property "processed" set to true
    $localModelResults.Processed = $true
    $localModelResults | ConvertTo-Json -Depth 10 | Set-Content -Path "$processedLLMLocation\$outputFile.json"
    
}
end{

  Write-Host "Done! :)" -ForegroundColor Green
}