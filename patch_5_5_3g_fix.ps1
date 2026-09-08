param(
    [Parameter(Mandatory=$true)]
    [string]$EnginePath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $EnginePath)) {
    throw "Khong tim thay engine.py: $EnginePath"
}

$enc = New-Object System.Text.UTF8Encoding($false)
$text = [System.IO.File]::ReadAllText($EnginePath, [System.Text.Encoding]::UTF8)
$beginMarker = '# === 5.5.3f_FINAL_REPAIR_BEGIN ==='
$endMarker   = '# === 5.5.3f_FINAL_REPAIR_END ==='
$gMarker     = '# === 5.5.3g_HELPER_ORDER_FIX ==='
$hook        = 'return _antirepeat_last_resort_553f(locals(), language=language, duration=duration)'

if ($text.Contains($gMarker)) {
    Write-Host '[OK] 5.5.3g da duoc cai truoc do.' -ForegroundColor Green
    exit 0
}
if (-not $text.Contains($beginMarker) -or -not $text.Contains($endMarker)) {
    throw 'Khong tim thay helper 5.5.3f. Hay chay patch 5.5.3f truoc.'
}
if (-not $text.Contains($hook)) {
    throw 'Khong tim thay hook Final Repair 5.5.3f.'
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = "$EnginePath.bak_5.5.3f_$stamp"
Copy-Item -LiteralPath $EnginePath -Destination $backup -Force
Write-Host "[BACKUP] $backup"

$begin = $text.IndexOf($beginMarker, [System.StringComparison]::Ordinal)
$endStart = $text.IndexOf($endMarker, $begin, [System.StringComparison]::Ordinal)
if ($begin -lt 0 -or $endStart -lt 0) {
    throw 'Khong xac dinh duoc helper block 5.5.3f.'
}
$end = $endStart + $endMarker.Length
while ($end -lt $text.Length -and ($text[$end] -eq "`r" -or $text[$end] -eq "`n")) { $end++ }

$helper = $text.Substring($begin, $end - $begin).TrimEnd("`r", "`n")
$body = $text.Remove($begin, $end - $begin)

$guardDouble = 'if __name__ == "__main__":'
$guardSingle = "if __name__ == '__main__':"
$i1 = $body.IndexOf($guardDouble, [System.StringComparison]::Ordinal)
$i2 = $body.IndexOf($guardSingle, [System.StringComparison]::Ordinal)
$entry = -1
if ($i1 -ge 0 -and $i2 -ge 0) {
    $entry = [Math]::Min($i1, $i2)
}
elseif ($i1 -ge 0) {
    $entry = $i1
}
elseif ($i2 -ge 0) {
    $entry = $i2
}

if ($entry -lt 0) {
    $m = [System.Text.RegularExpressions.Regex]::Match($body, '(?m)^main\(\)\s*$')
    if ($m.Success) { $entry = $m.Index }
}
if ($entry -lt 0) {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw 'Khong tim thay entry point Python. engine.py da duoc khoi phuc.'
}

$prefix = $body.Substring(0, $entry).TrimEnd("`r", "`n")
$suffix = $body.Substring($entry).TrimStart("`r", "`n")
$newText = $prefix + "`r`n`r`n" + $gMarker + "`r`n" + $helper + "`r`n`r`n" + $suffix

$helperCount = [System.Text.RegularExpressions.Regex]::Matches($newText, 'def\s+_antirepeat_last_resort_553f\s*\(').Count
$hookCount = [System.Text.RegularExpressions.Regex]::Matches($newText, [System.Text.RegularExpressions.Regex]::Escape($hook)).Count
$helperPos = $newText.IndexOf('def _antirepeat_last_resort_553f(', [System.StringComparison]::Ordinal)
$mainPos = $newText.IndexOf($guardDouble, [System.StringComparison]::Ordinal)
if ($mainPos -lt 0) { $mainPos = $newText.IndexOf($guardSingle, [System.StringComparison]::Ordinal) }
if ($mainPos -lt 0) {
    $m2 = [System.Text.RegularExpressions.Regex]::Match($newText, '(?m)^main\(\)\s*$')
    if ($m2.Success) { $mainPos = $m2.Index }
}

if ($helperCount -ne 1 -or $hookCount -lt 1 -or $helperPos -lt 0 -or $mainPos -lt 0 -or $helperPos -gt $mainPos) {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw "Verification failed: helperCount=$helperCount hookCount=$hookCount helperPos=$helperPos mainPos=$mainPos"
}

[System.IO.File]::WriteAllText($EnginePath, $newText, $enc)

$verify = [System.IO.File]::ReadAllText($EnginePath, [System.Text.Encoding]::UTF8)
if (-not $verify.Contains($gMarker) -or -not $verify.Contains($hook)) {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw 'Verification after write failed. engine.py da duoc khoi phuc.'
}

$py = Get-Command py -ErrorAction SilentlyContinue
if ($null -ne $py) {
    & py -3 -m py_compile $EnginePath 2>$null
    if ($LASTEXITCODE -ne 0) {
        Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
        throw 'Python syntax check failed. engine.py da duoc khoi phuc.'
    }
    Write-Host '[OK] Python syntax check PASS.' -ForegroundColor Green
}

Write-Host '[OK] 5.5.3g da sua NameError bang cach dua helper len truoc main().' -ForegroundColor Green
Write-Host '[OK] Khong thay doi GPU, Visual Brain, StoryFlow, GoldStyle hay timeline.' -ForegroundColor Green
exit 0
