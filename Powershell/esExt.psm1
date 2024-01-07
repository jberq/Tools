function esExt {
    <#
    .SYNOPSIS
        Search Everything for a specific file extension.
    .DESCRIPTION
        Did something just create a file? Is your workstation a cluttered mess? Worry not! This function turns your Everything database into a powerful quasi-"Get-ChildItem"!
        Jeffery Snover described Powershell as "programming with hand-grenades instead of sniper rifles", and this function was made with that principle in mind.
    .NOTES
        Information or caveats about the function e.g. 'This function is not supported in Linux'
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        # Some executables write to a log file.
        # Peering into these logs can be a pain in the neck when working interactively at the shell.
        # This runs an executable and subsequently reads the log.
        &logEmittingExecutable.exe
        Get-Content (esExt '.log')

        # What about when you're unsure of whether an executable wrote to a file?
        # Well, you can be *pretty* sure if the latest file was written to within, say, the last 5 seconds:

        &CsvEmittingExecutable.exe
        $LatestCsv = esExt '.csv'
        $date = (Get-Date)
        $SinceWriteTime = ($date - $LatestLog.LastWriteTime)
        if ($SinceWriteTime.TotalSeconds -le 5) {
            Import-Csv $LatestCsv -OutVariable someData
        }

        Other:
        mpv (esExt 'flac','m4a' -n 5) --shuffle
    #>

    param (
        [Parameter(Mandatory = $True)]
        [Alias('Ext')]
        [string[]]
        $Extension,
        [Parameter(Mandatory = $False)]
        [Alias('n')]
        [ValidateRange(0,[int32]::maxvalue)]
        [int]
        $Number = 1,
        [Parameter(Mandatory = $False)]
        [ValidateSet("date-created",
        "date-modified",
        "date-accessed",
        "file-list",
        "file-name",
        "run-count",
        "date-recently-changed",
        "date-run",
        "size")]
        [string]
        $SortBy = "date-modified",
        [Parameter(Mandatory = $False)]
        [switch]
        $Ascending,
        [Parameter(Mandatory = $False)]
        [Alias("Priority")]
        [System.Diagnostics.ProcessPriorityClass]
        $PriorityClass = [System.Diagnostics.ProcessPriorityClass]::Normal
    )
    $exitCodes = @(
      "No known error, search successful.",
      "Failed to register window class.",
      "Failed to create listening window.",
      "Out of memory.",
      "Expected an additional command line option with the specified switch.",
      "Failed to create export output file.",
      "Unknown switch.",
      "Failed to send Everything IPC a query.",
      "Everything IPC window not found. Please make sure the Everything search client is running."
    )
    if ($Ascending) {
        $SortOpt = $SortBy.Insert($SortBy.Length,'-ascending')
    } else {
        $SortOpt = $SortBy.Insert($SortBy.Length,'-descending')
    }

    # Extension string formatting.
    if ($Extension.Count -gt 1) { # Allows for multiple extension searching.
        $ExtensionArgList = [System.Collections.Generic.List[string]]::new()
        foreach ($e in $Extension) {
            $trimmedE = $e.TrimStart('.')
            $ExtensionArgList.add(("ext:{0}" -f $trimmedE))
        }
        $ExtensionArg = $ExtensionArgList -join '|'
    } else {
        $trimmedE = $Extension.TrimStart('.')
        $ExtensionArg = "ext:{0}" -f $Extension.TrimStart('.')
    }
    Write-Verbose ("es search query:`t{0}" -f $ExtensionArg)
    $esArg = "{0} -n {1} -sort {2} -csv" -f $ExtensionArg,$Number,$SortOpt
    $pInfo = [Diagnostics.ProcessStartInfo]::new()
    $pInfo = @{
        FileName               = 'es.exe'
        Arguments              = $esArg
        UseShellExecute        = $false
        RedirectStandardError  = $true
        RedirectStandardOutput = $true
    }
  
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $pInfo
    try {
        [void] $process.Start()
    } catch [System.Management.Automation.MethodInvocationException] {
        $e = $error[0]
        $eException = $e.Exception
        $eMessage = $eException.Message.split(': ')[1].trim('"')
        
        $gcm = Get-Command -CommandType Application -Name $pInfo.FileName -ErrorAction SilentlyContinue # if an error was caught, let's investigate further with Get-Command to check whether es.exe is in the User's PATH or working directory.
        if (!$gcm) {
            # building a message to throw
            [uri]$helpLink = 'https://www.voidtools.com/downloads/#cli'
            $gcmMsg = "`n{0} not found in PATH.`n`n`tDownload link:`n`t{1}.`n`n" -f $pInfo.FileName,$helpLink.AbsoluteUri
            $gcmException = [System.Exception]::new($gcmMsg,$esException)
            $gcmException.HelpLink = 'https://www.voidtools.com/downloads/#cli'
            $gcmId = 'EsExeNotFound'
            $errorRecord = [System.Management.Automation.ErrorRecord]::new($gcmException,$gcmId,[System.Management.Automation.ErrorCategory]::NotInstalled,$pInfo.FileName)
            throw $errorRecord
        } else {
            throw ("An unknown fatal error occured while invoking {0}." -f $pInfo.FileName)
        }
    }
    $process.PriorityClass = $PriorityClass
    
    do {
        $line = $Process.StandardOutput.ReadLine()
        if ($line.StartsWith('"')) {
            [System.IO.FileInfo]::new($line.Trim().Trim('"'))
        }
        if ($process.HasExited) {
            $process.StandardOutput.ReadToEnd().foreach{
                $_.Trim().Trim('"') -as [System.IO.FileInfo[]]
            }
        }
    } until ($process.StandardOutput.EndOfStream -and ($process.HasExited))

    $process.WaitForExit()
    if ($process.HasExited) {
        Write-Verbose -Message ("es.exe: {1} ({0})" -f $process.ExitCode,$exitCodes[$process.ExitCode])
        if ((1..$exitCodes.Count) -contains $process.ExitCode) {
            Write-Host $stdErr.Result -ForegroundColor Red
            throw $exitCodes[$process.ExitCode]
          }
    }

  }
Export-ModuleMember -Function 'esExt'
# todo:
# learn c# and do ReadLineAsync properly . . .