#Requires -Modules BuildHelpers

function Add-ModuleUnitTests {
    [CmdLetBinding()]
    param(
        [ValidateScript({Test-Path -Path $_ -PathType 'Container'})]
        [string]$ProjectPath
    )

    Pop-Location

    Set-Location -Path $ProjectPath
    Set-BuildEnvironment -Force

    $DefaultContent = @"

Describe 'MODULECOMMAND' {

    InModuleScope 'MODULENAME' {


    }

}

"@

    $ModuleFunctions = Get-ChildItem -Path $env:BHModulePath -File -Recurse -Include *.ps1
    foreach ($Function in $ModuleFunctions) {
        . $Function.FullName
        $FunctionName = $Function.BaseName
        $Command = Get-Command -Name $FunctionName
        if ($Command.CommandType -eq 'Function') {
            $TestScriptPath = Join-Path -Path $ProjectPath -ChildPath 'Tests' | Join-Path -ChildPath 'Unit' | Join-Path -ChildPath "$FunctionName.Test.ps1"
            try {
                $null = New-Item -Path $TestScriptPath -ItemType File -Force
                $null = Set-Content -Path $TestScriptPath -Value $DefaultContent.Replace('MODULECOMMAND',$FunctionName).Replace('MODULENAME',$env:BHProjectName) -Encoding UTF8
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