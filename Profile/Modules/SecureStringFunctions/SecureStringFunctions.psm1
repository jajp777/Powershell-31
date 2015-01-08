#requires -Version 2.0

if ($PSVersionTable.PSVersion.Major -ge 3)
{
    Import-Module Microsoft.PowerShell.Security -Global
}

$script:validEntropyTypes = @(
    [System.ValueType]
    [string]
    [System.Security.SecureString]
    [System.Text.StringBuilder]
)

function ConvertTo-SecureString
{
    <#
    
    .ForwardHelpTargetName ConvertTo-SecureString
    .ForwardHelpCategory Cmdlet
    
    #>

    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]
        ${String},
    
        [Parameter(ParameterSetName='PlainText', Position=1)]
        [switch]
        ${AsPlainText},
    
        [Parameter(ParameterSetName='PlainText', Position=2)]
        [Parameter(ParameterSetName = 'WithEntropy')]
        [switch]
        ${Force},
    
        [Parameter(ParameterSetName='Secure', Position=1)]
        [System.Security.SecureString]
        ${SecureKey},
    
        [Parameter(ParameterSetName='Open')]
        [byte[]]
        ${Key},

        [Parameter(ParameterSetName = 'WithEntropy')]
        [Object]
        $Entropy
    )
    
    begin
    {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($PSCmdlet.ParameterSetName -eq 'WithEntropy')
        {
            try
            {
                $entropyBytes = Get-EntropyBytes -Entropy $Entropy -Force:$Force
            }
            catch
            {
                throw
            }
        }
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'WithEntropy'
            {
                Add-Type -AssemblyName 'System.Security' -ErrorAction Stop

                try
                {
                    $encryptedBytes = Get-ByteArrayFromString -String $String
                    $plainTextBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, $entropyBytes, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
                    $plainTextChars = [System.Text.Encoding]::Unicode.GetChars($plainTextBytes)

                    $secureString = New-Object System.Security.SecureString

                    foreach ($char in $plainTextChars)
                    {
                        $secureString.AppendChar($char)
                    }

                    $secureString.MakeReadOnly()

                    return $secureString
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
                finally
                {
                    if ($null -ne $plainTextChars) { [array]::Clear($plainTextChars, 0, $plainTextChars.Count) }
                    if ($null -ne $plainTextBytes) { [array]::Clear($plainTextBytes, 0, $plainTextBytes.Count) }
                    if ($null -ne $entropyBytes)   { [array]::Clear($entropyBytes, 0, $entropyBytes.Count) }
                }
                
                break
            }

            default
            {
                try
                {
                    $cmd = Get-Command -Name ConvertTo-SecureString -CommandType Cmdlet
                    return & $cmd @PSBoundParameters
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
                
                break
            }
        }

    } # process
    
} # function ConvertTo-SecureString

function ConvertFrom-SecureString
{
    <#
    
    .ForwardHelpTargetName ConvertFrom-SecureString
    .ForwardHelpCategory Cmdlet
    
    #>

    [CmdletBinding(DefaultParameterSetName='Secure')]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateScript({ $_.Length -gt 0 })]
        [System.Security.SecureString]
        ${SecureString},
    
        [Parameter(ParameterSetName='Secure', Position=1)]
        [System.Security.SecureString]
        ${SecureKey},
    
        [Parameter(ParameterSetName='Open')]
        [byte[]]
        ${Key},

        [Parameter(ParameterSetName = 'WithEntropy')]
        [Object]
        $Entropy,

        [Parameter(ParameterSetName = 'PlainText')]
        [switch]
        $AsPlainText,

        [Parameter(ParameterSetName = 'PlainText')]
        [Parameter(ParameterSetName = 'WithEntropy')]
        [switch]
        $Force
    )
    
    begin
    {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

        if ($PSCmdlet.ParameterSetName -eq 'WithEntropy')
        {
            Add-Type -AssemblyName 'System.Security'

            try
            {
                $entropyBytes = Get-EntropyBytes -Entropy $Entropy -Force:$Force
            }
            catch
            {
                throw
            }
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'PlainText' -and -not $Force)
        {
            throw 'The system cannot protect plain text output.  To suppress this warning and convert the SecureString to plain text, reissue the command specifying the Force parameter.'
        }
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'PlainText'
            {
                try
                {
                    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($secureString)
                    return [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
                finally
                {
                    if ($null -ne $ptr) { [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr) }
                }
                
                break
            }

            'WithEntropy'
            {
                try
                {
                    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($secureString)
                    $chars = New-Object Char[]($secureString.Length)
                    [System.Runtime.InteropServices.Marshal]::Copy($ptr, $chars, 0, $secureString.Length)
                    $bytes = [System.Text.Encoding]::Unicode.GetBytes($chars)
                    $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect($bytes, $entropyBytes, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)

                    return Get-StringFromByteArray -ByteArray $encryptedBytes
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
                finally
                {
                    if ($null -ne $ptr)          { [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr) }
                    if ($null -ne $chars)        { [array]::Clear($chars, 0, $chars.Count) }
                    if ($null -ne $bytes)        { [array]::Clear($bytes, 0, $bytes.Count) }
                    if ($null -ne $entropyBytes) { [array]::Clear($entropyBytes, 0, $entropyBytes.Count) }
                }
                
                break
            }

            default
            {
                try
                {
                    $cmd = Get-Command -Name ConvertFrom-SecureString -CommandType Cmdlet
                    return & $cmd @PSBoundParameters
                }
                catch
                {
                    Write-Error -ErrorRecord $_
                }
                
                break
            }
        }

    } # process

} # function ConvertTo-SecureString

function Get-ByteArrayFromString
{
    # Converts a string containing an even number of hexadecimal characters into a byte array.

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            # Could use ValidatePattern for this, but ValidateScript allows for a more user-friendly error message.
            if ($_ -match '[^0-9A-F]')
            {
                throw 'String must only contain hexadecimal characters (0-9 and A-F).'
            }

            if ($_.Length % 2 -ne 0)
            {
                throw 'String must contain an even number of characters'
            }

            return $true
        })]
        [string]
        $String
    )

    $length = $String.Length / 2
    $bytes = New-Object byte[]($length)

    for ($i = 0; $i -lt $length; $i++)
    {
        $bytes[$i] = [byte]::Parse($String.Substring($i * 2, 2), [Globalization.NumberStyles]::AllowHexSpecifier, [Globalization.CultureInfo]::InvariantCulture)
    }

    return ,$bytes
}

