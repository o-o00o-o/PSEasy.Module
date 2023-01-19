#Requires -Version 5.0
using namespace System.Collections.Generic

<#
.SYNOPSIS

.EXAMPLE

.DESCRIPTION

.NOTES

#>
function Install-Dependency {
[CmdletBinding()]
Param(
    [Parameter()]
    [PSCustomObject]
    # All required dependencies for the application
    $DependencyConfig,

    [Parameter()]
    [PSCustomObject]
    # Repository configuration providing passwords for each repo
    $RepositoryConfig,

    [Parameter(ParameterSetName = "DependencyPath", Mandatory)]
    [Alias('DependencyPath')]
    [string[]]
    $DependencyPaths,

    [Parameter(ParameterSetName = "ScriptName", Mandatory)]
    [Alias('ScriptName')]
    [string[]]
    $ScriptNames,

    [Parameter()]
    [string]
    # The destination folder to install to (required for nuget and web-download types).
    # If not given The gitroot will be found and folders added to the named subfolder.
    $DestinationFolder,

    [parameter()]
    [switch]
    # By default we won't install if already installed. Force will first remove then install again
    $Force,

    [parameter()]
    [switch]
    # Automatically import after install
    $Import,

    # if set will force the scope (useful for server installation where you want installation to be for all users)
    [Parameter()]
    [ValidateSet('','AllUsers', 'CurrentUser')]
    [String]
    $ForceScope
)
try {

    Set-StrictMode -Version 2
    $ErrorActionPreference = "Stop"

    # get the dependencies asked for
    $dependencySplat = @{
        DestinationFolder = $DestinationFolder
    }
    if ($DependencyPaths) { $dependencySplat.Add('DependencyPaths', $DependencyPaths) }
    if ($ScriptNames) { $dependencySplat.Add('ScriptNames', $ScriptNames) }
    if ($DependencyConfig) { $dependencySplat.Add('DependencyConfig', $DependencyConfig) }
    $groupedDependencies = Get-Dependency @dependencySplat

    if ($ScriptNames) {
        Write-Host "Installing Dependencies for Scripts: $([string]::Join(', ', $ScriptNames))"
    } elseif ($DependencyPaths) {
        Write-Host "Installing Dependencies for Dependency Paths: $([string]::Join(', ', $DependencyPaths))"
    }

    # install them
    foreach ($typeGroup in $groupedDependencies) {
        if ($typeGroup.Name -eq 'PackageProvider') {
            foreach ($dependency in $typeGroup.Group) {
                $splat = @{
                    Name            = $Dependency.name
                    RequiredVersion = $Dependency.Version
                    Force           = $Force
                }

                Install-DependencyPSPackageProvider
            }
        } elseif ($typeGroup.Name -eq 'WebDownload') {
            foreach ($dependency in $typeGroup.Group) {
                $splat = @{
                    Name        = $Dependency.name
                    Version     = $Dependency.Version
                    Url         = $Dependency.Url
                    Destination = $Dependency.destination
                    Force       = $Force
                }

                Install-DependencyWebDownload @splat
            }
        } elseif ($typeGroup.Name -eq 'Module') {
            foreach ($dependency in $typeGroup.Group) {

                $splat = @{
                    Name            = $Dependency.name
                    RequiredVersion = $Dependency.Version
                    Force           = $Force
                    # ForceImport     = [bool]$Dependency.PSObject.Properties['forceImport']
                }
                if ($Dependency.PSObject.Properties['preRelease']) {
                    $splat.Add('PreRelease', $Dependency.PreRelease)
                }
                if ($Dependency.PSObject.Properties['allowClobber']) {
                    $splat.Add('AllowClobber', $Dependency.AllowClobber)
                }

                if ($ForceScope) {
                    $splat.Add('ForceScope', $ForceScope)
                }
                elseif ($Dependency.PSObject.Properties['ForceScope']) {
                    $splat.Add('ForceScope', $Dependency.ForceScope)
                }

                if ($Dependency.PSObject.Properties['Repository']) {
                    $splat.Add('Repository', $Dependency.Repository)
                    if ($RepositoryConfig -and
                        $RepositoryConfig.HasProperties() -and
                        $RepositoryConfig.PSObject.Properties[$Dependency.Repository] -and
                        $RepositoryConfig."$($Dependency.Repository)".PSObject.Properties['AdoArtifact']
                    ) {
                        $artifactConfig = $RepositoryConfig."$($Dependency.Repository)".AdoArtifact
                        ("Artifact Configuration for this Repository" + ($artifactConfig | Format-List | Out-String)) | Write-Verbose
                        if ($artifactConfig.PSObject.Properties['Password']) {
                            $splat.Add('Credential', (Get-CredentialSilently -Username $artifactConfig.Username -Password $artifactConfig.Password))
                        }
                    }
                }

                Install-DependencyPSModule @splat
            }
        } elseif ($typeGroup.Name -eq 'Nuget') {
            $splat = @{
                # TODO put nuget in the path so we don't need to absolute it
                NugetPath   = (Join-Path (Split-Path -Parent -Path $typeGroup.Group[0].Destination) 'Depend-WebDownload\NuGet\nuget.exe')
                Destination = $typeGroup.Group[0].destination
            }

            # Install-DependencyNuget @splat
            $typeGroup.Group | Format-List | Out-String | Write-Verbose
            $nuGetConfigTemplate = @"
<!-- DO NOT CHANGE THIS: This is autogenerated by Install-Dependency so anything you do here will be undone. Use dependencies.global.json to control what gets installed by which script-->
<packages>$($typeGroup.Group | Foreach-Object { [string]::format("`n`t<package id=""{0}"" version=""{1}"" />",$_.Name,$_.version)})
</packages>
"@
            $nuGetConfigFolderName = "Install-Dependency-Nuget$(([IO.Path]::GetFileNameWithoutExtension([IO.Path]::GetRandomFileName())))"
            $nuGetConfigFolder = "$(Join-Path ($env:TMP) $nuGetConfigFolderName)"
            try {
                $null = New-Item -ItemType Directory $nuGetConfigFolder -Force
                $nuGetConfigPath = Join-Path $nuGetConfigFolder "packages.config"
                Write-Verbose "Generated File: $nuGetConfigPath `n----------------------------`n$nuGetConfigTemplate`n----------------------------"
                $null = New-Item -ItemType File -Path $nuGetConfigPath -Value $nuGetConfigTemplate -Force
                Install-DependencyNuget -ConfigPath $nuGetConfigPath @splat
            } finally {
                Remove-Item $nuGetConfigFolder -force -recurse -ErrorAction 'SilentlyContinue' # cleanup, although with whatif this will error so ignore it
            }
        } else {
            Write-Error "Type $($typeGroup.Name) not expected. No installer known"
        }
    }

    if ($Import) {
        & Import-Dependency @dependencySplat
    }
} catch {
    throw
}
}
