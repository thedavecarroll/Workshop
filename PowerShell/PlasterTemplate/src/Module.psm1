#region discover module name
$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase
#endregion discover module name

#region load module variables
Write-Verbose "Creating modules variables"
#New-Variable ModuleName_Variable1 -Value () -Option ReadOnly -Scope Global -Force
#endregion load module variables

#region Load Public Functions
Try {
    Get-ChildItem "$ScriptPath\Public" -Filter *.ps1 | ForEach-Object {
        $Function = $_.FullName.BaseName
        . $_.FullName
    }
} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}
#endregion Load Public Functions

#region Load Private Functions
Try {
    Get-ChildItem "$ScriptPath\Private" -Filter *.ps1 | ForEach-Object {
        $Function = $_.FullName.BaseName
        . $_.FullName
    }
} Catch {
    Write-Warning ("{0}: {1}" -f $Function,$_.Exception.Message)
    Continue
}
#endregion Load Private Functions

#region Format and Type Data
Try {
    Update-FormatData "$ScriptPath\TypeData\${PSModule.Name}.Format.ps1xml" -ErrorAction Stop
}
Catch {}
Try {
    Update-TypeData "$ScriptPath\TypeData\${PSModuleName}.Types.ps1xml" -ErrorAction Stop
}
Catch {}
#endregion Format and Type Data

#region Aliases
#New-Alias -Name short -Value Get-LongCommand -Force
#endregion Aliases

#region Handle Module Removal
$OnRemoveScript = {
    #Remove-Variable ModuleName_Variable1 -Scope Global -Force
}
$ExecutionContext.SessionState.Module.OnRemove += $OnRemoveScript
Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) -Action $OnRemoveScript
#endregion Handle Module Removal

#region export module members
$ExportModule = @{
    #Alias = @()
    #Function = @()
    #Variable = @()
}
Export-ModuleMember @ExportModule
#endregion export module members






# dot source public and private function definition files, export public functions
try {
    foreach ($Scope in 'Public','Private') {
        Get-ChildItem "$PSScriptRoot\$Scope" -Filter *.ps1 | ForEach-Object {
            . $_.FullName
            if ($Scope -eq 'Public') {
                # export only the functions using PowerShell standard verb-noun naming
                if ($_.BaseName -match '-') {
                    Export-ModuleMember -Function $_.BaseName -ErrorAction Stop
                }
            }
        }
    }
}
catch {
    Write-Error ("{0}: {1}" -f $_.BaseName,$_.Exception.Message)
    exit 1
}