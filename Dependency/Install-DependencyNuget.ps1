
    function Install-DependencyNuget {
      Param(
          [Parameter(Mandatory)]
          [string]
          # The path to the nuget.exe
          $NugetPath,

          [Parameter(Mandatory, ParameterSetName='NameVersion')]
          [string]
          # The name of the dependency as set in the dependency config file
          $Name,

          [Parameter(Mandatory, ParameterSetName='NameVersion')]
          [string]
          # The version
          $Version,

          [Parameter(Mandatory, ParameterSetName='PackageConfig')]
          [string]
          # The name of the dependency as set in the dependency config file
          $ConfigPath,

          [Parameter(Mandatory)]
          [string]
          # The destination folder to install to. This should end in "\Packages"
          $Destination#,

          # [Parameter(Position, Mandatory)]
          # [ValidateSet('Install','Initialise')]
          # [string[]]
          # # Indicates if we should install the dependency or also initialise in the current session (sometimes you want to delay this due to DLL hell)
          # $Run = @('Install')
      )
      # Ensure we have the source that we need
      Write-Verbose "$NugetPath sources list"
      $sources = & $NugetPath sources list
      if (-not ($sources -match 'nuget.org')) {
        Write-Verbose "$NugetPath sources Add -Name 'nuget.org' -Source 'https://api.nuget.org/v3/index.json'"
        $null =  & $NugetPath sources Add -Name 'nuget.org' -Source 'https://api.nuget.org/v3/index.json'
      }

      # Now get the packages
      New-Item -Path $Destination -ItemType directory -Force 1> $null

      if ($PSCmdlet.ParameterSetName -eq 'NameVersion') {
          Write-Verbose "$NugetPath install '$Name' -version '$Version' -OutputDirectory '$Destination' -ExcludeVersion -PackageSaveMode nuspec -ForceEnglishOutput -Source nuget.org -NonInteractive -verbosity detailed"
        & $NugetPath install $Name -version $Version -OutputDirectory $Destination -ExcludeVersion -PackageSaveMode nuspec -ForceEnglishOutput -Source nuget.org -NonInteractive -verbosity detailed
      } else {
        Write-Verbose "$NugetPath install '$ConfigPath' -OutputDirectory '$Destination' -ExcludeVersion -PackageSaveMode nuspec -ForceEnglishOutput -Source nuget.org -NonInteractive -verbosity detailed"
        & $NugetPath install $ConfigPath -OutputDirectory $Destination -ExcludeVersion -PackageSaveMode nuspec -ForceEnglishOutput -Source nuget.org -NonInteractive -verbosity detailed
      }
  }
