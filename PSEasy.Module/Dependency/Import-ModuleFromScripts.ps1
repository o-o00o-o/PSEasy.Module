<#
.SYNOPSIS
Creates a dynamic module from a path containing PowerShell scripts

If the module requires dependencies, these can be imported using the DependencyConfig and DependencyPaths parameters

.EXAMPLE

$DependencyConfig = [PSCustomObject]@{
    Nuget = @(
        [PSCustomObject]@{
            Name = 'Microsoft.SqlServer.DacFx'
            "Version": "160.5400.1",
            "addType": [
                "lib\\netstandard2.1\\Microsoft.SqlServer.Dac.dll",
                "lib\\netstandard2.1\\Microsoft.SqlServer.TransactSql.ScriptDom.dll"
            ],
        }
    )
}
Invoke-DotInclude -Name 'Lodestar.GetModel' -Path "$root\GetModel\" -DependencyConfig $DependencyConfig -DependencyPaths @('Nuget\Microsoft.SqlServer.DacFx')

creates a module called dynamic.Lodestar.GetModel from the scripts in the GetModel folder, and imports the Nuget dependency Microsoft.SqlServer.DacFx which are needed as the function uses classes from this module

.NOTES
We built this to try to get around the issue of needing to include functions into the current session, but not being able to do so with . (dot) includes as any dot-sourcing in a module is scoped to the module and not the outer session.

However, while this function may be useful, it is probably better to create a proper module with a manifest and functions that are imported properly. Alternatively you can use the following pattern to do it in a native way that doesn't rely on this module at all.

    $paths = [System.Collections.Generic.List[string]]::new()

    $paths.Add("$root\GetModel\")
    $paths.Add("$root\TestMap\")

    $getCiSplat = @{
        Filter  = '*-*.ps1'
        File    = $true
        Recurse = $true
        Exclude = ('*.Tests.ps1')
    }

    $paths | Get-ChildItem @getCiSplat | ForEach-Object {
        Write-Debug "Importing function: $($_.FullName)"
        . $_.FullName
    }
#>
function Import-ModuleFromScripts {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Path,
        [Parameter()][string[]]$Exclude,
        [Parameter(ParameterSetName = "Dependencies")]
        [PSCustomObject]$DependencyConfig,
        [Parameter(ParameterSetName = "Dependencies")]
        [string[]]$DependencyPaths

    )
    Set-StrictMode -Version 2
    $moduleName = "dynamic.$Name"
    $module = New-Module -Name $moduleName -ScriptBlock {
        param (
            [Parameter(Mandatory)][string]$Path,
            [Parameter()][string[]]$Exclude,
            [Parameter()][PSCustomObject]$DependencyConfig,
            [Parameter()][string[]]$DependencyPaths
            )
        if ($DependencyPaths) {
            # foreach ($dependency in $Dependencies) {
                Import-Dependency -DependencyConfig $DependencyConfig -DependencyPaths $DependencyPaths -v
            # }
        }

        $Exclude += '*.Tests.ps1'
        Get-ChildItem $Path -Filter '*-*.ps1' -File -Recurse -Exclude $Exclude |
        ForEach-Object {
            Write-Debug "Including $_"
            . $_

        }

        $functions  = Get-Command -CommandType Function  | Where-Object { $_.ModuleName -eq $null }

        foreach($function in $functions) {
            Write-Debug "Exporting $($function.Name)"
            Export-ModuleMember -Function $function.Name
        }
    } -ArgumentList $Path, $Exclude, $DependencyConfig, $DependencyPaths

    $null = Import-Module $module -Global -Force # get all functions into this session so they can be used

    # Verify the module is imported
    if (Get-Module -Name $moduleName) {
        Write-Host "Module $moduleName imported successfully."
    } else {
        Write-Error "Failed to import module $moduleName."
    }
}
