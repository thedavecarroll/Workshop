function ConvertTo-Number {
    [Alias('ctn')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,ParameterSetName='Manual')]
        [object[]]$InputObject,
        [Parameter(Mandatory,ParameterSetName='Clipboard')]
        [Alias('fc')]
        [switch]$FromClipboard,
        [ValidateSet('int32','int64','short','long','single','double','decimal','float')]
        [Alias('type','nt')]
        [string]$NumberType = 'decimal'
    )
    begin {
        if ($PSCmdlet.ParamaterSetName -eq 'Manual') {
            $FinalString = [System.Text.StringBuilder]::new()
        }
    }
    process {
        if ($PSCmdlet.ParamaterSetName -eq 'Manual') {
            foreach ($object in $InputObject) { $null = $FinalString.Append($object) }
        }
    }
    end {
        try {
            if ($PSCmdlet.ParamaterSetName -eq 'Manual') {
                $NumberString = $FinalString. ToString()
            } else {
                $NumberString = Get-Clipboard -Raw
            }
            'numberstring {0}' -f $NumberString| Write-Verbose
            switch ($NumberType) {
                'int32'   { [int32]::Parse($NumberString,'Any') }
                'int64'   { [int64]::Parse($NumberString,'Any') }
                'short'   { [short]::Parse($NumberString,'Any') }
                'long'    { [long]::Parse($NumberString,'Any') }
                'decimal' { [decimal]::Parse($NumberString,'Any') }
                'single'  { [single]::Parse($NumberString,'Any') }
                'double'  { [double]::Parse($NumberString,'Any') }
                'float'   { [float]::Parse($NumberString,'Any') }
            }
        }
        catch {
            if ($_.Exception.InnerException.Message) {
                $_.Exception.InnerException.Message | Write-Warning
            } else {
                $false
            }
        }
    }
}