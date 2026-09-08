param(
    [Parameter(Mandatory=$true)]
    [string]$EnginePath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $EnginePath)) {
    throw "Khong tim thay engine.py: $EnginePath"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$text = [System.IO.File]::ReadAllText($EnginePath, [System.Text.Encoding]::UTF8)
$beginMarker = '# === 5.5.3f_FINAL_REPAIR_BEGIN ==='
$endMarker = '# === 5.5.3f_FINAL_REPAIR_END ==='
$gMarker = '# === 5.5.3g_HELPER_ORDER_FIX ==='
$hook = 'return _antirepeat_last_resort_553f(locals(), language=language, duration=duration)'

if ($text.Contains($gMarker)) {
    Write-Host '[OK] 5.5.3g da duoc cai truoc do.' -ForegroundColor Green
    exit 0
}

if (-not $text.Contains($beginMarker) -or -not $text.Contains($endMarker)) {
    throw 'Khong tim thay helper 5.5.3f. INSTALL_PATCH.bat phai chay patch 5.5.3f truoc.'
}

if (-not $text.Contains($hook)) {
    throw 'Khong tim thay Final Gate hook cua 5.5.3f.'
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
while ($end -lt $text.Length -and ($text[$end] -eq "`r" -or $text[$end] -eq "`n")) {
    $end++
}

$helperBlock = $text.Substring($begin, $end - $begin).TrimEnd("`r", "`n")
$withoutHelper = $text.Remove($begin, $end - $begin)

# Helper cua 5.5.3f truoc day bi append SAU main(), nen khi main dang chay
# Python chua kip define function va phat sinh NameError. 5.5.3g di chuyen
# helper len TRUOC entry point, khong thay doi Visual/Story/GoldStyle/Timing.
$guardDouble = 'if __name__ == "__main__":'
$guardSingle = "if __name__ == '__main__':"
$idxDouble = $withoutHelper.IndexOf($guardDouble, [System.StringComparison]::Ordinal)
$idxSingle = $withoutHelper.IndexOf($guardSingle, [System.StringComparison]::Ordinal)

$entryIndex = -1
if ($idxDouble -ge 0 -and $idxSingle -ge 0) {
    $entryIndex = [Math]::Min($idxDouble, $idxSingle)
}
elif ($idxDouble -ge 0) {
    $entryIndex = $idxDouble
}
elif ($idxSingle -ge 0) {
    $entryIndex = $idxSingle
}

if ($entryIndex -lt 0) {
    $m = [System.Text.RegularExpressions.Regex]::Match($withoutHelper, '(?m)^main\(\)\s*$')
    if ($m.Success) {
        $entryIndex = $m.Index
    }
}

if ($entryIndex -lt 0) {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw 'Khong tim thay Python entry point (if __name__ / main()). engine.py da duoc khoi phuc.'
}

$prefix = $withoutHelper.Substring(0, $entryIndex).TrimEnd("`r", "`n")
$suffix = $withoutHelper.Substring($entryIndex).TrimStart("`r", "`n")
$newText = $prefix + "`r`n`r`n" + $gMarker + "`r`n" + $helperBlock + "`r`n`r`n" + $suffix

# Static verification before write.
$helperCount = [System.Text.RegularExpressions.Regex]::Matches($newText, 'def\s+_antirepeat_last_resort_553f\s*\(').Count
$hookCount = [System.Text.RegularExpressions.Regex]::Matches($newText, [System.Text.RegularExpressions.Regex]::Escape($hook)).Count
$helperPos = $newText.IndexOf('def _antirepeat_last_resort_553f(', [System.StringComparison]::Ordinal)
$entryDouble2 = $newText.IndexOf($guardDouble, [System.StringComparison]::Ordinal)
$entrySingle2 = $newText.IndexOf($guardSingle, [System.StringComparison]::Ordinal)
$entry2 = -1
if ($entryDouble2 -ge 0 -and $entrySingle2 -ge 0) {
    $entry2 = [Math]::Min($entryDouble2, $entrySingle2)
}
elif ($entryDouble2 -ge 0) {
    $entry2 = $entryDouble2
}
elif ($entrySingle2 -ge 0) {
    $entry2 = $entrySingle2
}
if ($entry2 -lt 0) {
    $m2 = [System.Text.RegularExpressions.Regex]::Match($newText, '(?m)^main\(\)\s*$')
    if ($m2.Success) { $entry2 = $m2.Index }
}

if ($helperCount -ne 1 -or $hookCount -lt 1 -or $helperPos -lt 0 -or $entry2 -lt 0 -or $helperPos -gt $entry2) {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw "Verification failed before write: helperCount=$helperCount hookCount=$hookCount helperPos=$helperPos entryPos=$entry2"
}

[System.IO.File]::WriteAllText($EnginePath, $newText, $utf8NoBom)

$verify = [System.IO.File]::ReadAllText($EnginePath, [System.Text.Encoding]::UTF8)
if (-not $verify.Contains($gMarker) -or -not $verify.Contains($hook)) {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw 'Verification failed after write. engine.py da duoc khoi phuc.'
}

# Optional syntax check when system Python launcher exists. If not, skip safely.
$py = Get-Command py -ErrorAction SilentlyContinue
if ($null -ne $py) {
    & py -3 -m py_compile $EnginePath 2>$null
    if ($LASTEXITCODE -ne 0) {
        Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
        throw 'Python syntax check failed. engine.py da duoc khoi phuc.'
    }
    Write-Host '[OK] Python syntax check PASS.' -ForegroundColor Green
}

Write-Host '[OK] 5.5.3g: helper Final Repair da duoc dua len TRUOC main().' -ForegroundColor Green
Write-Host '[OK] Sua truc tiep NameError: _antirepeat_last_resort_553f is not defined.' -ForegroundColor Green
Write-Host '[OK] Giu nguyen GPU Recovery, StoryFlow, GoldStyle, 10-tu va timeline.' -ForegroundColor Green
exit 0
