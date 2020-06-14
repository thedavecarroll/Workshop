# How to Build a New Module

## Module Purpose

When creating a module, be sure to select a topic or group of tasks that are currently under-represented in the PowerShell community.
This could help identify the starting point for the module name and the topics.

For possible topics, consult the categories found in the [Microsoft Script Center Gallery](https://gallery.technet.microsoft.com/scriptcenter).
Topics should be used as the PSData tags list.

## Create Custom LinkS

Using [Bit.ly](https://bit.ly), do the following:

1. Create a new custom link for the module name.
   * Ex. PoShEvents or PwshGreatModule.
2. Create a new custom link for the module help.
   * Ex. PoshEventsHelp or PwshGreatModuleHelp.

* Try to create a module name that makes sense and is available as a custom link.
* This will secure both URLs for future use.

## Create Repository in GitHub

Create a new repository in [GitHub](https://www.github.com).

* Name the repo the same as the name as the bit.ly custom link.
* Add a short Description for the module.
* Select Initialize this repository with a README.
* Create the new repo.
* After the repo is created, update the Topics.
  * Include the following:
    * powershell
    * powershell-module
    * *modulename*
    * Add topics

## Clone the Repo

Clone the repo to your development system.

In a git capable client:

```powershell
git clone https://github.com/<user_name>/<repo_name>.git
```

## Module Scaffolding

Once you have the bare structure of the module repo cloned locally, you will need to create the file structure.
This scaffolding is typically performed by using the **Plaster** module and a Plaster template.
Additionally, the **BuildHelpers** module will be used by the Plaster template.

1. Use the Plaster template
2. Step 2
3. Step n

## Write Code

### Functions

Separate functions into Public and Private.

### Classes

Create classes as required.
If the module must support PowerShell versions prior to 5, classes must be created using .Net methodology.

### Types and Formats

If required, create type and format XML.

### Testing

Create **Pester** testing scripts.

#### Meta

#### Help

#### Unit

#### Integration

## Generate Help

### about_ModuleName

### External Help

### Online Help

### Updatable Help

## Build Module Release

1. Update CHANGELOG
2. Update module manifest
3. The `build.ps1` script will *compile* the `.psm1` file.

  * f
  * d

### CHANGELOG

See [PowerShellForGitHub Module CHANGELOG](https://github.com/PowerShell/PowerShellForGitHub/blob/master/CHANGELOG.md) for an example.

#### Release Header Types

* Unreleased
* [0.2.1] - YYYY-MM-DD Feature Release
* [0.2.0] - YYYY-MM-DD Bugfix Release, Update Recommended
* [0.1.1] - YYYY-MM-DD Security Release, Update Strongly Recommended
* [0.1.0] - YYYY-MM-DD Maintenance Release, Update Not Required

The release version number should link to the corresponding commit.

After the last commit for the release, the CHANGELOG should be updated with the correct commit link.

#### Type and Order of CHANGELOG entries

1. Security - addresses vulnerabilities
2. Deprecated - soon-to-be removed features
3. Removed - now removed features
4. Changed - changes in existing functionality or how something works
5. Fixed - bug fixes
6. Added - new features
7. Maintenance - fixing anything that does not fit into any of the above categories

## GitHub Release Tag

Create GitHub release tag and upload assets for release.

## Announce Module Release

For new modules, write a blog post highlighting the usefulness (and uniqueness) of the module.

* Announce the module release on Twitter and Reddit.
* Link to the blog post if a new module.

## References

* 2017-01-21 [Powershell: Let’s build the CI/CD pipeline for a new module](5)
* 2017-05-12 [Powershell: Adventures in Plaster](1)
* 2017-05-14 [Powershell: GetPlastered, a Plaster template to create a Plaster template](2)
* 2017-05-27 [Powershell: Building a Module, one microstep at a time](4)
* 2017-10-14 [PowerShell: Automatic Module Semantic Versioning](3)
* 2018-09-20 [Powershell: Building Modules with the Azure DevOps Pipeline](6)

[1]:https://powershellexplained.com/2017-05-12-Powershell-Plaster-adventures-in/?utm_source=blog&utm_medium=blog&utm_content=tags
[2]:https://powershellexplained.com/2017-05-14-Powershell-Plaster-GetPlastered-template/?utm_source=blog&utm_medium=blog&utm_content=tags
[3]:https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/?utm_source=blog&utm_medium=blog&utm_content=tags
[4]:https://powershellexplained.com/2017-05-27-Powershell-module-building-basics/?utm_source=blog&utm_medium=blog&utm_content=tags
[5]:https://powershellexplained.com/2017-01-21-powershell-module-continious-delivery-pipeline/?utm_source=blog&utm_medium=blog&utm_content=tags
[6]:https://powershellexplained.com/2018-09-20-Powershell-Building-Modules-with-the-Azure-DevOps-Pipeline/?utm_source=blog&utm_medium=blog&utm_content=tags
