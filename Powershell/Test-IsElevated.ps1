function Test-IsElevated
{
<#
    .Description
    Verifies that the shell is running as admin.
#>
    
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)

    if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        return $true
    }            
    else
    {
        return $false
    }       
}