function Get-ArtifactSource {
        param(
        [Parameter(Mandatory)][string]$OrganisationName,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter()][switch]$LegacyAddress
    )
    if ($LegacyAddress) {
        $source = "https://$OrganisationName.pkgs.visualstudio.com$(if ($ProjectName) {"/$ProjectName"})/_packaging/$FeedName/nuget/v2"
        #$source = "https://$OrganisationName.pkgs.visualstudio.com$(if ($ProjectName) {"/$ProjectName"})/_packaging/$FeedName/nuget/v3/index.json"
    } else {
        $source = "https://pkgs.dev.azure.com/$OrganisationName$(if ($ProjectName) {"/$ProjectName"})/_packaging/$FeedName/nuget/v2"
        #$source = "https://pkgs.dev.azure.com/$OrganisationName$(if ($ProjectName) {"/$ProjectName"})/_packaging/$FeedName/nuget/v3/index.json"
    }
    Write-Output $source
}
