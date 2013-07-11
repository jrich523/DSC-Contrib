function New-MofFile
{
    param (
        $Name,
        $ModuleName,
        $Version = '1.0.0'
    )

    if ([string]::IsNullOrEmpty($ModuleName))
    {
        $ModuleName = $Name
    }

    $Template = @"
[version("$Version"), FriendlyName("$ModuleName")]
class $Name : MSFT_BaseResourceConfiguration
{

"@
    $CommonParameters = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 
                        'WarningVariable', 'ErrorVariable', 'OutVariable', 'OutBuffer'
    $Command = get-command -Name Set-TargetResource -Module $ModuleName

    foreach ($key in $Command.Parameters.Keys)
    {
        
        if ($CommonParameters -notcontains $key)
        {
            $CurrentParameter = $Command.Parameters[$key]
            $IsKey = $false
            $PropertyString = "`t"
            
            $ParameterAttribute = $CurrentParameter.Attributes | 
                Where-Object {$_ -is [System.Management.Automation.ParameterAttribute]}
            $ValidateSetAttribute = $CurrentParameter.Attributes | 
                Where-Object {$_ -is [System.Management.Automation.ValidateSetAttribute]}

            if ($ParameterAttribute.Mandatory)
            {
                $PropertyString += '[Key'
                $IsKey = $true
            }
            else
            {
                $PropertyString += '[write'
                if ($ValidateSetAttribute -ne $null)
                {
                    $OFS = '", "'
                    $PropertyString += ',ValueMap{"' + "$($ValidateSetAttribute.ValidValues)"
                    $PropertyString += '"},Values{"' + "$($ValidateSetAttribute.ValidValues)"
                    $PropertyString += '"}'
                }
            }
                        
            
            switch ($CurrentParameter.ParameterType)
            {
                {$_ -eq [System.String]} { $PropertyString += '] string ' + "$key;`n" }
                {$_ -eq [System.Management.Automation.SwitchParameter]} { $PropertyString += '] boolean ' + "$key;`n"}
                {$_ -eq [System.Management.Automation.PSCredential]} { $PropertyString += ',EmbeddedInstance("MSFT_Credential")] string ' + "$key;`n"}
                {$_ -eq [System.String[]]} { $PropertyString += '] string ' + "$key[];`n" }
                default { Write-Warning "Don't know what to do with $_";}
            }
            
            $Template += $PropertyString
        }
        
    }
    $Template += @'
};
'@
    $module = Get-Module $ModuleName
    $Template | 
        Out-File -Encoding ascii -FilePath (join-path $Module.ModuleBase "$ModuleName.schema.mof")

}