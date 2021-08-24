function Get-GreatestCommonDivisor ([int]$a, [int]$b) {
    while ($a -ne 0 -and $b -ne 0) {
        if ($a -gt $b) {
            $a = $a % $b
        } else {
            $b = $b % $a
        }
    }
    if ($a) {
        $a
    } else {
        $b
    }
}
