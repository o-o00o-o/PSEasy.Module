<#<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER NugetPath
Path to Nuget

.PARAMETER OrganisationName
Azure Devops Organisation

.PARAMETER ProjectName
Azure Devops Project (if project scoped)

.PARAMETER FeedName
Artifacts Feed

.PARAMETER LegacyAddress
Whether we are using legacy addressing mode

.PARAMETER Username
Username to access the feed

.PARAMETER Password
Password to access the feed

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

Register-NugetArtifactSource @splat

.NOTES
General notes
#>
function Register-NugetArtifactSource {
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
        OrganisationName = $OrganisationName
        ProjectName      = $ProjectName
        FeedName         = $FeedName
        LegacyAddress    = $LegacyAddress
    }
    $source = Get-ArtifactSource @splat

    $installedSources = Get-NugetSource -NugetPath $NugetPath
    if ($source -in $installedSources.Source -and $Force) {
        & $NugetPath sources Remove -Name $FeedName -Source $source
    }

    if ($source -notIn $installedSources.Source -or $force) {
        & $NugetPath sources Add -Name $FeedName -Source $source -username $Username -password ($Password | ConvertFrom-SecureString -AsPlainText)
        if ($LASTEXITCODE -ne 0) {
            throw 'nuget sources add returned an error'
        }
    } else {
        Write-Verbose 'nuget source already exists'
    }

}
