function Test-NvidiaSmi {
    try {
        if (Get-Command -CommandType Application -Name "nvidia-smi.exe" -ErrorAction Stop) {
            $True
        }
    } catch {
        Write-Warning ("nvidia-smi.exe needs to be in your PATH.`nIs it installed?")
        $False
    }
}

function Get-NvidiaGPU {
    try {
        (nvidia-smi.exe --list-gpus).foreach{
            $elements = $_.split(':').foreach{$_.trim()}
            [PSCustomObject]@{
                Index = $elements[0].TrimStart('GPU ') -as [byte]
                Name = $elements[1].split(' (')[0]
                UUID = $elements[2].TrimEnd(')').trimstart('GPU-') -as [guid]
            }   
        }
    } catch {
        if (Test-NvidiaSmi) {
            Write-Error ("An unknown error occured.")
        } else {
            Write-Error ("nvidia-smi.exe not found.")
        }
    }
}


function Get-TemperatureNvidiaGPU {
    param (
        [parameter(Mandatory = $False)]
        [byte[]]
        $Index,
        [parameter(Mandatory = $False)]
        [switch]
        $Detailed
    )
    # if (!$Index) {
    #     $Index = Get-GPU
    # }
    try {
        $GPU = Get-nvidiaGPU
    } catch {
        break
    }

    foreach ($card in $GPU) {
        $pInfo = [Diagnostics.ProcessStartInfo]::new()
    $pInfo = @{
        FileName               = 'nvidia-smi.exe'
        Arguments              = ("-i={0} -q -d=temperature" -f $card.Index)
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

    $tempCelcius = ($stdOut.Result).split("`n").foreach{$_.trim()}.where{$_.startswith('GPU Current Temp')}.split(':')[1].trimend('C').trim() -as [int16]
    if ($tempCelcius) {
        if ($Detailed) {
            $tempFarenheit = (($tempCelcius * 9) / 5) + 32
            Add-Member -InputObject $card -MemberType NoteProperty -Name "Celcius" -Value $tempCelcius
            Add-Member -InputObject $card -MemberType NoteProperty -Name "Farenheit" -Value $tempFarenheit
            $card
        } else {
            $tempCelcius
        }
    } else {
        Write-Error ("Couldn't get temperature for {0}." -f $card.Name)
    }
    #($stdOut.Result).foreach{$_.trim()}.where{$_.startswith('GPU Current Temp')}.split(':')[1].trimend('C').trim()
    #$stdErr.Result
    }
}

Export-ModuleMember -Function Get-TemperatureNvidiaGPU,Get-NvidiaGPU