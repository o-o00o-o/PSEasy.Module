function Install-ArtifactCredentialPassword {
    param(
        [Parameter(Mandatory)][string]$OrganisationName,
        [Parameter()][string]         $ProjectName,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter()][switch]         $LegacyAddress,
        [Parameter()][string]         $Username,
        [Parameter()][SecureString]   $Password,
        [Parameter()][switch]         $OutputAdoVariable
    )
    $VerboseParam = @{Verbose = [bool]$PSBoundParameters['Verbose'] }

    $splat = @{
        OrganisationName  = $OrganisationName
        ProjectName       = $ProjectName
        FeedName          = $FeedName
        LegacyAddress     = $LegacyAddress
        Username          = $Username
        Password          = $Password
        OutputAdoVariable = $OutputAdoVariable
    }
    $endpoints = Get-ArtifactEndpointCredential @splat

    $sessionTokenCacheEnabledName = 'Nuget_CredentialProvider_SessionTokenCache_Enabled'
    $externalFeedEndpointsName = 'VSS_NUGET_EXTERNAL_FEED_ENDPOINTS'
    if ($Force) {
        # clear all scopes to ensure we got them all
        Clear-EnvironmentVariable -Name $sessionTokenCacheEnabledName @VerboseParam
        Clear-EnvironmentVariable -Name $externalFeedEndpointsName @VerboseParam
    }

    Set-EnvironmentVariable -Name $externalFeedEndpointsName -value $endpoints @VerboseParam -Target User
    Set-EnvironmentVariable -Name $sessionTokenCacheEnabledName -value 'true' @VerboseParam -Target User
    Set-EnvironmentVariable -Name $externalFeedEndpointsName -value $endpoints @VerboseParam -Target Process
    Set-EnvironmentVariable -Name $sessionTokenCacheEnabledName -value 'true' @VerboseParam -Target Process
}
