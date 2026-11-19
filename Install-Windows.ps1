# VigoBeatz SampQOL Stems + Grid64 — Windows installer (PowerShell 5.1+)
# Requires manifest.json and payload/ alongside this script. No Python required.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Read-Bytes([string]$Path) {
    # The leading comma is CRITICAL: PowerShell otherwise unwraps byte[] into object[].
    return ,([System.IO.File]::ReadAllBytes($Path))
}
function Get-Hash([byte[]]$Data) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Data))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Write-Bytes([string]$Path, [byte[]]$Data) {
    $parent = [System.IO.Path]::GetDirectoryName($Path)
    if ($parent) { [System.IO.Directory]::CreateDirectory($parent) | Out-Null }
    [System.IO.File]::WriteAllBytes($Path, $Data)
}
function Expand-Zlib([byte[]]$Data) {
    if ($Data.Length -lt 6 -or (($Data[0] -band 15) -ne 8)) {
        throw 'Invalid zlib compressed patch'
    }
    # Windows PowerShell 5.1 (.NET Framework) DeflateStream expects raw DEFLATE.
    $inputStream = New-Object System.IO.MemoryStream(, $Data)
    $outputStream = New-Object System.IO.MemoryStream
    $deflate = $null
    try {
        [void]$inputStream.Seek(2, [System.IO.SeekOrigin]::Begin)
        $deflate = New-Object System.IO.Compression.DeflateStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)
        $deflate.CopyTo($outputStream)
        return ,($outputStream.ToArray())
    }
    finally {
        if ($null -ne $deflate) { $deflate.Dispose() }
        $inputStream.Dispose()
        $outputStream.Dispose()
    }
}
function Safe-RelativePath([string]$Rel) {
    $Rel = $Rel.Replace('/', '\')
    if ([System.IO.Path]::IsPathRooted($Rel) -or $Rel -match '(^|\\)\.\.?($|\\)' -or $Rel.Contains(':')) {
        throw "Unsafe path in manifest: $Rel"
    }
    return $Rel
}
function On-Card([string]$Relative) {
    return [System.IO.Path]::Combine($script:CardRoot, (Safe-RelativePath $Relative))
}
function On-Package([string]$Relative) {
    return [System.IO.Path]::Combine($PSScriptRoot, (Safe-RelativePath $Relative))
}

try {
    Write-Host 'VigoBeatz SampQOL Stems + Grid64 Installer (BETA)' -ForegroundColor Cyan
    $rawCard = (Read-Host 'Enter the SD card drive letter/root (for example E:\)').Trim().Trim('"')
    if ($rawCard -match '^[A-Za-z]:$') { $rawCard += '\' }
    $script:CardRoot = [System.IO.Path]::GetFullPath($rawCard)
    $root = [System.IO.Path]::GetPathRoot($script:CardRoot)
    if (-not $root -or $script:CardRoot.TrimEnd('\') -ne $root.TrimEnd('\')) {
        throw 'Enter the SD card DRIVE ROOT (for example E:\), not a subfolder.'
    }
    if (-not (Test-Path -LiteralPath $script:CardRoot -PathType Container)) {
        throw "SD card drive not found: $script:CardRoot"
    }
    $stockDll = On-Card 'autorun/mpcqol.so'
    if (-not (Test-Path -LiteralPath $stockDll -PathType Leaf)) {
        throw 'No SampQOL installation found: autorun/mpcqol.so is missing at the card root.'
    }
    $action = (Read-Host 'Type INSTALL or RESTORE').Trim().ToUpperInvariant()
    if ($action -notin @('INSTALL', 'RESTORE')) { throw 'Choose INSTALL or RESTORE.' }
    $backup = On-Card 'VigoBeatz-Backup-SampQOL-v0.3.0'

    if ($action -eq 'RESTORE') {
        $statePath = [System.IO.Path]::Combine($backup, 'state.json')
        if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) { throw 'Backup state.json is missing. Cannot restore.' }
        $state = [System.IO.File]::ReadAllText($statePath) | ConvertFrom-Json
        foreach ($rel in $state.original) {
            $rel = Safe-RelativePath ([string]$rel)
            $backupFile = [System.IO.Path]::Combine($backup, 'original', $rel)
            if (-not (Test-Path -LiteralPath $backupFile -PathType Leaf)) { throw "Missing backup file: $rel" }
        }
        foreach ($rel in $state.original) {
            $rel = Safe-RelativePath ([string]$rel)
            Write-Bytes (On-Card $rel) (Read-Bytes ([System.IO.Path]::Combine($backup, 'original', $rel)))
        }
        foreach ($rel in $state.created) {
            $target = On-Card ([string]$rel)
            if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force }
        }
        Remove-Item -LiteralPath $backup -Recurse -Force
        Write-Host 'RESTORE SUCCESS: original files restored.' -ForegroundColor Green
    }
    else {
        if (Test-Path -LiteralPath $backup) { throw 'An installer backup already exists. RESTORE first.' }
        $manifestPath = On-Package 'manifest.json'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            throw 'manifest.json not found. Download/extract the ENTIRE GitHub repository ZIP.'
        }
        $man = [System.IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
        if ((Get-Hash (Read-Bytes $stockDll)) -ne $man.stock_sha256) {
            throw 'Unsupported SampQOL binary. Only the exact unmodified v0.3.0 build is supported.'
        }
        $updates = @{}
        foreach ($prop in $man.patches.PSObject.Properties) {
            $rel = Safe-RelativePath $prop.Name
            $meta = $prop.Value
            $orig = Read-Bytes (On-Card $rel)
            if ((Get-Hash $orig) -ne $meta.before) { throw "Unsupported original file: $rel" }
            $patchFile = On-Package ("payload/" + $meta.payload)
            $patch = Read-Bytes $patchFile
            if ((Get-Hash $patch) -ne $meta.payload_sha256) { throw "Patch checksum mismatch: $rel" }
            $ops = [Text.Encoding]::UTF8.GetString((Expand-Zlib $patch)) | ConvertFrom-Json
            $out = New-Object System.IO.MemoryStream
            try {
                foreach ($op in $ops) {
                    if ($op[0] -eq 'c') {
                        $offset = [int]$op[1]; $length = [int]$op[2]
                        if ($offset -lt 0 -or $length -lt 0 -or $offset + $length -gt $orig.Length) {
                            throw "Invalid copy range in patch: $rel"
                        }
                        $out.Write($orig, $offset, $length)
                    }
                    elseif ($op[0] -eq 'l' -or $op[0] -eq 'i') {
                        $hex = [string]$op[1]
                        if ($hex.Length % 2 -ne 0) { throw "Invalid hex patch data: $rel" }
                        $chunk = New-Object byte[] ($hex.Length / 2)
                        for ($i = 0; $i -lt $chunk.Length; $i++) {
                            $chunk[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16)
                        }
                        $out.Write($chunk, 0, $chunk.Length)
                    }
                    else { throw "Unrecognized patch opcode for $rel" }
                }
                $data = $out.ToArray()
            }
            finally { $out.Dispose() }
            if ((Get-Hash $data) -ne $meta.after) { throw "Rebuilt file checksum mismatch: $rel" }
            $updates[$rel] = $data
        }
        foreach ($prop in $man.files.PSObject.Properties) {
            $rel = Safe-RelativePath $prop.Name
            $data = Read-Bytes (On-Package ("payload/new/" + $rel))
            if ((Get-Hash $data) -ne $prop.Value) { throw "Asset checksum mismatch: $rel" }
            $updates[$rel] = $data
        }
        $state = @{ version = 1; original = @(); created = @() }
        foreach ($rel in ($updates.Keys | Sort-Object)) {
            $dest = On-Card $rel
            if (Test-Path -LiteralPath $dest) {
                if (-not (Test-Path -LiteralPath $dest -PathType Leaf)) { throw "Expected regular file: $rel" }
                $state.original += $rel
            }
            else { $state.created += $rel }
        }
        [System.IO.Directory]::CreateDirectory($backup) | Out-Null
        try {
            foreach ($rel in $state.original) {
                $backupFile = [System.IO.Path]::Combine($backup, 'original', $rel)
                Write-Bytes $backupFile (Read-Bytes (On-Card $rel))
            }
            $stateJson = $state | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText([System.IO.Path]::Combine($backup, 'state.json'), $stateJson)
            foreach ($rel in ($updates.Keys | Sort-Object)) {
                Write-Host "Installing $rel"
                Write-Bytes (On-Card $rel) ([byte[]]$updates[$rel])
                if ((Get-Hash (Read-Bytes (On-Card $rel))) -ne (Get-Hash ([byte[]]$updates[$rel]))) {
                    throw "Write verification failed: $rel"
                }
            }
            Write-Host 'INSTALL SUCCESS: Stems + Grid64 installed; backup retained on SD card.' -ForegroundColor Green
        }
        catch {
            $reason = $_
            Write-Warning 'Installation error. Attempting to restore original files.'
            foreach ($rel in $state.original) {
                $backupFile = [System.IO.Path]::Combine($backup, 'original', $rel)
                if (Test-Path -LiteralPath $backupFile -PathType Leaf) {
                    Write-Bytes (On-Card $rel) (Read-Bytes $backupFile)
                }
            }
            foreach ($rel in $state.created) {
                $target = On-Card $rel
                if (Test-Path -LiteralPath $target -PathType Leaf) { Remove-Item -LiteralPath $target -Force }
            }
            throw "Installation failed; original files restored where possible: $reason"
        }
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Location: $($_.InvocationInfo.PositionMessage)" -ForegroundColor DarkGray
    exit 1
}
