function Get-ChocoList {
    try {
        if (Get-Command -CommandType Application -Name choco) {
            (choco list -l -r).foreach{
                $app = $_.split('|')
                [PSCustomObject]@{
                    Name           = $app[0]
                    CurrentVersion = $app[1]
                }
            }
        }
    }
    catch {
        Write-Error "choco not found in PATH."
    }
}