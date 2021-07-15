function Get-ChocoOutdated {
    try {
        if (Get-Command -CommandType Application -Name choco -ErrorAction Stop) {
            (choco outdated -r).foreach{
                $app = $_.split('|')
                [PSCustomObject]@{
                    Name = $app[0]
                    CurrentVersion = $app[1]
                    AvailableVersion = $app[2]
                }
            }
        }
    }
    catch {
        Write-Error "choco not found in PATH."
    }
}