#Requires -Version 5.0
using namespace System.Collections.Generic

<#
.SYNOPSIS

.EXAMPLE

.DESCRIPTION

.NOTES

#>
function Import-Dependency {
[CmdletBinding()]
Param(
    [Parameter()]
    [PSCustomObject]
    $DependencyConfig,

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
    # The destination folder to install to (if required). The gitroot will be found and folders added to the named subfolder e.g. application will result in c:\gitroot\application\...
    $DestinationFolder
)
try {
    Set-StrictMode -Version 2
    $ErrorActionPreference = "Stop"

    $splat = @{}
    if ($DependencyPaths) { $splat.Add('DependencyPaths', $DependencyPaths) }
    if ($ScriptNames) { $splat.Add('ScriptNames', $ScriptNames) }
    if ($DependencyConfig) { $splat.Add('DependencyConfig', $DependencyConfig) }
    if ($DestinationFolder) { $splat.Add('DestinationFolder', $DestinationFolder) }
    $groupedDependencies = Get-Dependency @splat

    foreach ($typeGroup in $groupedDependencies) {
        if ($typeGroup.Name -eq 'PackageProvider') {
        } elseif ($typeGroup.Name -eq 'WebDownload') {
        } elseif ($typeGroup.Name -eq 'Module') {
            foreach ($dependency in $typeGroup.Group) {
                Write-Verbose "Import-Module $($dependency.name) $($dependency.version)"

                $splat = @{
                    Name = $dependency.Name
                }

                if ($dependency.PSObject.Properties['forceImport']) {
                    # force the import in case we already are using it
                    $splat.Add('Force', $true)
                }

                if ($dependency.PSObject.Properties['Version']) {
                    $splat.Add('RequiredVersion', ($dependency.version).Replace('-preview', ''))
                }

                ("Import-Module parameters" + ($splat | Format-Table | Out-String)) | Write-Verbose
                try {
                    Import-Module @splat 3> $null
                } catch {
                    Write-Warning "Import-Module $($dependency.name) $($dependency.version) failed with $_. For more details run with -verbose" # add details on existing version as expect this has a different version loaded
                    $_ | Get-Error | Out-String | Write-Verbose
                }
            }
        } elseif ($typeGroup.Name -eq 'Nuget') {
            Write-Verbose 'Initialising Nuget Payload'
            foreach ($nugetConfigItem in ($typeGroup.Group | Where-Object { $_.PSObject.Properties['copyItemFromPackage'] } )) {
                foreach ($copyItem in $nugetConfigItem.copyItemFromPackage) {
                    $fromPackage = $typeGroup.Group | Where-Object { $_.Name -eq $copyItem.FromPackageName }

                    if (-not $fromPackage) {
                        throw "Can't find package $copyItem.FromPackageName in set of nuget Packages. Ensure that it exists in the dependency config and that it exists for the current PSEdition and same 'script'"
                    }

                    $typeArgs = @{
                        Path        = Join-Path (Join-Path $fromPackage.Destination $fromPackage.Name) $copyItem.fromPath
                        Destination = Join-Path (Join-Path $nugetConfigItem.Destination $nugetConfigItem.Name) $copyItem.toPath
                        Force       = $true
                        Confirm     = $false
                    }
                    $destinationPath = (Join-Path $typeArgs.Destination (Split-Path -Leaf $typeArgs.Path)) # destination is only the folder so add the filename to it
                    $destinationExists = Test-Path -Path $destinationPath

                    if ((
                            -not $destinationExists
                        ) -or (
                            $destinationExists -and
                            (Get-Item -Path $typeArgs.Path).LastWriteTime -ne # source has a different date
                                (Get-Item -Path $destinationPath).LastWriteTime
                        )
                    ) {
                        (
                        ('$typeArgs = @{') +
                        ($typeArgs.GetEnumerator() | Foreach-Object { "`n`t{0} = '{1}'" -f @($_.Name, $_.Value) }) +
                        ("`n}`n") +
                            "Copy-Item @typeArgs -verbose"
                        ) | Write-Verbose

                        Copy-Item @typeArgs
                    }
                }
            }

            foreach ($nugetConfigItem in ($typeGroup.Group | Where-Object { $_.PSObject.Properties['addType'] } )) {
                foreach ($typePath in $nugetConfigItem.addType) {
                    $typeArgs = @{
                        DependencyFolder = (Split-Path -Parent -Path $nugetConfigItem.Destination)
                        NugetPackageName = $nugetConfigItem.Name
                        PathToDll        = $typePath
                    }
                    Add-TypeFromNugetPackage @typeArgs
                }
            }

            foreach ($nugetConfigItem in ($typeGroup.Group | Where-Object { $_.PSObject.Properties['importModule'] } )) {
                foreach ($importModulePath in $nugetConfigItem.importModule) {
                    $typeArgs = @{
                        DependencyFolder = (Split-Path -Parent -Path $nugetConfigItem.Destination)
                        NugetPackageName = $nugetConfigItem.Name
                        PathToPsm1       = $importModulePath
                    }
                    Import-ModuleFromNugetPackage @typeArgs
                }
            }
        } else {
            Write-Error "Type $($typeGroup.Name) not expected. No installer known"
        }
    }
} catch {
    throw
}
}
