function Set-ProcessPriority {

    # I only realized afterwards that System.Diagnostics.Process objects have a property called BasePriorityClass along with Get/Set methods.
    # On the bright side, this function was made almost entirely using CIM/WMI, so in theory, it should be able to set process priorities remotely, which .NET alone can't natively do AFAIK. 

    # This one is pretty reliable I've found, especially for CPU-intensive tasks such as encoding video, e.g.:
    ## gps ffmpeg | Set-ProcessPriority AboveNormal
    # Your CPU temps will spike up dramatically, but so will the performance of ffmpeg.
    #
    # Works well with PsSuspend64.exe as well. One can dynamically suspend resource-intensive processes while tuning the priority of others.

    [CmdletBinding(PositionalBinding = $False)]
    #[CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, Position = 1)]
        [System.Diagnostics.Process[]]
        $Process,
        [Parameter(Mandatory = $true, Position = 0)]
        #[ValidateSet('Idle', 'BelowNormal', 'AboveNormal', 'High', 'Realtime')]
        [System.Diagnostics.ProcessPriorityClass]$Priority,
        [Parameter(Mandatory = $False)]
        [CimSession]
        $CimSession
    )
    begin {
        if ($CimSession -and !($CimSession.TestConnection())) {
            Write-Error ("Failed to connect to CimSession. ({0})`nComputerName:`t{1}`nProtocol:`t{2}" -f $CimSession.Name,$CimSession.ComputerName,$CimSession.Protocol) -Category ConnectionError -TargetObject $CimSession
            break
        } elseif (!$CimSession) {
            $cimSession = New-CimSession -Name cimSession -ComputerName 'localhost' -SessionOption (New-CimSessionOption -Protocol Dcom)
            if ($CimSession.TestConnection()) {
                Write-Verbose -Message ("CimSession opened. ({0}@{1})" -f $CimSession.Name,$CimSession.ComputerName)
            } else {
                Write-Verbose ("Failed to connect to CimSession. ({0})`nComputerName:`t{1}`nProtocol:`t{2}" -f $CimSession.Name,$CimSession.ComputerName,$CimSession.Protocol) -Category ConnectionError -TargetObject $CimSession
                Write-Error ("Failed to connect to CimSession. ({0})`nComputerName:`t{1}`nProtocol:`t{2}" -f $CimSession.Name,$CimSession.ComputerName,$CimSession.Protocol) -Category ConnectionError -TargetObject $CimSession
                break
            } 
            [bool]$removeCimSession = $True
        }
        $CimInstances = Get-CimInstance Win32_Process -CimSession $cimSession
        $PriorityMapping = @{
            Idle= 0x00000040;
            BelowNormal= 0x00004000
            Normal= 0x00000020;
            AboveNormal= 0x00008000;
            High = 0x00000080;
            Realtime = 0x00000100
        }
        $Priority = $PriorityMapping.Item($Priority.ToString())
        #$Process.ForEach{Add-Member -InputObject $_ -MemberType AliasProperty -Name "ProcessId" -Value "Id"}
        #$CimProcesses =Compare-Object -ReferenceObject $CimInstances -DifferenceObject $Process -Property ProcessId -PassThru -ExcludeDifferent
    }
    process {
         foreach ($p in $Process) {
            $p.Refresh()
            if ($p.PriorityClass -eq $Priority) {
                Write-Verbose -Message ('Priority of {0} ({1}) is already set to {2}. Skipping.' -f $p.MainModule.ModuleName,$p.Id,$Priority)
                continue
            }
            if (!$p.HasExited -and ($p.Responding)) {
                Add-Member -InputObject $p -MemberType AliasProperty -Name "ProcessId" -Value "Id" -PassThru -Force | Out-Null
                $CimProcess = Compare-Object -ReferenceObject $CimInstances -DifferenceObject $p -Property ProcessId -ExcludeDifferent -PassThru
                $CimProcess = [ciminstance]::new($CimProcess)
                try {
                    #$ProcessId = $p.Id
                    #$p2 = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = '$ProcessId'"
                    Invoke-CimMethod -CimSession $cimSession -InputObject $CimProcess -MethodName SetPriority -Arguments @{ Priority = $Priority } -OutVariable CimMethodReturnValue | Out-Null
                    if ($CimMethodReturnValue.ReturnValue -ne 0) {
                        $CimProcess | Add-Member -MemberType NoteProperty -Name CimMethodReturnValue -Value $CimMethodReturnValue.ReturnValue -PassThru
                        Write-Error -Message ("CimMethod returned {0} on {1} ({2})." -f $CimMethodReturnValue.ReturnValue,$CimProcess.Name,$CimProcess.ProcessId)
                    } else {
                        Write-Verbose -Message ('Set process priority to {0} for {1} ({2})' -f $Priority, $p.Name,$p.Id)
                    }
            } catch {
                $Error[0]
            }
                #Invoke-CimMethod -InputObject $CimProcess -MethodName GetOwner
                #return $CimProcess
            } else {
                $p.Refresh()
                if ($p.Name) {
                    $errorFriendlyName = "'{0}'({1})" -f $p.name,$p.Id
                } else {
                    $errorFriendlyName = "The process ({0})" -f $p.Id
                }
                if ($p.HasExited) {
                    Write-Error -Message ("{0} has already exited." -f $errorFriendlyName) -TargetObject $p
                } elseif (!$p.Responding){
                    Write-Error -Message ("{0} wasn't responding.`nSkipped." -f $errorFriendlyName) -TargetObject $p
                } else {
                    Write-Error -Message ("An unknown error has occured when setting priority to {0} on {1}.`n" -f $Priority,[cultureinfo]::CurrentCulture.TextInfo.ToLower($errorFriendlyName)) -TargetObject $p
                }
                }
            }
        }
        end {
            if ($removeCimSession) {
                if (Get-CimSession -InstanceId $cimSession.InstanceId){
                    $CimSession.Close()
                    $CimSession.Dispose()
                    Write-Verbose -Message ("CimSession closed and disposed. ({0}@{1})" -f $CimSession.Name,$CimSession.ComputerName)
                    #Remove-CimSession -CimSession $cimSession
                }
            }
            $CimInstances.Dispose()
        }
    
    } 


New-Alias spp Set-ProcessPriority -Description "Set the priority class of a [System.Diagnostics.Process] object!"
Export-ModuleMember -alias * -function *