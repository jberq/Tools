function Get-GPUProcesses {
    [CmdletBinding()]
    param (
        # Path to nvidia-smi.exe
        [Parameter()]
        [System.IO.FileInfo]
        $NvidiaSmi_Path = "$Env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
    )

    if (!(Test-Path $NvidiaSmi_Path)) { # ensuring nvidia-smi.exe exists
        Write-Warning -Message ("Can't find {0}." -f $NvidiaSmi_Path.FullName)
        return
    }
    try { # ensuring nvidia-smi.exe is legit
        $sig = (Get-AuthenticodeSignature -FilePath $NvidiaSmi_Path -ErrorAction Stop)
        $org = $sig.SignerCertificate.Subject.Split(',')[1]
        if (!($org -eq " O=Microsoft Corporation" -or $org -eq " O=Nvidia Corporation")) { 
            Write-Warning -Message ("Invalid authenticode signature on {0}. `nSigned by:`t {1}" -f $NvidiaSmi_Path.Name,$org)
            return
        }
    }
    catch {
        Write-Warning -Message ("Invalid authenticode signature on {0}." -f $NvidiaSmi_Path.Name)
        return
    }

    # getting the process ids and returning system.diagnostics.process objects
    try {
        [xml]$xml = &$NvidiaSmi_Path -q -x
        $pids = $xml.nvidia_smi_log.gpu.processes.process_info.pid
        if ($pids) {
            Get-Process -Id $pids -ErrorAction Stop
        }
    }
    catch {
        Write-Warning "Couldn't get processes."
    }
    
}