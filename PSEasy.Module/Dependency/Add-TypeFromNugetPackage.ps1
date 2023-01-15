<#
.SYNOPSIS

Extends Add-Type to make it easier and faster when we need to add libraries from nuget

.DESCRIPTION

This will first check if the assembly is already loaded and then if it is check if we are trying to load a later version. If we are we will send a warning as this could create a future issue

.NOTES

If you have the choice of netstandard or netcoreapp you should be able to use either

To work through DLL hell see https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/resolving-dependency-conflicts?view=powershell-7.2

Other helpers

If you run Install-Dependency with the -Initialise switch, it will automatically add the types defined in the addType array in \config\dependencies.global.json

Also we have a library\Get-Assembly function (gass alias) that can help to understand what is currently loaded

.EXAMPLE

EXAMPLE 1

Load the assembly "lib\netstandard2.0\Microsoft.Build.Framework.dll" from the Microsoft.Build.Framework nuget package that has been deploy to the deploy folder

    $typeArgs = @{
        DependencyFolder = 'deploy'
        NugetPackageName = "Microsoft.Build.Framework"
        PathToDll = "lib\netstandard2.0\Microsoft.Build.Framework.dll"
    }
    & "$PSScriptRoot\..\library\Add-TypeFromNugetPackage.ps1" @typeArgs

this is equivalent to

    Add-Type 'deploy\Depend-NuGet\Microsoft.Build.Framework\lib\netstandard2.0\Microsoft.Build.Framework.dll'

but with the active checking and better warnings
#>
function Add-TypeFromNugetPackage {
    [CmdletBinding()]
    param(
        [string]$DependencyFolder,
        [string]$NugetPackageName,
        [string]$PathToDll
    )
    try {
        $filePath = Join-Path (Join-Path (Join-Path $DependencyFolder 'Depend-NuGet') $NugetPackageName) $PathToDll
        $SessionVariable = "$((Split-Path $DependencyFolder -Leaf).Replace('-','_'))Dependency" # HACK
        $SessionCollection = 'AddTypeFromNugetPackage'
        if (-not (Test-PSSessionEntry -GlobalVariableName $SessionVariable -CollectionName $SessionCollection -Value $filePath)) {
            # only try if we haven't added already this session
            $dll = Split-Path -Leaf $PathToDll
            # Always check that the dll exists (to prevent non-deterministic errors if Install-Dependency and Add-TypeFromNugetPackage not in sync)

            if (-not (Test-Path $filePath)) {
                throw "Library path '$filePath', does not exist. Has it been installed?"
            } else {
                # Only do it if we don't alreay have it loaded
                $existingAssembly = [appdomain]::currentdomain.getassemblies() | where-object { $_.ManifestModule.Name -eq $dll }

                if ($null -eq $existingAssembly) {
                    Write-Verbose "Add-Type -Path '$filePath'"
                    Add-Type -Path $filePath
                } else {
                    # Warn if the version we want is a later version than the one that exists
                    $existingAssembly | Format-List | Out-STring | Write-Verbose

                    $existingAssemblyFileVersion = ($existingAssembly.ManifestModule.Assembly.GetCustomAttributesData() |
                        where-object { $_.AttributeType.Name -eq 'AssemblyFileVersionAttribute' }).ConstructorArguments[0]

                    $existingAssemblyFileVersion | Format-Table | Out-STring | Write-Verbose

                    $existingAssemblyVersion = [version]($existingAssemblyFileVersion.Value)

                    $fileVersionInfo = (Get-Command $filePath).FileVersionInfo
                    $fileVersionInfo | Format-List | Out-String | Write-Verbose

                    $fileVersionRegexResult = $fileVersionInfo.FileVersion | Select-String -Pattern '^(?<version>[0-9\.]+)'
                    $fileVersion = [Version]($fileVersionRegexResult.Matches.Groups | Where-Object { $_.name -eq 'version' }).Value

                    if ($fileVersion -gt $existingAssemblyVersion) {
                        Write-Warning ("an earlier $dll already exists in this session so we couldn't load it. This might cause dll load failures if the requested version is depended on by another library and the existing one is not compatible. `nRequested Version: {0,-18} from $filePath`n Existing version: {1,-18} from $($existingAssembly.ManifestModule.FullyQualifiedName)`nSolutions are to 1. Restart your powershell session in case it is contaminated 2. try to align libraries to have compatible dependency versions 3. run powershell in an isolated session" -f @($fileVersion, $existingAssemblyVersion)) -ErrorAction Stop
                    }
                }
                Add-PSSessionEntry -GlobalVariableName $SessionVariable -CollectionName $SessionCollection -Value $filePath # Record so we don't try again this session
            }
        }
    } catch {
        throw
    }
}
