function Get-ChocoList {
	(choco list -l -r).foreach{
		$app = $_.split('|')
		[PSCustomObject]@{
			Name = $app[0]
			CurrentVersion = $app[1]
		}
	}
}