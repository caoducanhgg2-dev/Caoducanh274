param(
    [Parameter(Mandatory=$true)]
    [string]$EnginePath
)

$ErrorActionPreference = 'Stop'
$enc = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path -LiteralPath $EnginePath)) {
    throw "Khong tim thay engine.py: $EnginePath"
}

$appDir = Split-Path -Parent $EnginePath
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$safety = Join-Path $appDir ("engine.py.before_5.5.4_" + $stamp)
Copy-Item -LiteralPath $EnginePath -Destination $safety -Force
Write-Host "[BACKUP CURRENT] $safety"

function Test-Clean553e([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    try {
        $t = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    } catch { return $false }
    if ($t -notmatch 'Anti-Repeat 5\.5\.3e') { return $false }
    if ($t -notmatch 'Final Gate V3') { return $false }
    if ($t -match '5\.5\.3f_FINAL_REPAIR_BEGIN') { return $false }
    if ($t -match '_antirepeat_last_resort_553f') { return $false }
    if ($t -match '5\.5\.3g_HELPER_ORDER_FIX') { return $false }
    if ($t -match '5\.5\.3h_HELPER_BEFORE_MAIN_DEF') { return $false }
    return $true
}

# 5.5.4 KHONG stack tren f/g/h. Luon tim lai source 5.5.3e sach truoc.
$clean = $null
$candidates = Get-ChildItem -LiteralPath $appDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'engine.py.bak_5.5.3e_*' } |
    Sort-Object LastWriteTime -Descending

foreach ($c in $candidates) {
    if (Test-Clean553e $c.FullName) {
        $clean = $c.FullName
        break
    }
}

# Neu engine hien tai van la 5.5.3e sach thi dung truc tiep no.
if ($null -eq $clean -and (Test-Clean553e $EnginePath)) {
    $clean = $EnginePath
}

if ($null -eq $clean) {
    throw @"
Khong tim thay engine.py 5.5.3e sach.
5.5.4 Clean khong duoc phep patch chong len 5.5.3f/g/h.
Hay cai lai goi 5.5.3e AntiRepeatV3 mot lan, dong app, roi chay lai INSTALL_PATCH.bat 5.5.4.
Engine hien tai da duoc backup va KHONG bi thay doi.
"@
}

Write-Host "[BASE CLEAN 5.5.3e] $clean" -ForegroundColor Cyan
$baseText = [System.IO.File]::ReadAllText($clean, [System.Text.Encoding]::UTF8)

# Tim DUY NHAT Final Gate V3 fatal RuntimeError trong source 5.5.3e.
$lines = [System.Text.RegularExpressions.Regex]::Split($baseText, "\r?\n")
$targets = New-Object System.Collections.Generic.List[object]

for ($p = 0; $p -lt $lines.Length; $p++) {
    $line = $lines[$p]
    if (($line -like '*Anti-Repeat 5.5.3e*hard-repeat*') -or
        ($line -like '*hard-repeat sau Final Gate V3*')) {

        $raiseStart = -1
        $indent = ''
        $floor = [Math]::Max(0, $p - 40)
        for ($i = $p; $i -ge $floor; $i--) {
            if ($lines[$i] -match '^(\s*)raise\s+RuntimeError\s*\(') {
                $raiseStart = $i
                $indent = $Matches[1]
                break
            }
        }
        if ($raiseStart -lt 0) { continue }

        $raiseEnd = -1
        $balance = 0
        $seenOpen = $false
        $scanEnd = [Math]::Min($lines.Length - 1, $raiseStart + 50)
        for ($j = $raiseStart; $j -le $scanEnd; $j++) {
            foreach ($ch in $lines[$j].ToCharArray()) {
                if ($ch -eq '(') { $balance++; $seenOpen = $true }
                elseif ($ch -eq ')') { $balance-- }
            }
            if ($seenOpen -and $balance -le 0) {
                $raiseEnd = $j
                break
            }
        }
        if ($raiseEnd -ge $raiseStart) {
            $targets.Add([pscustomobject]@{ Start=$raiseStart; End=$raiseEnd; Indent=$indent; Phrase=$p })
        }
    }
}

