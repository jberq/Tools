function Get-ChocoOutdated {
	(choco outdated -r).foreach{
		$app = $_.split('|')
		[PSCustomObject]@{
			Name = $app[0]
			CurrentVersion = $app[1]
			AvailableVersion = $app[2]
		}
	}
}