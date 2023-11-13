function Get-Dependency {
    [CmdletBinding()]
    Param(

        [Parameter(Mandatory)]
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
        # The destination folder to install to (if required). If not provided uses the current working directory. Will create Depend-Nuget and Depend-WebDownload folders below this folder.
        $DestinationFolder = $pwd
    )
    try {
        $moduleFolder = $DestinationFolder

        $destinationTypes = 'Nuget','WebDownload'
        # $dependencyBuilder = [System.Collections.Generic.List[PSCustomObject]]::new()
        $dependencyBuilder = @{}

        foreach ($type in ($DependencyConfig | ConvertTo-Array2)) {
            Write-Debug "looking at $type"

            foreach ($dependency in ($type | ConvertTo-Array2 -AddProperties @{Type = $type.Name })) {
                Write-Debug "looking at $($dependency | Format-List | Out-String)"
                $loopDependencyPath = "$($dependency.Type)\\$($dependency.Name)"
                $destination = Join-Path $moduleFolder "Depend-$($dependency.Type)"

                if ($PSCmdlet.ParameterSetName -eq 'ScriptName') {

                    foreach ($scriptName in $ScriptNames) {
                        if ($dependency.PSObject.Properties['scripts'] -and $dependency.scripts -contains $scriptName) {
                            if ($dependency.Type -in $destinationTypes) {
                                $dependency | Add-Member 'destination' $destination -force
                            }
                            # only add if we don't already have it
                            if (-not $dependencyBuilder.Contains($loopDependencyPath)) {
                                $dependencyBuilder.Add($loopDependencyPath, $dependency)
                            }
                        }
                    }
                } else {
                    foreach ($DependencyPath in $DependencyPaths) {
                        $splitDependencyPath = ($DependencyPath.split('\'.ToCharArray()))
                        $type = $splitDependencyPath[0]
                        $name = $splitDependencyPath[1]
                        if (-not ('WebDownload', 'Nuget', 'Module', 'PackageProvider').Contains($type)) {
                            throw "$type is not a known installer type (from $DependencyPath)"
                        }
                        if ($dependency.type -eq $type -and $dependency.name -eq $name) {
                            Write-Debug "Found $($dependency | Format-List | Out-String)"
                            if ($dependency.Type -in $destinationTypes) {
                                $dependency | Add-Member 'destination' $destination -force
                            }
                            # only add if we don't already have it
                            if (-not $dependencyBuilder.Contains($loopDependencyPath)) {
                                $dependencyBuilder.Add($loopDependencyPath, $dependency)
                            }
                        }
                    }
                }
            }
        }

        if ($dependencyBuilder.Count -eq 0) {
            throw "No dependencies found for $($ScriptNames)$($DependencyPaths)"
        }

        $groupByType = (@($dependencyBuilder.GetEnumerator()).Value | Group-Object -Property Type)
        $loadOrder = [scriptblock] {
            switch ($_.Name) {
                'PackageProvider' { 1 }
                'WebDownload' { 2 }
                'Module' { 3 }
                'Nuget' { 4 }
                Default { 5 }
            } }
        Write-Output $groupByType | Sort-Object $loadOrder
    } catch {
        throw
    }
}