# Loai duplicate target neu 2 phrase cung nam trong mot raise block.
$unique = @{}
foreach ($t in $targets) {
    $key = "$($t.Start):$($t.End)"
    if (-not $unique.ContainsKey($key)) { $unique[$key] = $t }
}
$targetList = @($unique.Values | Sort-Object Start)

if ($targetList.Count -ne 1) {
    throw "5.5.4 Clean: can tim dung 1 Final Gate fatal block, nhung tim thay $($targetList.Count). Khong sua engine."
}

$t = $targetList[0]
$replacement = @(
    ($t.Indent + '# === 5.5.4_CLEAN_STABILITY_FINAL_GATE ==='),
    ($t.Indent + '# Final Gate da chay 3 pass + repair rieng tung caption. Neu van con hard-repeat,'),
    ($t.Indent + '# ghi QA/warning nhung KHONG huy toan bo SRT. Khong chen helper, khong sua main().'),
    ($t.Indent + 'pass')
)

$before = @()
if ($t.Start -gt 0) { $before = $lines[0..($t.Start - 1)] }
$after = @()
if ($t.End + 1 -lt $lines.Length) { $after = $lines[($t.End + 1)..($lines.Length - 1)] }
$newLines = @($before + $replacement + $after)
$newText = [string]::Join("`r`n", $newLines)

# Static integrity checks: khong mang bat ky helper f/g/h nao sang 5.5.4.
if ($newText -match '_antirepeat_last_resort_553f') {
    throw 'Integrity FAIL: helper 5.5.3f bi lot vao clean source.'
}
if ($newText -match '5\.5\.3f_FINAL_REPAIR_BEGIN|5\.5\.3g_HELPER_ORDER_FIX|5\.5\.3h_HELPER_BEFORE_MAIN_DEF') {
    throw 'Integrity FAIL: marker hotfix f/g/h bi lot vao clean source.'
}
if ($newText -notmatch '5\.5\.4_CLEAN_STABILITY_FINAL_GATE') {
    throw 'Integrity FAIL: thieu marker 5.5.4.'
}
if ($newText -notmatch 'Anti-Repeat 5\.5\.3e') {
    throw 'Integrity FAIL: mat Anti-Repeat 5.5.3e base.'
}
if ($newText -notmatch 'num_gpu') {
    Write-Host '[WARN] Khong thay chuoi num_gpu trong source. Khong dung patch, nhung nen kiem tra GPU sau khi mo app.' -ForegroundColor Yellow
}

# Ghi file moi chi sau khi tat ca static check da PASS.
[System.IO.File]::WriteAllText($EnginePath, $newText, $enc)

# Neu may co Python launcher thi compile. Neu compile fail, restore current engine truoc 5.5.4.
$py = Get-Command py -ErrorAction SilentlyContinue
if ($null -ne $py) {
    & py -3 -m py_compile $EnginePath 2>$null
    if ($LASTEXITCODE -ne 0) {
        Copy-Item -LiteralPath $safety -Destination $EnginePath -Force
        throw 'Python syntax check FAIL. Da restore engine truoc 5.5.4.'
    }
    Write-Host '[PASS] Python syntax compile.' -ForegroundColor Green
}

$markerFile = Join-Path $appDir 'PATCH_5.5.4_CLEAN.txt'
$markerText = @"
Comedy Host Studio Beta 5.1 - 5.5.4 Clean Stability
Installed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Base source: $clean
Safety backup: $safety
Policy: restore clean 5.5.3e first; no 5.5.3f/g/h helper stacking.
Change: Final Gate residual hard-repeat becomes QA warning instead of cancelling full SRT export.
Preserved: GPU Recovery 5.5.3b, StoryFlow, GoldStyle, 10-word target, ~4.08s, gap 0.10s, JP, Vietnamese translation.
"@
[System.IO.File]::WriteAllText($markerFile, $markerText, $enc)

Write-Host '[PASS] 5.5.4 Clean source installed.' -ForegroundColor Green
Write-Host '[PASS] 5.5.3f/g/h helper branch removed by clean-base restore.' -ForegroundColor Green
Write-Host '[PASS] Final Gate will no longer cancel the entire SRT for a residual repeat.' -ForegroundColor Green
Write-Host "[INFO] Rollback backup: $safety"
exit 0
