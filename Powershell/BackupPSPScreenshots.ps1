# quick 'n dirty

param (
    [parameter(Mandatory = $False)]
    [switch]
    $RemoveAfterCompressing
)
import-module (join-path $PSScriptRoot BackUpPSPSaveGame.psm1)

$outBaseDir = Get-Item $HOME\Pictures\Screenshots\Games\PSP\OriginalHardware

$driveLetter = Get-PSPDriveLetter
$PSPDrive = Get-Item ("{0}:\" -f $driveLetter)

$PSPDir = $PSPDrive.EnumerateDirectories('PSP')
if ($PSPDir) {
    $ScreenshotDir = $PSPDir.EnumerateDirectories('Screenshot')
}
else {
    throw "no psp dir found"
}
if (!$ScreenshotDir) {
    throw "no screenshot dir found"
}

$dirs = $ScreenshotDir.EnumerateDirectories()

$bmp = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$dirs.foreach{
    $d = $_
    $dBmp = $d.EnumerateFiles("*.bmp")
    if ($dBmp) {
        $dBmp.foreach{
            $bmp.add($_)
        }
    }
}

for ($i = 0; $i -lt $bmp.Count; $i++) {
    $img = $bmp[$i]
    # creating filename
    $creationTimeStr = $img.CreationTime.ToString("MM-dd-yyyy_HH-mm-ss")
    $PngOutName = "{0}-{1}.PNG" -f $img.Directory.BaseName, $creationTimeStr
    $outDir = $outBaseDir.CreateSubdirectory($img.Directory.BaseName)
    $PngOutFullName = Join-Path $outDir $PngOutName


    if ([System.IO.File]::Exists($PngOutFullName)) {
        Write-Warning ("{0} already exists. Skipping." -f $PngOutFullName)
    }
    else {
        magick.exe $img -quality 0 PNG:- | oxipng.exe -o max --out $PngOutFullName - # bmp to png with optimal compression
        if ($LASTEXITCODE -eq 0) {
            if ($RemoveAfterCompressing) {
                Write-Host ("Deleting `"{0}`" . . ." -f $img.Name)
                $img.Delete()
            }
        }
    }
}