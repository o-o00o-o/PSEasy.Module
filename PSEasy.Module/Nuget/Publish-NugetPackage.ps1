<#<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER NugetPath
Parameter description

.PARAMETER FeedName
Parameter description

.PARAMETER ModulePath
Parameter description

.PARAMETER VersionIncrementType
Parameter description

.PARAMETER ApiKey
Parameter description

.EXAMPLE
$splat = @{
    NugetPath            = $nugetPath
    FeedName             = 'Feed'
    ModulePath           = 'module\PSEasy.Module'
}
Publish-NugetPackage @splat -VersionIncrementType None

.NOTES
General notes
#>#>
function Publish-NugetPackage {
    param (
        [Parameter(Mandatory)][string]$NugetPath,
        [Parameter(Mandatory)][string]$ModulePath,
        [Parameter(Mandatory)][string]$FeedName,
        [Parameter(Mandatory)][ValidateSet('Major', 'Minor', 'Patch', 'None')][string]$VersionIncrementType,
        [Parameter()][string]$ApiKey = 'any key will do'
    )
    $moduleName = (Split-Path $ModulePath -Leaf)
    $nuspecPath = (Join-Path $ModulePath "$moduleName.nuspec")

    if (-not (Test-Path $nuspecPath)) {
        # build nuspec
        Push-Location $ModulePath
        try {
            & $NugetPath Spec $moduleName
            if ($LASTEXITCODE -ne 0) {
                throw 'nuget spec returned an error'
            }
        } finally {
            Pop-Location
        }
    }

    # update version
    Set-ModuleVersion -ModulePath $ModulePath -VersionIncrementType $VersionIncrementType

    # TODO set other things (e.g. description) in the nuspec from the .build-module.config

    # build nupkg
    & $NugetPath Pack $nuspecPath -OutputFileNamesWithoutVersion -NonInteractive -NoPackageAnalysis -OutputDirectory $ModulePath
    if ($LASTEXITCODE -ne 0) {
        throw 'nuget pack returned an error'
    }

    # publish
    & $NugetPath Push -Source $FeedName -ApiKey $ApiKey (Join-Path $ModulePath "$ModuleName.nupkg")
    if ($LASTEXITCODE -ne 0) {
        throw 'nuget push returned an error'
    }
}
