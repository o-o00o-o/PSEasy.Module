# PSEasy.Module

a set of functions to publishing powershell modules

- Publish the module to a previously setup private feed, setting the ModulePath and VersionIncrementType

    ```powershell
    $splat = @{
        NugetPath            = $nugetPath
        FeedName             = 'Feed'
        ModulePath           = 'module\PSEasy.Utility'
    }
    Publish-NugetPackage @splat -VersionIncrementType Patch
    ```


## Setup development of this the PSEasy.Module itself if publishing/getting to Azure Devops artifacts

- If you don't yet have this module version on your machine you can bootstrap the functions into your session before installing properly by using the Import-ModuleFunction script and provide the Module

    ``` powershell
    . "module\PSEasy.Module\Module\Import-ModuleFunction.ps1" -ModulePath "$projectRoot\module\PSEasy.Utility"
    . .\src\PSEasy.Module\PSEasy.Module.build.ps1 -bootstrap
    ```

- Install the artifact credential provider on the machine

    ``` powershell
    Install-ArtifactCredentialProvider -AddNetfx
    ```

- Register the artifact for Nuget.exe to allow publishing

    ``` powershell
    $splat = @{
        NugetPath = $nugetPath
        OrganisationName = 'yourOrg'
        ProjectName = 'yourProj'
        FeedName = 'Feed'
        LegacyAddress = $true
        Username = 'Personal Access Token'
        Password = $azureDevOpsPat
    }
    Register-NugetArtifactSource @splat
    ```

- Register the artifact for Powershell nuget provider to allow Install-Module to work (get a Personal Artifact Token from Azure Devops and provide as a password)

    ``` powershell
    $splat = @{
        OrganisationName = 'yourOrg'
        ProjectName = 'yourProj'
        FeedName = 'Feed'
        LegacyAddress = $true
        Username = 'Personal Access Token'
        Password = $azureDevOpsPat
    }
    Register-PSArtifactSource @splat
    ```

- Now you can test you have the repository

    ``` powershell
    Get-PSRepository
    Get-PackageSource
    Find-Module '*' -Repository Feed
    ```

- Now install it

    ``` powershell
    Install-Module -Name PSEasy.Module -Repository Feed
    ```

## Developing the PSEasy.Module itself

- Make changes to the library
- Test directly by importing from the folder

    ``` powershell
    Build-Module .\src\PSEasy.Module\ -Import
    ```

- test it, change further, repeat
- once happy publish as Nuget to a repository and indicate how to increment the version as part of the activity

- Now publish it

    ``` powershell
    Set-ModuleVersion -modulepath '.\module\PSEasy.Module\' -VersionIncrementType Patch
    Publish-Module -path '.\module\PSEasy.Module\' -Verbose -NuGetApiKey 'Your key here' -whatif
    # then run without whatif if no errors
    ```

- Now others can use ```Install-Module``` to install from the published location
