#Requires -Modules BuildHelpers

function Add-ModuleUnitTests {
    [CmdLetBinding()]
    param(
        [ValidateScript({Test-Path -Path $_ -PathType 'Container'})]
        [string]$ProjectPath
    )

    Pop-Location

    $ProjectPath = Resolve-Path -Path $ProjectPath

    Set-Location -Path $ProjectPath
    Set-BuildEnvironment -Force

    $DefaultContent = @"

Describe -Name 'MODULECOMMAND' -Tag 'Unit','UNITTYPE' {

    InModuleScope 'MODULENAME' {

        It -Pending 'UnitTestPending' {

        }

    }

}

"@

    $BaseTestScriptPath = Join-Path -Path $ProjectPath -ChildPath 'Tests' | Join-Path -ChildPath 'Unit'

    $ModuleFunctions = @()
    $ModuleFunctions += Get-ChildItem -Path (Join-Path -Path $env:BHModulePath -ChildPath 'Public') -File -Recurse -Include *.ps1
    $ModuleFunctions += Get-ChildItem -Path (Join-Path -Path $env:BHModulePath -ChildPath 'Private') -File -Recurse -Include *.ps1

    foreach ($Function in $ModuleFunctions) {
        . $Function.FullName
        $FunctionName = $Function.BaseName
        $Command = Get-Command -Name $FunctionName
        if ($Command.CommandType -eq 'Function') {
            $FunctionPath = Split-Path -Path $Function.FullName -Parent
            if ($FunctionPath -match 'Public') {
                $UnitType = 'Public'
            } else {
                $UnitType = 'Private'
            }
            $TestScriptPath = Join-Path -Path $BaseTestScriptPath -ChildPath $UnitType | Join-Path -ChildPath "$FunctionName.Tests.ps1"
            try {
                $null = New-Item -Path $TestScriptPath -ItemType File -Force
                $null = Set-Content -Path $TestScriptPath -Value $DefaultContent.Replace('MODULECOMMAND',$FunctionName).Replace('MODULENAME',$env:BHProjectName).Replace('UNITTYPE',$UnitType) -Encoding UTF8
                Write-Verbose -Message "Created $TestScriptPath"
            }
            catch {
                Write-Warning -Message "Unable to create file $TestScriptPath"
                continue
            }
        }
    }

    Push-Location
}