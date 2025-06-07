$DOCUMENT_LIBRARY_BASETEMPLATE = 101
$FOLDER_OBJECT_TYPE = 1


$TenantAdminUrl = "https://2v8lc2-admin.sharepoint.com/"
$ClientId = "#####"
$Thumbprint = "#####"


Write-Host "Connecting to Tenant Admin Site..."
Connect-PnPOnline -Url $TenantAdminUrl -Thumbprint $Thumbprint -ClientId $ClientId
$Sites = Get-PnPTenantSite | Where-Object { $_.Template -ne "RedirectSite#0" -and $_.Template -ne "SPSMSITEHOST#0" }


$Report = @()


Write-Host "Processing $($sites.Count) sites..."
foreach ($Site in $Sites) {
    Write-Host "> $($Site.Url)" -ForegroundColor Blue
    $Connection = Connect-PnPOnline -Url $Site.Url -Thumbprint $Thumbprint -ClientId $ClientId -ReturnConnection
    $Lists = Get-PnPList -Connection $Connection | Where-Object { $_.BaseTemplate -eq $DOCUMENT_LIBRARY_BASETEMPLATE -and $_.Hidden -eq $false }
  
    $TotalSiteItemCount = $Lists | ForEach-Object { $_.ItemCount } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    $Report += [PSCustomObject]@{
        Type                     = "Site"
        Id                       = $Site.Id
        Path                     = $Site.Url
        WebUrl                   = $Site.Url
        SiteTitle                = $Site.Title
        DocumentLibraryTitle     = ""
        DocumentLibraryUrl       = ""
        DocumentLibraryId        = ""
        DirectFolderCount        = 0
        DirectFilesCount         = 0
        DirectItemCount          = $Lists.Count
        DirectPercentageOfDocLib = "0%"
        DirectPercentageOfSite   = "100%"
        TotalFolderCount         = 0
        TotalFilesCount          = 0
        TotalItemCount           = $TotalSiteItemCount
        TotalPercentageOfDocLib  = "0%"
        TotalPercentageOfSite    = "100%"
    }


    foreach ($List in $Lists) {
        write-host "`t> $($List.Title)"

        if ($List.ItemCount -gt 0) {
            $Items = Get-PnPListItem -List $List -Fields "FileRef", "FileDirRef", "ItemChildCount", "FFSObjType", "ID", "FolderChildCount" -PageSize 5000 -Connection $Connection
           
            $Folders = $Items | Where-Object { $_.FieldValues.FSObjType -eq $FOLDER_OBJECT_TYPE } | Sort-Object -Property FileRef
            $Files = $Items | Where-Object { $_.FieldValues.FSObjType -ne $FOLDER_OBJECT_TYPE } | Sort-Object -Property FileRef

            $RootLevelFolderCount = $Folders | Where-Object { $_.FieldValues.FileDirRef -eq $List.RootFolder.ServerRelativeUrl } | Measure-Object | Select-Object -ExpandProperty Count
            $RootLevelFileCount = $Files | Where-Object { $_.FieldValues.FileDirRef -eq $List.RootFolder.ServerRelativeUrl } | Measure-Object | Select-Object -ExpandProperty Count
            $RootLevelItemCount = $RootLevelFolderCount + $RootLevelFileCount

            $Report += [PSCustomObject]@{
                Type                     = "Document Library"
                Id                       = $List.Id
                Path                     = $List.RootFolder.ServerRelativeUrl
                WebUrl                   = $Site.Url
                SiteTitle                = $Site.Title
                DocumentLibraryTitle     = $List.Title
                DocumentLibraryUrl       = $List.RootFolder.ServerRelativeUrl
                DocumentLibraryId        = $List.Id
                DirectFolderCount        = $RootLevelFolderCount
                DirectFilesCount         = $RootLevelFileCount
                DirectItemCount          = $RootLevelItemCount
                DirectPercentageOfDocLib = $RootLevelItemCount -gt 0 ? "$([Math]::Round(($RootLevelItemCount / $List.ItemCount) * 100, 2))%" : "0%"
                DirectPercentageOfSite   = $TotalSiteItemCount -gt 0 ? "$([Math]::Round(($RootLevelItemCount / $TotalSiteItemCount) * 100, 2))%" : "0%"
                TotalFolderCount         = $Folders.Count
                TotalFilesCount          = $Files.Count
                TotalItemCount           = $List.ItemCount
                TotalPercentageOfDocLib  = $List.ItemCount -gt 0 ? "$([Math]::Round(($List.ItemCount / $List.ItemCount) * 100, 2) ?? 0)%" : "0%"
                TotalPercentageOfSite    = $List.ItemCount -gt 0 ? "$([Math]::Round(($List.ItemCount / $TotalSiteItemCount) * 100, 2) ?? 0)%" : "0%"
            }
    


            foreach ($Folder in $Folders) {  
                Write-Host "`t`t> $($Folder.FieldValues.FileRef)"
                
                $TotalSubFolderCount = $Folders | Where-Object { $_.FieldValues.FileRef.StartsWith($folder.FieldValues.FileRef + "/") } | Measure-Object | Select-Object -ExpandProperty Count
                $TotalSubFilesCount = $Files | Where-Object { $_.FieldValues.FileRef.StartsWith($folder.FieldValues.FileRef) } | Measure-Object | Select-Object -ExpandProperty Count
                $TotalItemCount = $TotalSubFolderCount + $TotalSubFilesCount

                $DirectItemCount = ([int]$Folder.FieldValues.ItemChildCount + [int]$Folder.FieldValues.FolderChildCount)

                $Report += [PSCustomObject]@{
                    Type                     = "Folder"
                    Id                       = $Folder.Id
                    Path                     = $Folder.FieldValues.FileRef
                    WebUrl                   = $Site.Url
                    SiteTitle                = $Site.Title
                    DocumentLibraryTitle     = $List.Title
                    DocumentLibraryUrl       = $List.RootFolder.ServerRelativeUrl
                    DocumentLibraryId        = $List.Id
                    DirectFilesCount         = $Folder.FieldValues.ItemChildCount
                    DirectFolderCount        = $Folder.FieldValues.FolderChildCount
                    DirectItemCount          = $DirectItemCount
                    DirectPercentageOfDocLib = $DirectItemCount -gt 0 ? "$([Math]::Round(($DirectItemCount / $List.ItemCount) * 100, 2))%" : "0%"
                    DirectPercentageOfSite   = $DirectItemCount -gt 0 ? "$([Math]::Round(($DirectItemCount / $TotalSiteItemCount) * 100, 2))%" : "0%"
                    TotalFolderCount         = $TotalSubFolderCount
                    TotalFilesCount          = $TotalSubFilesCount
                    TotalItemCount           = $TotalItemCount
                    TotalPercentageOfDocLib  = $TotalItemCount -gt 0 ? "$([Math]::Round(($TotalItemCount / $List.ItemCount) * 100, 2))%" : "0%"
                    TotalPercentageOfSite    = $TotalItemCount -gt 0 ? "$([Math]::Round(($TotalItemCount / $TotalSiteItemCount) * 100, 2))%" : "0%"
                }
            }
        }
    }
}

$Report | Select-Object * | Export-Csv -Path "Report.csv" -NoTypeInformation
Invoke-Item -Path "Report.csv"
