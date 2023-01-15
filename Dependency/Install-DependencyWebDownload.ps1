function Install-DependencyWebDownload {
  Param(
      [Parameter(Mandatory)]
      [string]
      # The name of the dependency as set in the dependency config file
      $Name,

      [Parameter(Mandatory)]
      [string]
      # The version
      $Version,

      [Parameter(Mandatory)]
      [string]
      # Where to get the package from
      $Url,

      [Parameter(Mandatory)]
      [string]
      # The destination folder to install to (if required). The Name will be added as an additional folder
      $Destination,

      [parameter()]
      [switch]
      # By default we won't install if already installed. Force will first remove then install again
      $Force
  )

  # always put in a seperate folder to prevent dll clashes etc
  $destinationFolder = Join-Path $Destination $Name
  $versionFile = Join-Path $destinationFolder 'version.txt'
  # If it isn't an archive, then it will be a normal file
  $isArchive = [System.IO.Path]::GetExtension((Split-Path -Leaf $Url)) -eq '.zip'
  if ($isArchive) {
      $intermediatePath = ([System.IO.Path]::GetTempFileName()) -replace "\.tmp", ".zip"
  } else {
      $intermediatePath = Join-Path $destinationFolder ([System.IO.Path]::GetFileName((Split-Path -Leaf $Url)))
  }

  try {
      # If we are forcing then remove what was there before
      if ($Force -and (Test-Path -Path $destinationFolder)) {
          Write-Verbose "Removing $destinationFolder"
          Remove-Item -Path $destinationFolder -Recurse -Force
      }

      # if folder already exists then check the version
      $existingVersion = [Version]"0.0"
      if (Test-Path -Path $destinationFolder) {
          if (Test-Path -Path $versionFile) {
              $existingVersion = [Version](Get-Content $versionFile)
              Write-Verbose "existing version is $existingVersion from $versionFile"
          } else {
              Write-Verbose "no version file exists, assuming version 0.0. checked $versionFile"
          }
      } else {
          Write-Verbose "destination folder $destinationFolder doesn't exist"
      }
      $requiredVersion = [Version]$Version
      Write-Verbose "required version is $requiredVersion"

      # only download and unpack if the folder doesn't already exist or if the version is higher
      if ($existingVersion -lt $requiredVersion) {
          Write-Host "$Name is at $existingVersion but $requiredVersion is required. Upgrading."
          # first remove any existing files to make sure we have a clean landing area
          if ((Test-Path -Path $destinationFolder)) {
              Write-Verbose "Removing $destinationFolder"
              Remove-Item -Path $destinationFolder -Recurse -Force
          }
          # create the folder and version file
          New-Item -Path $destinationFolder -ItemType directory -Force > $null
          New-Item -Path $versionFile -value $Version > $null

          # Download the file
          [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls" ## Most modern websites mandate higher levels of SSL encryption. This ensures that the highest is selected first.
          Write-Verbose "Downloading '$url' to '$intermediatePath'"
          Invoke-WebRequest -Uri $url -OutFile $intermediatePath

          # Extract if is archive
          if ($isArchive) {
              Write-Verbose "Extracting '$intermediatePath' to '$destinationFolder'"
              Expand-Archive -Path $intermediatePath -DestinationPath $destinationFolder -Force
          }
      }
      else {
          Write-Host "$Name $Version is already installed"
      }
  }
  finally {
      if ($isArchive -and (Test-Path $intermediatePath)) {
          Remove-Item -Path $intermediatePath -Force
      }
  }
}
