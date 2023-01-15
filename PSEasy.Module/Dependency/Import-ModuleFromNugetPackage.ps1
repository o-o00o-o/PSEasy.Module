function Import-ModuleFromNugetPackage {
param(
  [string]$DependencyFolder,
  [string]$NugetPackageName,
  [string]$PathToPsm1
)
$ModulePath = Join-Path (Join-Path (Join-Path $DependencyFolder 'Depend-NuGet') $NugetPackageName) $PathToPsm1
if (! (Test-Path $ModulePath)) {
    Write-Error "$PathToPsm1 module not found in $ModulePath"
}
get-childitem $ModulePath | Import-Module -Force
}
