function getGameIds {
    param(
        [Parameter(Mandatory = $False)]
        [string]
        $Path = 'E:\GAMES\Console-Images\psp\gameIDs-hashtable.json' 
    )
    Get-Content $Path | ConvertFrom-Json -AsHashtable
}
function Compress-PSPSaveGame {
    param (
        [Parameter(Mandatory = $True)]
        [System.IO.DirectoryInfo]
        $SaveDataDir,
        [Parameter(Mandatory = $False)]
        [System.IO.DirectoryInfo]
        $OutDirectory = 'E:\Backups\PSP-SaveData'
    )
    $gameIds = getGameIds
    $dirs = $SaveDataDir.EnumerateDirectories()
    $dirsToProcess = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
    $dirs.ForEach{
        $d = $_
        $gameId = $d.BaseName
        if ($gameIds.Keys -contains $gameId) {
            Add-Member -InputObject $d -MemberType NoteProperty -Name gameTitle -Value $gameIds.$gameid
            $dirsToProcess.add($d)
        }
        else {
            Write-Warning ("GameID not found. ({0})" -f $gameId)
        }
    }
    if ($dirsToProcess) {
        $maxGameStringLength = (($dirsToProcess.Gametitle | Sort-Object -Property Length)[-1] + " (ULUS10391)-->`t ')").Length # used for aligning console output
    }
    for ($i = 0; $i -lt $dirsToProcess.Count; $i++) {
        $d = $dirsToProcess[$i]
        $gameId = $d.BaseName
        $gameTitle = $gameIds.$gameId
        # the 7z archive name
        $archiveName = "PSP-SaveData-{0}-{1}.7z" -f $gameId, $gameTitle.replace(' ', '+')
        # 7z archive path
        $archiveFullName = Join-Path -Path $OutDirectory -ChildPath $archiveName


        $titleIdString = "{0} ({1})" -f $gameTitle, $gameId
        $seperator = " " * ($maxGameStringLength - $titleIdString.Length)
        Write-Host ("Updating backup...") -ForegroundColor DarkYellow
        Write-Host ("Game: {0}{1}-->`t{2}" -f $titleIdString, ($seperator), $archiveFullName)

        # creating temporar junction with which the archive will be appended
        $tempDirName = "{0}-{1}" -f $gameId, [datetime]::Now.ToString("yyyy-dd-M--HH-mm-ss")
        $tempDirPath = Join-Path -Path $env:TEMP -ChildPath $tempDirName
        $junction = New-Item -ItemType Junction -Path $tempDirPath -Value $d
    
        # 7z append junction
        $pInfo = [Diagnostics.ProcessStartInfo]::new()
        $pInfo = @{
            FileName               = '7z.exe'
            Arguments              = "a -r `"{0}`" `"{1}`" -m0=BCJ2 -m1=LZMA2:d=1024m -aoa" -f $archiveFullName, $junction
            UseShellExecute        = $false
            RedirectStandardError  = $true
            RedirectStandardOutput = $true
        }

        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $pInfo
        [void] $process.Start()
        $process.WaitForExit()

        $stdOut = $process.StandardOutput.ReadToEndAsync()
        $stdErr = $process.StandardError.ReadToEndAsync()
        #removing junction
        $junction.delete()
        
        if ($process.ExitCode -eq 0) {
            Write-Verbose $stdOut.Result
            $d
        }

        
        
        
        # # 7z update saves
        # write-host
        # $7zUpdate = [Diagnostics.ProcessStartInfo]::new()
        # $7zUpdate = @{
        #     FileName               = '7z.exe'
        #     Arguments              = "u -up0q0x0w1y1 `"{0}`" `"{1}`"" -f $archiveFullName,$d.FullName
        #     UseShellExecute        = $false
        #     RedirectStandardError  = $true
        #     RedirectStandardOutput = $true
        # }

        # $process = [Diagnostics.Process]::new()
        # $process.StartInfo = $7zUpdate
        # [void] $process.Start()
        # $process.WaitForExit()

        # $stdOut = $process.StandardOutput.ReadToEndAsync()
        # $stdErr = $process.StandardError.ReadToEndAsync()

        # # $stdOut.Result
        # $stdErr.Result
    }
}

