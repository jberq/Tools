#http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/2003_w/misc/bmp_file_format/bmp_file_format.htm

# Header 	14 bytes 	  	Windows Structure: BITMAPFILEHEADER
#   	Signature 	2 bytes 	0000h 	'BM'
# FileSize 	4 bytes 	0002h 	File size in bytes
# reserved 	4 bytes 	0006h 	unused (=0)
# DataOffset 	4 bytes 	000Ah 	Offset from beginning of file to the beginning of the bitmap data

# ^ no longer needed after discovering System.Drawing.Image. Haven't tested whether reading the header is faster than using this class, but this sure is pretty damn simple (and fairly quick) as it is.

# The purpose of this is to save disk space and to quickly ensure that the file is a bitmap regardless of file extension.
# Works exceptionally well paired alongside ImageMagick and Oxipng. Just tell ImageMagick to convert to PNG with the least amount of compression possible, and then pass to oxipng.exe over Stdin. Set System.Diagnostics.ProcessPriorityClass to AboveNormal or higher for best results.
# Saved a couple hundred MB.
function Test-IsBitmap {
    param(
        [Parameter(Mandatory)]
        [string]
        $Filename
    )
    try {
        if (
            [System.Drawing.Image]::FromFile($Filename).RawFormat -eq [System.Drawing.Imaging.ImageFormat]::Bmp
        ) {
            $True
       } else {
        $False
       }
    } catch {
        $False
    }
}

Export-ModuleMember -Function Test-IsBitmap -Alias (New-Alias -Name "Test-IsBMP" -Value Test-IsBitmap -PassThru)