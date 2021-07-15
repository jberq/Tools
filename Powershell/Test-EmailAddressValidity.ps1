function Test-EmailAddressValidity {
    <#
    .SYNOPSIS
        Checks whether a string is a valid e-mail address.
    .EXAMPLE
        PS C:\> $Addresses = 'foo@bar.com', 'support@contoso.com', 'Invalid Address'
    
        PS C:\> foreach ($a in $Addresses) {
        >>      if (Test-EmailAddressValidity $a) {
        >>          [mailaddress]::new($a)
        >>      }
        >>      else {
        >>          Write-Warning "Couldn't validate $a."    
        >>      }
        
        WARNING: Couldn't validate Invalid Address
        DisplayName User    Host         Address
        ----------- ----    ----         -------
                    foo     bar.com      foo@bar.com
                    support contoso.com  support@contoso.com


            This validates addresses and casts to the [mailaddress] type.
    .NOTES
        Regex pattern found on https://docs.microsoft.com/en-us/dotnet/standard/base-types/how-to-verify-that-strings-are-in-valid-email-format
    #>
    param (
        # Parameter help description
        [Parameter(Mandatory, Position=0)]
        [string]
        $Address
    )
    $validatePattern = '^[^@\s]+@[^@\s]+\.[^@\s]+$'

    if ([regex]::IsMatch($Address, $validatePattern)) {
        $True
    }
    else {
        $False
    }
    
}