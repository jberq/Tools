function Convert-VideoToGif {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory = $False)]
        [System.IO.FileInfo]
        $OutFile,

        [Parameter(Mandatory = $False)]
        [int]
        $Width,

        [Parameter(Mandatory = $False)]
        [ValidateRange(1, 100)]
        [int]
        $Quality,
        [Parameter(Mandatory = $False)]
        [float]
        $FPS
    )

    if (!(Test-Path -Path $File)) {
        throw "$File doesn't exist."
        return
    }
    $Requirements = @(
        "ffmpeg",
        "gifski",
        "ffprobe"
    )
    ForEach-Object -InputObject $Requirements {
        try {
            $null = Get-Command -Name $_ -CommandType Application -ErrorAction Stop
        }
        catch {
            Write-Error "$_ must be in PATH."
            return
        }
    }
    #Checking framerate
    $frameRate = ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=avg_frame_rate -i $File 2>$null
    if ($frameRate) {
        $frameRate = Invoke-Expression $frameRate
    }
    else {
        throw "ffprobe failed to check the framerate of $File."
        return
    }
    #extracting frames
    ForEach-Object -InputObject (New-TemporaryFile) {
        Remove-Item $_; 
        $FrameDirectory = New-Item $_ -ItemType Directory #temp directory
    }
    ffmpeg -i $File -vf fps=$FrameRate ($FrameDirectory.Fullname + "\frame%03d.png")
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed to extract frames from $File to $FrameDirectory."
        return
    }
    #Creating gif
    $ExtraArgs = @()
    if ($Width) {
        $ExtraArgs += "--width=$Width"
    }
    if ($Quality) {
        $ExtraArgs += "--quality=$Quality"
    }
    if ($FPS) {
        $ExtraArgs += "--fps=$FPS"
    }
    elseif (!$FPS) {
        $ExtraArgs += "--fps=$framerate"
    }
    if ($ExtraArgs) {
        [string] $ExtraArgs -join " "
    }
    if ($OutFile -and $OutFile.Exists) {
        throw "$OutFile already exists."
        return
    }
    elseif ($OutFile -and $OutFile.Extension -ne '.gif') {
        $OutFile = $OutFile.DirectoryName + '\' + $OutFile.Basename + '.gif'
        [bool] $ExtensionChanged = 1
    }
    elseif (! $OutFile) {
        $OutFile = $File.DirectoryName + '\' + $File.BaseName + '.gif'
    }
    
    [string] $frames = $FrameDirectory.Fullname + "\*.png"

    gifski.exe $ExtraArgs --output $OutFile $frames
    if ($LASTEXITCODE -ne 0) {
        throw "gifski failed to create gif from $File to $OutFile."
    }
    
    #cleanup
    try {
        Remove-Item -Path $FrameDirectory -Force -Recurse -ErrorAction Stop
    }
    catch {
        Write-Warning -Message "Failed to delete $FrameDirectory"
    }
}