function Get-EntropyBytes
{
    [CmdletBinding()]
    param (
        $Entropy,

        [switch]
        $Force
    )

    if ($null -eq $Entropy)
    {
        return $null
    }
    elseif (-not $Force -and -not (Test-EntropyType -Object $Entropy))
    {
        throw @'
Entropy object's type should be a value type, string, StringBuilder, SecureString, or an array containing only value types or strings.
Use of other object types might result in a different binary representation of the object between script executions.  To suppress this message and use any type of entropy object, use the -Force switch.
'@
    }

    if ($Entropy -is [byte[]])
    {
        # Clone the object because the caller may be zeroing out the byte array when they're done, due
        # to it potentially containing plain text data from a SecureString.

        return $Entropy.Clone()
    }
    elseif ($Entropy -is [string])
    {
        return [System.Text.Encoding]::Unicode.GetBytes($Entropy)
    }
    elseif ($Entropy -is [System.Text.StringBuilder])
    {
        return [System.Text.Encoding]::Unicode.GetBytes($Entropy.ToString())
    }
    elseif ($Entropy -is [System.Security.SecureString])
    {
        try
        {
            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($Entropy)
            $chars = New-Object Char[]($Entropy.Length)

            [System.Runtime.InteropServices.Marshal]::Copy($ptr, $chars, $Entropy.Length)

            return [System.Text.Encoding]::Unicode.GetBytes($chars)
        }
        catch
        {
            throw
        }
        finally
        {
            if ($null -ne $ptr) { [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($ptr) }
            if ($null -ne $chars) { [Array]::Clear($chars) }
        }
    }
    else
    {
        try
        {
            $ms = New-Object System.IO.MemoryStream
            $bf = New-Object System.Runtime.Serialization.Formatters.Binary.BinaryFormatter

            $bf.Serialize($ms, $Entropy)
            
            return ,$ms.ToArray()
        }
        catch
        {
            throw
        }
        finally
        {
            if ($null -ne $ms) { $ms.Dispose() }
        }
    }
}

function Get-StringFromByteArray
{
    # Converts byte array into a string of hexadecimal characters in the same order as the byte array

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]
        $ByteArray
    )

    $sb = New-Object System.Text.StringBuilder

    for ($i = 0; $i -lt $ByteArray.Length; $i++)
    {
        $null = $sb.Append($ByteArray[$i].ToString('x2', [Globalization.CultureInfo]::InvariantCulture))
    }

    return $sb.ToString()
}

function Test-EntropyType
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $Object
    )

    if ($Object -is [array])
    {
        foreach ($obj in $Object)
        {
            if ($obj -isnot [System.ValueType] -and $obj -isnot [string])
            {
                return $false
            }
        }

        return $true
    }
    else
    {
        foreach ($type in $script:validEntropyTypes)
        {
            if ($Object -is $type)
            {
                return $true
            }
        }

        return $false
    }
}

function Get-CallerPreference
{
    <#
    .Synopsis
       Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
       Script module functions do not automatically inherit their caller's variables, but they can be
       obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
       for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
       and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
    .PARAMETER Cmdlet
       The $PSCmdlet object from a script module Advanced Function.
    .PARAMETER SessionState
       The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
       Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
       script module.
    .PARAMETER Name
       Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
       Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
       This parameter may also specify names of variables that are not in the about_Preference_Variables
       help file, and the function will retrieve and set those as well.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Imports the default PowerShell preference variables from the caller into the local scope.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

       Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
    .EXAMPLE
       'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Same as Example 2, but sends variable names to the Name parameter via pipeline input.
    .INPUTS
       String
    .OUTPUTS
       None.  This function does not produce pipeline output.
    .LINK
       about_Preference_Variables
    #>

    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $SessionState,

        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]
        $Name
    )

    begin
    {
        $filterHash = @{}
    }
    
    process
    {
        if ($null -ne $Name)
        {
            foreach ($string in $Name)
            {
                $filterHash[$string] = $true
            }
        }
    }

    end
    {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null

            'ErrorActionPreference' = 'ErrorAction'
            'DebugPreference' = 'Debug'
            'ConfirmPreference' = 'Confirm'
            'WhatIfPreference' = 'WhatIf'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
        }


        foreach ($entry in $vars.GetEnumerator())
        {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name)))
            {
                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)
                
                if ($null -ne $variable)
                {
                    if ($SessionState -eq $ExecutionContext.SessionState)
                    {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force
                    }
                    else
                    {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered')
        {
            foreach ($varName in $filterHash.Keys)
            {
                if (-not $vars.ContainsKey($varName))
                {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)
                
                    if ($null -ne $variable)
                    {
                        if ($SessionState -eq $ExecutionContext.SessionState)
                        {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force
                        }
                        else
                        {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }

    } # end

} # function Get-CallerPreference

Export-ModuleMember -Function 'ConvertTo-SecureString', 'ConvertFrom-SecureString', 'Get-CallerPreference'
