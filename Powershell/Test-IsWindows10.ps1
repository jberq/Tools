function Test-IsWindows10
{
<#
    .Description
    Verifies whether the machine is running on Windows 10 or greater.
#>
    if ([System.Environment]::OSVersion.Version.Major -ge "10" -and [System.Environment]::OSVersion.Version.Build -ge "16299")  
    {
        return $true
    }
    else
    {
        return $false
    }
}
