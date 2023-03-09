<#<#
.SYNOPSIS
Registers the Artifact Repo in Powershell

.DESCRIPTION
Long description

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
    OrganisationName = 'yourOrg'
    ProjectName = 'yourProj'
    FeedName = 'Feed'
    LegacyAddress = $true
    Username = 'Personal Access Token'
    Password = $azureDevOpsPat
}

Register-PSArtifactSource @splat

Get-PSRepository
Get-PackageSource
Find-Module '*' -Repository Feed
Install-Module -Name PSEasy.Module -Repository Feed

.NOTES
General notes
#>#>
function Register-PSArtifactSource {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$OrganisationName,
        [Parameter()][string]         $ProjectName,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter()][switch]         $LegacyAddress,
        [Parameter()][string]         $Username,
        [Parameter()][SecureString]   $Password,
        [Parameter()][string]         $ProviderName = 'NuGet',
        [Parameter()][switch]         $Force,
        [Parameter()][switch]         $OutputAdoVariable
    )
    $VerboseParam = @{Verbose = [bool]$PSBoundParameters['Verbose']}

    $splat = @{
        OrganisationName = $OrganisationName
        ProjectName      = $ProjectName
        FeedName         = $FeedName
        LegacyAddress    = $LegacyAddress
    }
    $source = Get-ArtifactSource @splat

    Write-Verbose "Source = $source" @VerboseParam

    $credential = New-Object System.Management.Automation.PSCredential($Username, $Password)

    # setup the credentials to prevent the PS nuget from prompting
    # https://github.com/microsoft/artifacts-credprovider#setup

    $splat = @{
        OrganisationName  = $OrganisationName
        ProjectName       = $ProjectName
        FeedName          = $FeedName
        LegacyAddress     = $LegacyAddress
        Username          = $Username
        Password          = $Password
        OutputAdoVariable = $OutputAdoVariable
    }
    Install-ArtifactCredentialPassword @splat @VerboseParam

    $packageSource = Get-PackageSource | Where-Object { $_.Name -eq $FeedName -and $_.ProviderName -eq $ProviderName }
    if ($packageSource -and $Force) {
        if ($PSCmdlet.ShouldProcess("PackageSource", "Unregister")) {
            $packageSource | ForEach-Object {
                Write-Verbose "Unregister-PackageSource $($_.Name)" @VerboseParam
                UnRegister-PackageSource -Name $_.Name @VerboseParam
            }
        }
    }

    if ((Get-PSRepository | Where-Object { $_.Name -eq $FeedName }) -and $Force) {
        if ($PSCmdlet.ShouldProcess("PSRepository", "Unregister")) {
            Write-Verbose "Unregister-PSRepository $FeedName"  @VerboseParam
            UnRegister-PSRepository -Name $FeedName @VerboseParam
        }
    }

    if (-not (Get-PSRepository | Where-Object { $_.Name -eq $FeedName })) {
        if ($PSCmdlet.ShouldProcess("PSRepository", "Register")) {
            Write-Verbose "Register-PSRepository $FeedName" @VerboseParam

            $splat = @{
                Name               = $FeedName
                SourceLocation     = $source
                PublishLocation    = $source
                InstallationPolicy = 'Trusted'
                Credential         = $credential
            }
            Register-PSRepository @splat @VerboseParam
        }
    }

    if (-not (Get-PackageSource | Where-Object { $_.Name -eq $FeedName -and $_.ProviderName -eq $ProviderName })) {
        if ($PSCmdlet.ShouldProcess("PackageSource", "Register")) {
            Write-Verbose "Register-PackageSource $FeedName" @VerboseParam
            $splat = @{
                Name         = $FeedName
                Location     = $source
                ProviderName = $ProviderName
                Trusted      = $true
                SkipValidate = $true
                Credential   = $credential
            }
            Register-PackageSource @splat @VerboseParam
        }
    }
}
