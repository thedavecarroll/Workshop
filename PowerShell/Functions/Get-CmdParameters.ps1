function Get-CmdParameters {
    param(
        [Parameter(ParameterSetName='Command')]
        [string]$Command,
        [Parameter(ParameterSetName='Module')]
        [string]$Module
    )

    if ($PSBoundParameters.ParameterSetName -eq 'Command') {
        $CmdParameters = Get-Command -Name $Command
    } else {
        $CmdParameters = Get-Command -Module $Command
    }

    foreach ($Command in $CmdParameters) {
        $CommonParameters = $NonCommonParameters = $null
        $CmdHelp = Get-Help -Name $Command.Name)

        foreach ($Parameter in $Command.Parameters.Values) {
            if ($Parameter.Name -in [System.Management.Automation.PSCmdlet]::CommonParameters) {
                $CommonParameters = $Parameter
            } else {
                $NonCommonParameters = $Parameter
            }
        }
        [PSCustomObject]@{
            Name = $Command.Name
            Module = $Command.Module
            Version = $Command.Version
            Verb = $Command.Verb
            Noun = $Command.Noun
            DefaultParameterSet = $Command.DefaultParameterSet
            ParameterSets = $Command.ParameterSets
            CommonParameters = $CommonParameters
            NonCommonParameters = $NonCommonParameters
            ApiUri = $ApiUri
        }
    }
}