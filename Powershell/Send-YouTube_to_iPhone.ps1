# todo:
# ensure iphone is available with 'tailscale status'
# break up the pipe (i.e. the actual "|") and provide further checks (through System.Diagnostics.Process) before sending video over StdOut

param(
    [parameter(Mandatory)]
    [uri]
    $URL
)

$formatSelector = "res,vcodec:h264:h265,vext:mp4,acodec:mp4a:aac,aext:m4a:aac:mp3,fps,br" # this *should* always play on ios camera rol and Messages, and *should* select the highest resolution, framerate, and bitrate.

# getting file name
$fileName = yt-dlp -S $formatSelector --print filename -o '%(title)s [%(id)s].%(ext)s' $url

if ($fileName) { # getting video and sending to iphone
    yt-dlp -S $formatSelector $url -o - | tailscale file cp --name $fileName - iphone:
    if ($LASTEXITCODE -eq 0) {
        Write-Host -ForegroundColor Blue -Object ("Done!`nCheck phone.")
    } else {
        Write-Error -Message ("An error occured either while downloading or uploading the video. Work on the script to figure out which...")
    }
} else {
    write-error ("No filename could be found from {0}`nExit code: {1}" -f $url,$LASTEXITCODE)
}
