# gdrive_folder_dl.ps1
# Downloads all files from a public Google Drive folder
# Usage: powershell -File gdrive_folder_dl.ps1 <FOLDER_ID> <OUTPUT_DIR>
param(
    [Parameter(Mandatory=$true)][string]$FolderId,
    [Parameter(Mandatory=$true)][string]$OutDir
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

# ---- STEP 1: Fetch folder page and extract file list ----
Write-Host "  Fetching file list from Google Drive folder..."

$folderUrl = "https://drive.google.com/drive/folders/${FolderId}?usp=sharing"
try {
    $resp = Invoke-WebRequest -Uri $folderUrl -UseBasicParsing -UserAgent $ua
} catch {
    Write-Host "  ERROR: Cannot access Google Drive folder: $_"
    exit 1
}

$html = $resp.Content

# Decode unicode escape sequences (\xNN, \uNNNN) that Google embeds in the page
$decoded = $html
try {
    $decoded = [regex]::Replace($decoded, '\\x([0-9a-fA-F]{2})', {
        param($m) [char][int]('0x' + $m.Groups[1].Value)
    })
    $decoded = [regex]::Replace($decoded, '\\u([0-9a-fA-F]{4})', {
        param($m) [char][int]('0x' + $m.Groups[1].Value)
    })
} catch {}

# ---- STEP 2: Parse file entries from embedded data ----
# Google Drive embeds file metadata in the HTML as JavaScript data arrays
# File entries appear in the pattern: "FILE_ID",["FILENAME",...
# We search for file IDs (25-45 chars) followed by filenames with extensions

$files = @()
$seenIds = @{}

# Collect all potential file IDs and filenames from the page
$allIds = [regex]::Matches($decoded, '"([a-zA-Z0-9_-]{25,50})"')
$allNames = [regex]::Matches($decoded, '"([^"]{2,200}\.(?:exe|zip|msi|iso|7z|rar|cab|tar|gz|bat|cmd|ps1|msu|inf|dll|sys))"', 'IgnoreCase')

# For each filename found, find the nearest file ID within 300 chars
foreach ($nm in $allNames) {
    $namePos = $nm.Index
    $fileName = $nm.Groups[1].Value

    # Skip obvious non-file strings
    if ($fileName -match '(?:http|www\.|\.com|\.org|\\x|function|prototype|return)') { continue }

    $bestId = $null
    $bestDist = 99999

    foreach ($im in $allIds) {
        $id = $im.Groups[1].Value
        # Skip the folder ID itself
        if ($id -eq $FolderId) { continue }
        # Skip IDs we've already matched
        if ($seenIds.ContainsKey($id)) { continue }

        $dist = [Math]::Abs($im.Index - $namePos)
        if ($dist -lt $bestDist -and $dist -lt 1000) {
            $bestDist = $dist
            $bestId = $id
        }
    }

    if ($bestId) {
        $files += [PSCustomObject]@{ Id = $bestId; Name = $fileName }
        $seenIds[$bestId] = $true
    }
}

# Fallback: if no files found, try broader pattern
if ($files.Count -eq 0) {
    # Look for direct ID-name pairs: ["ID",["NAME"
    $pairPattern = '\["([a-zA-Z0-9_-]{25,50})"\s*,\s*\[\s*"([^"]+\.\w{2,5})"'
    $pairs = [regex]::Matches($decoded, $pairPattern)
    foreach ($p in $pairs) {
        $id = $p.Groups[1].Value
        $name = $p.Groups[2].Value
        if ($id -ne $FolderId -and -not $seenIds.ContainsKey($id)) {
            $files += [PSCustomObject]@{ Id = $id; Name = $name }
            $seenIds[$id] = $true
        }
    }
}

if ($files.Count -eq 0) {
    Write-Host "  WARNING: No files found in Drive folder."
    Write-Host "  Make sure the folder is shared as 'Anyone with the link'."
    Write-Host "  Folder ID: $FolderId"
    exit 1
}

Write-Host "  Found $($files.Count) file(s):"
foreach ($f in $files) {
    Write-Host "    - $($f.Name)"
}
Write-Host ""

# ---- STEP 3: Download each file ----
$success = 0
$skipped = 0
$failed = 0

foreach ($f in $files) {
    $outPath = Join-Path $OutDir $f.Name

    # Skip if already exists
    if (Test-Path $outPath) {
        Write-Host "  [SKIP] $($f.Name) (already exists)"
        $skipped++
        continue
    }

    Write-Host "  [DL] $($f.Name)..." -NoNewline

    try {
        # Step A: Hit the download URL to get session cookies, confirm token, and uuid (with retries)
        $session = $null
        $confirmToken = 't'
        $uuid = ''
        $stepAConnected = $false
        $retryCountA = 0
        $maxRetriesA = 3
        while (-not $stepAConnected -and $retryCountA -lt $maxRetriesA) {
            try {
                $retryCountA++
                $r = Invoke-WebRequest -Uri "https://drive.google.com/uc?export=download&id=$($f.Id)" `
                    -SessionVariable session -UseBasicParsing -UserAgent $ua -ErrorAction Stop
                if ($r.Content -match 'name="uuid"\s+value="([^"]+)"') {
                    $uuid = $Matches[1]
                }
                if ($r.Content -match 'name="confirm"\s+value="([^"]+)"') {
                    $confirmToken = $Matches[1]
                } elseif ($r.Content -match 'confirm=([0-9A-Za-z_-]+)') {
                    $confirmToken = $Matches[1]
                }
                $stepAConnected = $true
            } catch {
                if ($retryCountA -eq $maxRetriesA) {
                    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                } else {
                    Start-Sleep -Seconds 2
                }
            }
        }

        # Step B: Download with confirm token, uuid, and session cookies (with retries)
        if ($uuid) {
            $dlUrl = "https://drive.usercontent.google.com/download?id=$($f.Id)&export=download&confirm=$confirmToken&uuid=$uuid"
        } else {
            $dlUrl = "https://drive.google.com/uc?export=download&confirm=$confirmToken&id=$($f.Id)"
        }

        $maxRetriesB = 3
        $retryCountB = 0
        $downloadSuccess = $false

        while (-not $downloadSuccess -and $retryCountB -lt $maxRetriesB) {
            try {
                $retryCountB++
                if ($retryCountB -gt 1) {
                    Write-Host " (Retry $retryCountB/$maxRetriesB)..." -NoNewline
                    Start-Sleep -Seconds 3
                }
                Invoke-WebRequest -Uri $dlUrl -OutFile $outPath -WebSession $session -UseBasicParsing -UserAgent $ua -ErrorAction Stop
                $downloadSuccess = $true
            } catch {
                if ($retryCountB -eq $maxRetriesB) {
                    throw $_
                }
            }
        }

        # Step C: Validate the downloaded file is not an HTML error page
        if (Test-Path $outPath) {
            $fi = Get-Item $outPath
            if ($fi.Length -lt 5000) {
                $content = Get-Content $outPath -Raw -ErrorAction SilentlyContinue
                if ($content -match '<!DOCTYPE|<html|Google Drive - Virus') {
                    Remove-Item $outPath -Force
                    Write-Host " FAILED (got HTML error page instead of file)"
                    $failed++
                    continue
                }
            }
            $sizeMB = [Math]::Round($fi.Length / 1MB, 1)
            Write-Host " OK ($sizeMB MB)"
            $success++
        } else {
            Write-Host " FAILED (file not created)"
            $failed++
        }
    } catch {
        Write-Host " FAILED ($_)"
        if (Test-Path $outPath) { Remove-Item $outPath -Force -ErrorAction SilentlyContinue }
        $failed++
    }
}

# ---- STEP 4: Summary ----
Write-Host ""
Write-Host "  Download complete: $success OK, $skipped skipped, $failed failed"
exit $(if ($failed -gt 0) { 1 } else { 0 })
