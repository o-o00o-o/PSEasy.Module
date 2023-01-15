# Powershell Module Development

## General Powershell authoring

- always use [approved verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3) in your functions
- [New-Module for creating dynamic/temporary modules from script blocks](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-module?view=powershell-7.3)
- [New-ScriptFileInfo to get help details](https://learn.microsoft.com/en-us/powershell/module/powershellget/new-scriptfileinfo?view=powershell-7.3)

- [Get-Command for getting file contents into a scriptblock](https://stackoverflow.com/a/27993341/7815011)

``` powershell
$sb = get-command C:\temp\add-numbers.ps1 | select -ExpandProperty ScriptBlock
```

- https://learn.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-script-module?view=powershell-7.3
- https://learn.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest?view=powershell-7.3

## Development Activities


``` powershell

# Directly Import from working folder
Import-Module .\src\PSEasy.Module\ -force -PassThru # NOTE module functions only available in this PS session

# Install from local folder
Install-ModuleFromFolder .\src\PSEasy.Module\ | fl

# execute private function in a module (debugging/testing)
Invoke-ModuleFunction 'PSEasy.Utility' {Get-LogPath @blah}
```

## Artifacts

``` powershell

Install-ArtifactCredentialProvider -AddNetfx

.\build\Depend-WebDownload\NuGet\nuget.exe spec PSEasy.Module
.\build\Depend-WebDownload\NuGet\nuget.exe pack PSEasy.Module
https://vrmobility.pkgs.visualstudio.com/Vega/_packaging/Vega/nuget/v2/
nuget sources Add -Name "Vega" -Source "https://vrmobility.pkgs.visualstudio.com/Vega/_packaging/Vega/nuget/v2/" -username "Personal Access Token" -password "<PERSONAL_ACCESS_TOKEN>"

```

## Pester / Testing

- https://stackoverflow.com/questions/53184460/pester-test-non-exported-powershell-cmdlets-function

## Nuget in Powershell

- https://github.com/apurin/powershellget-module
- https://stackoverflow.com/questions/33433824/create-pure-powershell-nuget-module-for-powershellget
- maybe related? https://learn.microsoft.com/en-us/powershell/scripting/gallery/how-to/getting-support/bootstrapping-nuget?view=powershell-7.3

- https://stackoverflow.com/questions/68544815/how-to-install-a-nuget-package-such-as-it-can-be-loaded-from-powershell

## Nested Modules

It seems that we typically don't need nested modules but here are some references

- https://social.technet.microsoft.com/Forums/en-US/e3f33003-3222-4c0d-873b-6673bb47e4ce/powershell-nested-modules
- https://stackoverflow.com/questions/55397323/powershell-module-call-function-in-nestedmodule-from-another-nestedmodulehttps://www.sapien.com/blog/2015/08/19/get-commands-in-a-nested-module/#:~:text=Many%20Windows%20PowerShell%20modules%20include%20nested%20modules.%20In,course%2C%20they%20require%20something%20in%20the%20parent%20module.

## Useful Links

- [Manifest Details](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_module_manifests?view=powershell-7.3)


## NuGet

- https://stackoverflow.com/questions/33433824/create-pure-powershell-nuget-module-for-powershellget


## Azure Devops

- https://learn.microsoft.com/en-us/azure/devops/artifacts/tutorials/private-powershell-library?view=azure-devops
- https://faun.pub/creating-and-publishing-powershell-modules-to-azure-artifacts-with-azure-devops-yaml-pipelines-246fcaa355b
- https://ochzhen.com/blog/install-powershell-module-from-azure-artifacts-feed
