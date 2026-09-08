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
$hMarker     = '# === 5.5.3h_HELPER_BEFORE_MAIN_DEF ==='
$hook        = 'return _antirepeat_last_resort_553f(locals(), language=language, duration=duration)'

if ($text.Contains($hMarker)) {
    Write-Host '[OK] 5.5.3h da duoc cai truoc do.' -ForegroundColor Green
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

try {
    # Lay helper block 5.5.3f ra khoi vi tri cu.
    $begin = $text.IndexOf($beginMarker, [System.StringComparison]::Ordinal)
    $endStart = $text.IndexOf($endMarker, $begin, [System.StringComparison]::Ordinal)
    if ($begin -lt 0 -or $endStart -lt 0) {
        throw 'Khong xac dinh duoc helper block 5.5.3f.'
    }
    $end = $endStart + $endMarker.Length
    while ($end -lt $text.Length -and ($text[$end] -eq "`r" -or $text[$end] -eq "`n")) { $end++ }

    $helper = $text.Substring($begin, $end - $begin).TrimEnd("`r", "`n")
    $body = $text.Remove($begin, $end - $begin)

    # Traceback cua app xac nhan engine.py co ham main().
    # Dat helper NGAY TRUOC 'def main(...)' thay vi tim entry-point call.
    # Nhu vay helper chac chan da duoc define truoc khi main() co the chay.
    $mainMatch = [System.Text.RegularExpressions.Regex]::Match(
        $body,
        '(?m)^def\s+main\s*\('
    )
    if (-not $mainMatch.Success) {
        throw 'Khong tim thay top-level def main(...) trong engine.py.'
    }
    $mainDef = $mainMatch.Index

    $prefix = $body.Substring(0, $mainDef).TrimEnd("`r", "`n")
    $suffix = $body.Substring($mainDef).TrimStart("`r", "`n")
    $newText = $prefix + "`r`n`r`n" + $hMarker + "`r`n" + $helper + "`r`n`r`n" + $suffix

    # Static verification.
    $helperCount = [System.Text.RegularExpressions.Regex]::Matches(
        $newText,
        'def\s+_antirepeat_last_resort_553f\s*\('
    ).Count
    $hookCount = [System.Text.RegularExpressions.Regex]::Matches(
        $newText,
        [System.Text.RegularExpressions.Regex]::Escape($hook)
    ).Count
    $helperPos = $newText.IndexOf('def _antirepeat_last_resort_553f(', [System.StringComparison]::Ordinal)
    $mainMatch2 = [System.Text.RegularExpressions.Regex]::Match($newText, '(?m)^def\s+main\s*\(')
    $mainPos = if ($mainMatch2.Success) { $mainMatch2.Index } else { -1 }

    if ($helperCount -ne 1) {
        throw "Verification failed: helperCount=$helperCount"
    }
    if ($hookCount -lt 1) {
        throw "Verification failed: hookCount=$hookCount"
    }
    if ($helperPos -lt 0 -or $mainPos -lt 0 -or $helperPos -gt $mainPos) {
        throw "Verification failed: helperPos=$helperPos mainDefPos=$mainPos"
    }

    [System.IO.File]::WriteAllText($EnginePath, $newText, $enc)

    $verify = [System.IO.File]::ReadAllText($EnginePath, [System.Text.Encoding]::UTF8)
    if (-not $verify.Contains($hMarker) -or -not $verify.Contains($hook)) {
        throw 'Verification after write failed.'
    }

    # Neu may co Python launcher thi kiem tra syntax. Khong co thi bo qua.
    $py = Get-Command py -ErrorAction SilentlyContinue
    if ($null -ne $py) {
        & py -3 -m py_compile $EnginePath 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw 'Python syntax check failed.'
        }
        Write-Host '[OK] Python syntax check PASS.' -ForegroundColor Green
    }

    Write-Host '[OK] 5.5.3h: helper Final Repair da duoc dat TRUOC def main().' -ForegroundColor Green
    Write-Host '[OK] Sua loi NameError ma khong can tim Python entry-point call.' -ForegroundColor Green
    Write-Host '[OK] Giu nguyen GPU Recovery, StoryFlow, GoldStyle, Anti-Repeat va timeline.' -ForegroundColor Green
}
catch {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw ($_.Exception.Message + ' engine.py da duoc khoi phuc.')
}

exit 0
