# ;)

$minutes = 15
$seconds = 5
$wshell = New-Object -ComObject Wscript.Shell
$timer = [System.Diagnostics.Stopwatch]::new()
[System.Console]::Title = ';)'

$fullSpan = [timespan]::new(0,$minutes,$seconds)
$timer.Start()
Clear-Host; while ($timer.Elapsed.Minutes -lt $minutes) {
    $timeLeft =  $fullSpan - $timer.Elapsed
    if ($timeLeft.Minutes -eq 1 -and $timeLeft.Seconds -eq 0) {
        # $wshell.AppActivate(';)')
        #$wshell.Popup("Operation Completed", 0, "Done", 0x1)
        $wshell.Popup((" {0:d2}:{1:d2} left! " -f $timeLeft.minutes, $timeLeft.seconds), 0, "Done", 0x1)
    }
    elseif ($timeLeft.Minutes -lt 1 -and $timeLeft.Seconds -lt 60) {
        [console]::SetCursorPosition(0, 0);
        [console]::Write((" Less than a minute left! "))
        [System.Console]::Title = (" {0:d2}:{1:d2}!" -f $timeLeft.minutes, $timeLeft.seconds)
        [Console]::Clear()
    }
    else {
        [console]::SetCursorPosition(0, 0);
        [console]::Write((" Time left: "))
        [System.Console]::Title = (" {0:d2}:{1:d2} " -f $timeLeft.minutes, $timeLeft.seconds)
    }

    [console]::SetCursorPosition(0, 1);
    [console]::Write((" {0:d2}:{1:d2} " -f $timeLeft.minutes, $timeLeft.seconds))
    [System.Threading.Thread]::Sleep(200)

        
}

