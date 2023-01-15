<#<#
.SYNOPSIS
Registers ArtifactSource on both Nuget and PS provider

.EXAMPLE
$splat = @{
    NugetPath = $nugetPath
    OrganisationName = 'yourOrg'
    ProjectName = 'yourProj'
    FeedName = 'Feed'
    LegacyAddress = $true
    Username = 'Personal Access Token'
    Password = $azureDevOpsPat
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
