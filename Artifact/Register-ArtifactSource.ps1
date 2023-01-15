<#<#
.SYNOPSIS
Registers ArtifactSource on both Nuget and PS provider

.EXAMPLE
$splat = @{
    NugetPath = ($VegaContext.nugetPath)
    OrganisationName = 'vrmobility'
    ProjectName = 'Vega'
    FeedName = 'Vega'
    LegacyAddress = $true
    Username = 'Personal Access Token'
    Password = ($VegaContext.adoPatWorkItemRW)
}
Register-ArtifactSource @splat

.NOTES
General notes
#>
function Register-ArtifactSource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$NugetPath,
        [Parameter(Mandatory)][string]$OrganisationName,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter()][switch]$LegacyAddress,
        [Parameter()][string]$Username,
        [Parameter()][SecureString]$Password,
        [Parameter()][switch]$Force
    )
    $splat = @{
        NugetPath = $NugetPath
        OrganisationName = $OrganisationName
        ProjectName = $ProjectName
        FeedName = $FeedName
        LegacyAddress = $LegacyAddress
        Username = $UserName
        Password = $Password
        Force = $Force
    }
    Register-NugetArtifactSource @splat

    $splat.Remove('NugetPath')

    Register-PSArtifactSource @splat
}
