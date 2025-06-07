
$AdminCenterURL="https://contoso-admin.sharepoint.com/"# Connect to SharePoint Online admin center
Connect-PnPOnline -Url $AdminCenterURL -Interactive
$dateTime = (Get-Date).toString("dd-MM-yyyy")
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$fileName = "m365OwnersNotMembers-" + $dateTime + ".csv"
$OutPutView = $directorypath + "\" + $fileName
# Array to Hold Result - PSObjects
$m365GroupCollection = @()
#Write-host $"$ownerName not part of member in $siteUrl";
$m365Sites = Get-PnPTenantSite -Detailed | Where-Object { ($_.Template -eq 'GROUP#0') -and $_.Template -ne 'RedirectSite#0' }
$m365Sites | ForEach-Object {   
    $groupId = $_.GroupId;
    $siteUrl = $_.Url;
    $siteName = $_.Title
    #if owner is not part of m365 group member
    (Get-PnPMicrosoft365GroupOwner -Identity $groupId -ErrorAction Ignore) | foreach-object {
        $owner = $_;
        $ownerDisplayName = $owner.DisplayName;
        if (!(Get-PnPMicrosoft365GroupMember -Identity $groupId  -ErrorAction Ignore | Where-Object { $_.DisplayName -eq $owner.DisplayName })) {
            $ExportVw = New-Object PSObject
            $ExportVw | Add-Member -MemberType NoteProperty -name "Site Name" -value $siteName
            $ExportVw | Add-Member -MemberType NoteProperty -name "Site URL" -value $siteUrl
            $ExportVw | Add-Member -MemberType NoteProperty -name "Owner Name" -value $owner.DisplayName
            $m365GroupCollection += $ExportVw
            Add-PnPMicrosoft365GroupMember -Identity $groupId -Users $owner.Email
            Write-host "$ownerDisplayName has been added as member in $siteUrl";
      }
   }
}
# Export the result array to CSV file
$m365GroupCollection | sort-object "Site Name" | Export-CSV $OutPutView -Force -NoTypeInformation