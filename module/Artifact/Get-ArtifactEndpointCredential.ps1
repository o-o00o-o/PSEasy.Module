function Get-ArtifactEndpointCredential {
    param(
        [Parameter(Mandatory)][string]$OrganisationName,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter()][switch]$LegacyAddress,
        [Parameter()][string]$Username,
        [Parameter()][SecureString]$Password,
        [Parameter()][switch]$OutputAdoVariable
    )
    $splat = @{
        OrganisationName = $OrganisationName
        ProjectName      = $ProjectName
        FeedName         = $FeedName
        LegacyAddress    = $LegacyAddress
    }
    $source = Get-ArtifactSource @splat

    # e.g. {"endpointCredentials": [{"endpoint":"http://example.index.json", "username":"optional", "password":"accesstoken"}]}
    $endpoints = [PSCustomObject]@{
        endpointCredentials = @(
            [PSCustomObject]@{
                endpoint = $source
                username = $Username
                password = ($Password | ConvertFrom-SecureString -AsPlainText)
            }
        )
    } | ConvertTo-Json -Compress

    if ($OutputAdoVariable) {
        # used for AzureDevops so that later steps can use this
        Write-Host "##vso[task.setvariable variable=PackageFeedEndpointCredential;issecret=true]$endpoints"
    }
}
