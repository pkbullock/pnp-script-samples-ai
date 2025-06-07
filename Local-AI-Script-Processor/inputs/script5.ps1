$m365Status = m365 status
if ($m365Status -match "Logged Out") {
    m365 login
}

$dateTime = (Get-Date).toString("dd-MM-yyyy")
$invocation = (Get-Variable MyInvocation).Value
$directorypath = Split-Path $invocation.MyCommand.Path
$fileName = "m365OwnersNotMembers-" + $dateTime + ".csv"
$OutPutView = $directorypath + "\" + $fileName
# Array to Hold Result - PSObjects
$m365GroupCollection = @()
#Write-host $"$ownerName not part of member in $siteUrl";
$m365Sites = m365 spo site list --query "[?Template == 'GROUP#0' && Template != 'RedirectSite#0'].{GroupId:GroupId, Url:Url, Title:Title}" --output json | ConvertFrom-Json
$m365Sites | ForEach-Object {   
    $groupId = $_.GroupId -replace "/Guid\((.*)\)/",'$1';
    $siteUrl = $_.Url;
    $siteName = $_.Title
    #if owner is not part of m365 group member
    (m365 entra m365group user list --role Owner --groupId $groupId --output json | ConvertFrom-Json) | foreach-object {
        $owner = $_;
        $ownerDisplayName = $owner.displayName
        if (!(m365 entra m365group user list --role Member --groupId $groupId --query "[?displayName == '$ownerDisplayName']" --output json | ConvertFrom-Json)) {
            $ExportVw = New-Object PSObject
            $ExportVw | Add-Member -MemberType NoteProperty -name "Site Name" -value $siteName
            $ExportVw | Add-Member -MemberType NoteProperty -name "Site URL" -value $siteUrl
            $ExportVw | Add-Member -MemberType NoteProperty -name "Owner Name" -value $ownerDisplayName
            $m365GroupCollection += $ExportVw
            m365 entra m365group user add --role Owner --groupId $groupId --userName $owner.userPrincipalName
            Write-host "$ownerDisplayName has been added as member in $siteUrl";
        }
    }
}
# Export the result array to CSV file
$m365GroupCollection | sort-object "Site Name" | Export-CSV $OutPutView -Force -NoTypeInformation

#Disconnect SharePoint online connection
m365 logout