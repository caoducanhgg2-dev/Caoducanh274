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
$marker = '# === 5.5.3f_FINAL_REPAIR_BEGIN ==='

if ($text.Contains($marker)) {
    Write-Host '[OK] 5.5.3f da duoc cai truoc do. Khong can patch lai.' -ForegroundColor Green
    exit 0
}

if (($text -notmatch 'Anti-Repeat 5\.5\.3e') -and ($text -notmatch 'hard-repeat sau Final Gate V3')) {
    throw 'Khong tim thay Final Gate V3 cua 5.5.3e. Hay cai 5.5.3e truoc khi cai 5.5.3f.'
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = "$EnginePath.bak_5.5.3e_$stamp"
Copy-Item -LiteralPath $EnginePath -Destination $backup -Force
Write-Host "[BACKUP] $backup"

$lines = [System.Text.RegularExpressions.Regex]::Split($text, "\r?\n")
$phraseIndex = -1

for ($i = 0; $i -lt $lines.Length; $i++) {
    if (($lines[$i] -like '*Anti-Repeat 5.5.3e*hard-repeat*') -or
        ($lines[$i] -like '*hard-repeat sau Final Gate V3*')) {
        $phraseIndex = $i
        break
    }
}

if ($phraseIndex -lt 0) {
    throw 'Khong tim thay thong bao hard-repeat cuoi cua 5.5.3e.'
}

$raiseStart = -1
$indent = ''
$searchFloor = [Math]::Max(0, $phraseIndex - 30)
for ($i = $phraseIndex; $i -ge $searchFloor; $i--) {
    if ($lines[$i] -match '^(\s*)raise\s+RuntimeError\s*\(') {
        $raiseStart = $i
        $indent = $Matches[1]
        break
    }
}

if ($raiseStart -lt 0) {
    throw 'Khong tim thay raise RuntimeError cua Final Gate V3.'
}

$raiseEnd = -1
$balance = 0
$seenOpen = $false
$scanEnd = [Math]::Min($lines.Length - 1, $raiseStart + 40)
for ($i = $raiseStart; $i -le $scanEnd; $i++) {
    $line = $lines[$i]
    foreach ($ch in $line.ToCharArray()) {
        if ($ch -eq '(') {
            $balance++
            $seenOpen = $true
        }
        elseif ($ch -eq ')') {
            $balance--
        }
    }
    if ($seenOpen -and $balance -le 0) {
        $raiseEnd = $i
        break
    }
}

if ($raiseEnd -lt $raiseStart) {
    throw 'Khong xac dinh duoc diem ket thuc cua RuntimeError block.'
}

$replacement = $indent + 'return _antirepeat_last_resort_553f(locals(), language=language, duration=duration)'

$before = @()
if ($raiseStart -gt 0) {
    $before = $lines[0..($raiseStart - 1)]
}
$after = @()
if ($raiseEnd + 1 -lt $lines.Length) {
    $after = $lines[($raiseEnd + 1)..($lines.Length - 1)]
}

$patchedLines = @($before + $replacement + $after)
$patchedText = [string]::Join("`r`n", $patchedLines)

$helper = @'

# === 5.5.3f_FINAL_REPAIR_BEGIN ===
def _antirepeat_last_resort_553f(local_map, language="EN", duration=None):
    """Last-resort export guard for 5.5.3e Final Gate V3.

    The normal AI/editor pipeline still runs first. This helper is reached only
    when that pipeline would otherwise abort the whole job because one or a few
    hard repeats remain after the final repair attempts.

    It locates the in-memory caption timeline from write_srt_script locals,
    identifies the caption(s) already marked as remaining hard repeats whenever
    possible, and replaces only those rows with factual-safe, complete,
    deterministic 10-word reviewer lines. It never rescans the video and never
    rewrites the whole script.
    """
    import copy as _copy553f
    import difflib as _difflib553f
    import re as _re553f

    _word_re553f = _re553f.compile(r"[A-Za-z0-9]+(?:['’][A-Za-z0-9]+)?(?:-[A-Za-z0-9]+)*")

    def _words553f(text):
        return _word_re553f.findall(str(text or ""))

    def _norm553f(text):
        return " ".join(w.lower() for w in _words553f(text))

    def _script_score553f(name, value):
        if not isinstance(value, list) or len(value) < 2:
            return -1
        good = 0
        for row in value:
            if not isinstance(row, dict) or not isinstance(row.get("text"), str):
                continue
            has_start = any(k in row for k in ("start", "start_time", "begin", "from"))
            has_end = any(k in row for k in ("end", "end_time", "finish", "to"))
            if has_start and has_end:
                good += 1
        if good < max(2, int(len(value) * 0.60)):
            return -1
        bonus = 0
        lname = str(name or "").lower()
        if "script" in lname:
            bonus += 5000
        if "caption" in lname or "slot" in lname or "timeline" in lname:
            bonus += 2500
        if "observation" in lname or "event" in lname:
            bonus -= 3000
        return good * 100 + len(value) + bonus

    candidates = []
    for _name553f, _value553f in dict(local_map or {}).items():
        _score553f = _script_score553f(_name553f, _value553f)
        if _score553f >= 0:
            candidates.append((_score553f, _name553f, _value553f))

    if not candidates:
        raise RuntimeError(
            "Anti-Repeat 5.5.3f: khong tim thay caption timeline trong bo nho de sua last-resort."
        )

    candidates.sort(key=lambda x: x[0], reverse=True)
    _source_name553f = candidates[0][1]
    _source553f = candidates[0][2]
    script553f = [_copy553f.deepcopy(row) for row in _source553f]

    # Deterministic factual-safe reviewer lines. Every row is exactly 10 words
    # under the same contraction/hyphen-friendly counting rule used here.
    fallbacks553f = [
        "The movement repeats, but small visible changes keep adding up.",
        "Same task again, yet the result keeps looking more defined.",
        "Nothing dramatic changes, but visible progress stays easy to follow.",
        "Another steady pass adds detail without changing the basic process.",
        "The action stays familiar, while the result keeps evolving slowly.",
        "This part repeats, yet each pass leaves something visibly different.",
        "The process looks repetitive, but the outcome keeps gaining definition.",
        "Same rhythm here, although the scene keeps showing gradual progress.",
        "The method barely changes, but the visible result keeps improving.",
        "Another familiar step lands, and the overall picture gets clearer.",
        "Repetition takes over here, but the details still move forward.",
        "The same motion continues, while the overall shape grows clearer.",
        "No big twist yet, just steady progress becoming more obvious.",
        "This stretch stays repetitive, though the result keeps developing steadily.",
        "Another routine pass, and the visible difference becomes easier now.",
        "The action repeats again, but the scene still moves forward.",
        "Same basic move, yet the overall result keeps changing visibly.",
        "This step feels familiar, but the details keep building momentum.",
        "The routine continues, while each pass adds another visible change.",
        "Repeated work dominates here, but progress still shows clearly onscreen.",
    ]

    for _fb553f in fallbacks553f:
        if len(_words553f(_fb553f)) != 10:
            raise RuntimeError("Anti-Repeat 5.5.3f internal fallback word-count check failed.")

    def _extract_caption_ids553f(obj, depth=0):
        found = set()
        if depth > 4:
            return found
        if isinstance(obj, dict):
            if "caption" in obj:
                try:
                    cap = int(obj.get("caption"))
                    if 1 <= cap <= len(script553f):
                        found.add(cap - 1)
                except Exception:
                    pass
            for k, v in obj.items():
                lk = str(k).lower()
                if depth == 0 or any(token in lk for token in ("remain", "hard", "repeat", "issue", "fail")):
                    found.update(_extract_caption_ids553f(v, depth + 1))
        elif isinstance(obj, (list, tuple)):
            for v in obj:
                found.update(_extract_caption_ids553f(v, depth + 1))
        return found

    targets553f = set()
    for _name553f, _value553f in dict(local_map or {}).items():
        lname = str(_name553f).lower()
        if any(token in lname for token in ("remain", "hard", "repeat", "fail", "issue")):
            targets553f.update(_extract_caption_ids553f(_value553f))

    norms553f = [_norm553f(row.get("text", "")) for row in script553f]

    # Exact duplicates are always hard.
    seen553f = {}
    for idx553f, n553f in enumerate(norms553f):
        if not n553f:
            continue
        if n553f in seen553f:
            targets553f.add(idx553f)
        else:
            seen553f[n553f] = idx553f

    # Strong reviewer opener/catchphrase reuse remains hard only as last-resort.
    openers553f = (
        "okay", "wait", "look at that", "boom", "my guy",
        "this is where", "here comes", "secret weapon time",
    )
    families553f = (
        "diy wizard", "secret weapon", "built like a tank", "proper payoff",
        "real magic", "heavy lifting", "jackpot", "no shortcuts",
        "game changer", "next level",
    )

    used_openers553f = {}
    used_families553f = {}
    for idx553f, n553f in enumerate(norms553f):
        for op553f in openers553f:
            if n553f == op553f or n553f.startswith(op553f + " "):
                if op553f in used_openers553f:
                    targets553f.add(idx553f)
                else:
                    used_openers553f[op553f] = idx553f
                break
        for fam553f in families553f:
            if fam553f in n553f:
                if fam553f in used_families553f:
                    targets553f.add(idx553f)
                else:
                    used_families553f[fam553f] = idx553f

    # Extremely close copies are hard; moderate factual similarity is not.
    for i553f in range(len(script553f)):
        ni553f = norms553f[i553f]
        if len(_words553f(ni553f)) < 5:
            continue
        for j553f in range(i553f):
            nj553f = norms553f[j553f]
            if len(_words553f(nj553f)) < 5:
                continue
            sim553f = _difflib553f.SequenceMatcher(None, ni553f, nj553f).ratio()
            if sim553f >= 0.95:
                targets553f.add(i553f)
                break

    # If Final Gate reported a hard repeat but its local variable used an
    # unexpected shape, repair the strongest remaining pair instead of aborting.
    if not targets553f:
        best553f = (0.0, None)
        for i553f in range(1, len(script553f)):
            ni553f = norms553f[i553f]
            if not ni553f:
                continue
            for j553f in range(i553f):
                nj553f = norms553f[j553f]
                if not nj553f:
                    continue
                sim553f = _difflib553f.SequenceMatcher(None, ni553f, nj553f).ratio()
                if sim553f > best553f[0]:
                    best553f = (sim553f, i553f)
        if best553f[1] is not None and best553f[0] >= 0.85:
            targets553f.add(best553f[1])

    existing553f = {_norm553f(row.get("text", "")) for row in script553f}
    used_fallbacks553f = set()

    for idx553f in sorted(targets553f):
        if not (0 <= idx553f < len(script553f)):
            continue
        chosen553f = None
        for fb553f in fallbacks553f:
            nfb553f = _norm553f(fb553f)
            if nfb553f in existing553f or nfb553f in used_fallbacks553f:
                continue
            too_close553f = False
            for row553f in script553f:
                other553f = _norm553f(row553f.get("text", ""))
                if not other553f:
                    continue
                if _difflib553f.SequenceMatcher(None, nfb553f, other553f).ratio() >= 0.88:
                    too_close553f = True
                    break
            if not too_close553f:
                chosen553f = fb553f
                break
        if chosen553f is None:
            # The pool is intentionally larger than a normal repair count.
            # This fallback is deterministic and still exactly 10 words.
            chosen553f = "Repeated work dominates here, but progress still shows clearly onscreen."

        old_norm553f = _norm553f(script553f[idx553f].get("text", ""))
        if old_norm553f in existing553f:
            try:
                existing553f.remove(old_norm553f)
            except KeyError:
                pass
        script553f[idx553f]["text"] = chosen553f
        if "role" in script553f[idx553f]:
            script553f[idx553f]["role"] = "anti_repeat_last_resort"
        new_norm553f = _norm553f(chosen553f)
        existing553f.add(new_norm553f)
        used_fallbacks553f.add(new_norm553f)

    # Final exact-duplicate sweep. Only the later row is touched.
    seen553f = {}
    pool_index553f = 0
    for idx553f, row553f in enumerate(script553f):
        n553f = _norm553f(row553f.get("text", ""))
        if n553f and n553f in seen553f:
            while pool_index553f < len(fallbacks553f):
                candidate553f = fallbacks553f[pool_index553f]
                pool_index553f += 1
                nc553f = _norm553f(candidate553f)
                if nc553f not in seen553f and nc553f not in used_fallbacks553f:
                    row553f["text"] = candidate553f
                    if "role" in row553f:
                        row553f["role"] = "anti_repeat_last_resort"
                    n553f = nc553f
                    used_fallbacks553f.add(nc553f)
                    break
        if n553f:
            seen553f[n553f] = idx553f

    # Guarantee that every row inserted by this last-resort stage is exactly
    # ten words. Existing captions are intentionally left untouched here.
    for row553f in script553f:
        if row553f.get("role") == "anti_repeat_last_resort":
            if len(_words553f(row553f.get("text", ""))) != 10:
                raise RuntimeError("Anti-Repeat 5.5.3f: last-resort caption is not exactly 10 words.")

    return script553f
# === 5.5.3f_FINAL_REPAIR_END ===
'@

$newText = $patchedText + $helper + "`r`n"
[System.IO.File]::WriteAllText($EnginePath, $newText, $utf8NoBom)

$verify = [System.IO.File]::ReadAllText($EnginePath, [System.Text.Encoding]::UTF8)
if (-not $verify.Contains($marker)) {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw 'Verification failed: helper marker missing. engine.py da duoc khoi phuc tu backup.'
}
if (-not $verify.Contains('return _antirepeat_last_resort_553f(locals(), language=language, duration=duration)')) {
    Copy-Item -LiteralPath $backup -Destination $EnginePath -Force
    throw 'Verification failed: Final Gate return hook missing. engine.py da duoc khoi phuc tu backup.'
}

Write-Host '[OK] Da thay strict abort bang 5.5.3f Final Repair.' -ForegroundColor Green
Write-Host '[OK] Chi caption hard-repeat cuoi moi dung deterministic fallback 10 tu.' -ForegroundColor Green
Write-Host '[OK] Toan bo Visual Brain, StoryFlow, GoldStyle, GPU Recovery va timeline duoc giu nguyen.' -ForegroundColor Green
exit 0
