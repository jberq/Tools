function Test-7Zip {
    param(
        [parameter(Mandatory)]
        [System.IO.FileInfo]
        $Archive
    )
    enum ExitCode {
        NoError = 0
        NonFatalError = 1
        FatalError = 2
        CommandLineError = 7
        InsufficientMemory = 8
        UserStoppedProcess = 255
    }
    $pInfo = [Diagnostics.ProcessStartInfo]::new()
    $pInfo = @{
        FileName               = '7z.exe'
        Arguments              = "t -ba `"{0}`"" -f $Archive.FullName
        UseShellExecute        = $True
        RedirectStandardError  = $false
        RedirectStandardOutput = $false
        CreateNoWindow         = $true
        WindowStyle            = [System.Diagnostics.ProcessWindowStyle]::Hidden
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $pInfo
    try {
        [void] $process.Start()
    } catch [System.Management.Automation.MethodInvocationException] {
        try {
            Get-Command -CommandType Application -Name $pinfo.FileName -ErrorAction Stop | Out-Null
        } catch {
            $eMsg = "{0} not found. Is it in your PATH or working directory (`"{1}`")?`n`n" -f $pinfo.FileName,[System.IO.Directory]::GetCurrentDirectory()
            Write-Error -Message $eMsg -Category ObjectNotFound
            throw
        }
    }

    $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::AboveNormal
    $process.WaitForExit()
    if ([System.Enum]::GetValues([exitcode]) -contains $process.ExitCode) {
        $ExitCode = $process.ExitCode -as [Exitcode]
        switch ($ExitCode) {
            'NoError' {return $True}
            'FatalError' {return $False}
            default {
                Write-Error $ExitCode
            }
        }
    } else {
        Write-Error ("An unknown error has occured. (Exit code: {0})" -f $process.ExitCode) -TargetObject $process -Category InvalidResult
    }
}

Export-ModuleMember -Function Test-7Zip