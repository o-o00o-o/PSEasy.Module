function Install-DependencyPSPackageProvider {
  Param(
      [Parameter(Mandatory)]
      [string]
      # The name of the dependency as set in the dependency config file
      $Name,

      [Parameter(Mandatory)]
      [string]
      # The version
      $RequiredVersion,

      [parameter()]
      [switch]
      # By default we won't install if already installed. Force will first remove then install again
      $Force
  )
  if (-not (Get-PackageProvider -ListAvailable -Name $Name |
      #Where-Object {$_.Name -eq $Name -and $_.Version -eq $RequiredVersion}) -or
      Where-Object {$_.Version -eq $RequiredVersion}) -or
      $Force)
  {
      Write-Host "Package Provider $Name $RequiredVersion installing"
      Install-PackageProvider -Name $Name -Force:$Force -RequiredVersion $RequiredVersion -Confirm:$false -Scope CurrentUser
  } else {
      Write-Host "Package Provider $Name $RequiredVersion is already installed"
  }

}