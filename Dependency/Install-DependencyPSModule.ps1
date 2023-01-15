function Install-DependencyPSModule {
    Param(
        [Parameter(Mandatory)]
        [string]
        # The name of the dependency as set in the dependency config file
        $Name,

        [Parameter(Mandatory)]
        [string]
        # The version
        $RequiredVersion,

        [Parameter()]
        [string]
        # The prerelease string. This the part after the - in the version
        $PreRelease,

        [Parameter()]
        [string]
        # The Repository to get it from, defaults to Nuget
        $Repository,

        [parameter()]
        [switch]
        # By default we won't install if already installed. Force will first remove then install again
        $Force

        # [parameter()]
        # [switch]
        # # normally PS will auto-import however not for types, so for those modules with types (e.g. pester) we import also.
        # $ForceImport
    )

    if ($RequiredVersion) {
        $currentModule = Get-Module -ListAvailable -Name $Name  | Where-Object { $_.Version -eq $RequiredVersion }
        $requiresInstall = -not $currentModule
    } else {
        # not finished, needs to be a bit smarter
        $latestVersion = (Get-Module -Name $Name -ListAvailable | Sort-Object Version -Descending)[0] # latest version
        $requiresInstall = $latestVersion.Version -lt ((Find-Module -Name | Sort-Object Version -Descending)[0]).Version
    }

    # Only install module if we don't already have it
    if ($requiresInstall -or $Force ) {
        Write-Host "Module $Name $RequiredVersion installing "
        # PSGallery is always untrusted and so we always need to force for this to be agreed in non-interactive mode
        if (-not [Environment]::UserInteractive -or
            ((Test-Path 'variable:UserInteractive') -and $UserInteractive -eq $false) # pscore doesn't honour UserInteractive setting, so we have to do it ourselves
        ) {
            $adjustedForce = $true
        } else {
            $adjustedForce = $Force
        }

        if ((Test-UserPrivilegeAdmin)) {
            $scope = 'AllUsers'
            $adjustedForce = $true
            $allowClobber = $true
        } else {
            $scope = 'CurrentUser'
            #$adjustedForce = $false # seems that force doesn't work with current user in ps7
            $allowClobber = $true # Az.Storage required this and does it do any harm?
        }
        #Install-Module -Name $Name -SkipPublisherCheck -AllowClobber -Force:$adjustedForce -RequiredVersion $RequiredVersion -Confirm:$false -Scope CurrentUser

        $InstallModuleArgs = @{
            Name = $Name
            SkipPublisherCheck = $true
            AllowClobber = $allowClobber
            Force = $adjustedForce
            Confirm = $false
            Scope = $scope
        }
        if ($RequiredVersion) {
            $InstallModuleArgs.Add('RequiredVersion', "$($RequiredVersion)$(if($PreRelease) {"-$PreRelease"})")
        }
        if ($PreRelease) {
            $InstallModuleArgs.Add('AllowPrerelease', [bool]$PreRelease)
        }
        if ($Repository) {
            $InstallModuleArgs.Add('Repository', $Repository)
        }

        ("Install-Module parameters" + ($InstallModuleArgs | Format-Table | Out-String)) | Write-Host
        Install-Module @InstallModuleArgs
    } else {
        Write-Host "Module $Name $RequiredVersion is already installed"

        # Write-Verbose "Import-Module $Name $RequiredVersion"
        # try {
        #      # force the import in case we already are using it
        #      $ImportModuleArgs = @{
        #         Name = $Name
        #         Force = $true
        #         RequiredVersion = ($RequiredVersion).Replace('-preview','')
        #     }
        #     ("Import-Module parameters" + ($ImportModuleArgs | Format-Table | Out-String)) | Write-Verbose
        #     Import-Module @ImportModuleArgs 3> $null
        # }
        # catch {
        #     $_ | Get-Error
        # }
    }

    # if ($ForceImport.IsPresent) {
    #     Import-Module -Name $Name -Force -ErrorAction SilentlyContinue
    # }
}
