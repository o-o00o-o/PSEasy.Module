function Get-NugetSource {
    param(
        [Parameter(Mandatory)][string]$NugetPath
    )
    & $NugetPath sources -format short |
    ForEach-Object {
        $firstSpace = $_.indexOf(' ')
        [PSCustomObject]@{
            Flags  = $_.substring(0, $firstSpace)
            Source = $_.substring($firstSpace + 1)
        }
    }
}