function Get-PSPDriveLetter {
    $PSPDrive = Get-CimInstance -Namespace ROOT/Microsoft/Windows/Storage -Query 'Select FileSystemLabel,DriveLetter FROM MSFT_Volume WHERE FileSystemLabel LIKE "PSP%"'
        if ($PSPDrive) {
            if ($PSPDrive.Count -gt 1) {
                $driveLetterInquiryString = $PSPDrive.foreach{"Drive Letter {0}:`t{1}" -f $_.DriveLetter,$_.FileSystemLabel} -join "`n"
                Write-Warning ("More than one PSP found.`n{0}" -f $driveLetterInquiryString)
                do {
                    $PSPDriveLetter = (Read-Host -Prompt ("Please enter drive letter ({0})" -f ($PSPDrive.DriveLetter -join ', ')))
                } until ($PSPDrive.DriveLetter -contains $PSPDriveLetter)
            } else {
                return $PSPDrive.DriveLetter
            }           
        }
        else {
            Write-Error -Message "PSP not connected."
            throw
        }
}
function Update-PSPSaveData {
    param(
        [Parameter(Mandatory = $False)]
        [System.IO.DirectoryInfo]
        $PPSSPP_SaveDataDir = 'C:\Users\jberq\Documents\PPSSPP\PSP\SAVEDATA\',
        [Parameter(Mandatory = $False)]
        [char]
        $PSPDriveLetter,
        [Parameter(Mandatory)]
        [ValidateSet("ToPSP","ToComputer")]
        $Direction
    )
    if (!$PSPDriveLetter) {
        $PSPDrive = Get-CimInstance -Namespace ROOT/Microsoft/Windows/Storage -Query 'Select FileSystemLabel,DriveLetter FROM MSFT_Volume WHERE FileSystemLabel LIKE "PSP%"'
        if ($PSPDrive) {
            if ($PSPDrive.Count -gt 1) {
                $driveLetterInquiryString = $PSPDrive.foreach{"Drive Letter {0}:`t{1}" -f $_.DriveLetter,$_.FileSystemLabel} -join "`n"
                Write-Warning ("More than one PSP found.`n{0}" -f $driveLetterInquiryString)
                do {
                    $PSPDriveLetter = (Read-Host -Prompt ("Please enter drive letter ({0})" -f ($PSPDrive.DriveLetter -join ', ')))
                } until ($PSPDrive.DriveLetter -contains $PSPDriveLetter)
            } else {
                $PSPDriveLetter = $PSPDrive.DriveLetter
            }
            
        }
        else {
            Write-Error -Message "PSP not connected."
            throw
        }
    }
    [System.IO.DirectoryInfo]$PSPSaveDataDir = Join-Path ("{0}:\" -f $PSPDriveLetter) -ChildPath 'PSP\SAVEDATA'
    if ($PSPSaveDataDir.Exists) {
        if ($Direction -eq 'ToPSP') {
            $To = $PSPSaveDataDir
            $From = $PPSSPP_SaveDataDir
        } else {
            $To = $PPSSPP_SaveDataDir
            $From = $PSPSaveDataDir
        }
        try {
            $ToTransfer = Compress-PSPSaveGame -SaveDataDir $To -ErrorAction Stop
            
        } catch {
            throw 'error backing up saves.'
        }
        
        if ($ToTransfer) {
            write-host ("Copying {0} to {1}" -f $From,$To) 
            #robocopy arg list minus the initial source/destination
            $roboArgs = [System.Collections.Generic.List[string]]::new(("/E /COPYALL /DCOPY:DAT /IT /IM".split(' ')))
            #$excludeDirs = (Compare-Object $From.EnumerateDirectories().FullName $ToTransfer -IncludeEqual).where{$_.SideIndicator -ne '=='} #potential directories to exclude i.e. when a gameid isn't found
            if ($excludeDirs) {
                $ex = for ($i = 0; $i -lt $excludeDirs.Count; $i++) {
                    "/XD `"{0}`"" -f $excludeDirs[$i]
                }
                $roboArgs.add(($ex -join ' '))
            }
            # $ToTransfer | ForEach-Object {
            #     $d = $_
            #     write-host ("Copying:`t{0}" -f $d.Fullname)
            #     Copy-Item $d -Destination $To -Force
            # }
            $robocopy_pInfo = [Diagnostics.ProcessStartInfo]::new()
            $robocopy_pInfo.FileName = 'Robocopy.exe'
            $robocopy_pInfo.Arguments = "`"{0} `" `"{1} `" {2}" -f $from.FullName,$to.Fullname,($roboArgs -join ' ')
            Write-Verbose -Message ("robocopy args:`t{0}" -f $robocopy_pInfo.Arguments)
            $robocopy_pInfo.UseShellExecute        = $false
            $robocopy_pInfo.RedirectStandardError  = $true
            $robocopy_pInfo.RedirectStandardOutput = $False
            $robocopy_pInfo.CreateNoWindow = $True
            $robocopyProcess = [System.Diagnostics.Process]::new()
            $robocopyProcess.StartInfo = $robocopy_pInfo

            ## [void]$robocopyProcess.Start()
            ## $robocopyProcess.WaitForExit()
            ## $stdOut = $roboCopyprocess.StandardOutput.ReadToEndAsync()
            ## $stdErr = $robocopyProcess.StandardError.ReadToEndAsync()
            Start-Process robocopy -ArgumentList $robocopy_pInfo.Arguments -NoNewWindow
            if ($stdOut.Result){
                $stdOut.Result
            }
            if ($stdErr.Result) {
                $stdErr.Result
            }
            }
        }
        

    }

Export-ModuleMember -Function "Get-PSPDriveLetter","Update-PSPSaveData"