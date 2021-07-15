function Get-ChocoList {
    try {
        if (Get-Command -Name 'choco' -CommandType Application -ErrorAction Stop) {
            (choco list -lo -r).foreach{
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