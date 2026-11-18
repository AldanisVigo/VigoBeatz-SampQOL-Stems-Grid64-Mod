# VigoBeatz native PowerShell installer; no Python or Tkinter required.
$ErrorActionPreference='Stop'
Set-Location $PSScriptRoot
function Bytes($p) { return [IO.File]::ReadAllBytes($p) }
function Hash($b) { return ([BitConverter]::ToString(([Security.Cryptography.SHA256]::Create()).ComputeHash($b))).Replace('-','').ToLowerInvariant() }
function Write-Bytes($p,$b) { $dir=[IO.Path]::GetDirectoryName($p); [IO.Directory]::CreateDirectory($dir)|Out-Null; [IO.File]::WriteAllBytes($p,$b) }
function Inflate($b) {
  $inputStream=New-Object IO.MemoryStream(,$b)
  $null=$inputStream.Seek(2,[IO.SeekOrigin]::Begin)
  $stream=New-Object IO.Compression.DeflateStream($inputStream,[IO.Compression.CompressionMode]::Decompress)
  $output=New-Object IO.MemoryStream
  $stream.CopyTo($output);$stream.Dispose();$inputStream.Dispose()
  return ,$output.ToArray()
}
try {
 $card=(Read-Host 'Enter SD card root (example E:\)').Trim('"').TrimEnd('\')
 $action=(Read-Host 'Type INSTALL or RESTORE').Trim().ToUpperInvariant()
 if ($action -notin @('INSTALL','RESTORE')) {throw 'Choose INSTALL or RESTORE'}
 if (!(Test-Path "$card\autorun\mpcqol.so" -PathType Leaf)) {throw 'No SampQOL autorun\mpcqol.so at SD root'}
 $backup="$card\VigoBeatz-Backup-SampQOL-v0.3.0"
 if ($action -eq 'RESTORE') {
   if (!(Test-Path "$backup\state.json")) {throw 'Backup missing'}
   $state=Get-Content "$backup\state.json" -Raw | ConvertFrom-Json
   foreach($rel in $state.original) {Write-Bytes "$card\$rel" (Bytes "$backup\original\$rel")}
   foreach($rel in $state.created) {if(Test-Path "$card\$rel" -PathType Leaf){Remove-Item -LiteralPath "$card\$rel" -Force}}
   Remove-Item -LiteralPath $backup -Recurse -Force
   Write-Host 'Restored original SampQOL files.';exit 0
 }
 if(Test-Path $backup) {throw 'Existing backup detected. Restore first.'}
 $man=Get-Content 'manifest.json' -Raw | ConvertFrom-Json
 if((Hash (Bytes "$card\autorun\mpcqol.so")) -ne $man.stock_sha256) {throw 'Unsupported SampQOL binary; only exact stock v0.3.0 accepted'}
 $updates=@{}
 foreach($prop in $man.patches.PSObject.Properties) {
   $rel=$prop.Name;$meta=$prop.Value;$orig=Bytes "$card\$rel"
   if((Hash $orig) -ne $meta.before) {throw "Original file mismatch: $rel"}
   $patch=Bytes "payload\$($meta.payload)"
   if((Hash $patch) -ne $meta.payload_sha256) {throw "Corrupt patch: $rel"}
   $ops=[Text.Encoding]::UTF8.GetString((Inflate $patch))|ConvertFrom-Json
   $out=New-Object IO.MemoryStream
   foreach($op in $ops) {
     if($op[0] -eq 'c') {$out.Write($orig,[int]$op[1],[int]$op[2])}
     elseif($op[0] -in @('l','i')) {$hex=[string]$op[1];$chunk=New-Object byte[] ($hex.Length/2);for($i=0;$i -lt $chunk.Length;$i++){$chunk[$i]=[Convert]::ToByte($hex.Substring($i*2,2),16)};$out.Write($chunk,0,$chunk.Length)}
     else {throw 'Invalid patch opcode'}
   }
   $data=$out.ToArray();$out.Dispose()
   if((Hash $data) -ne $meta.after) {throw "Reconstructed file mismatch: $rel"}
   $updates[$rel]=$data
 }
 foreach($prop in $man.files.PSObject.Properties) {
   $rel=$prop.Name;$data=Bytes "payload\new\$rel"
   if((Hash $data) -ne $prop.Value) {throw "Corrupt mod asset: $rel"}
   $updates[$rel]=$data
 }
 $state=@{version=1;original=@();created=@()}
 foreach($rel in ($updates.Keys|Sort-Object)) {
   if(Test-Path "$card\$rel") {if(!(Test-Path "$card\$rel" -PathType Leaf)){throw "Not a file: $rel"};$state.original+= $rel}
   else {$state.created+= $rel}
 }
 [IO.Directory]::CreateDirectory($backup)|Out-Null
 foreach($rel in $state.original) {Write-Bytes "$backup\original\$rel" (Bytes "$card\$rel")}
 [IO.File]::WriteAllText("$backup\state.json",($state|ConvertTo-Json -Depth 5))
 try {
   foreach($rel in ($updates.Keys|Sort-Object)) {
     Write-Bytes "$card\$rel" $updates[$rel]
     if((Hash (Bytes "$card\$rel")) -ne (Hash $updates[$rel])) {throw "Verification failed: $rel"}
   }
 } catch {
   foreach($rel in $state.original) {Write-Bytes "$card\$rel" (Bytes "$backup\original\$rel")}
   foreach($rel in $state.created) {if(Test-Path "$card\$rel" -PathType Leaf){Remove-Item -LiteralPath "$card\$rel" -Force}}
   throw "Install failed; originals restored: $_"
 }
 Write-Host 'SUCCESS. Stems + Grid64 installed. Backup retained on SD card.'
} catch {Write-Host "ERROR: $_" -ForegroundColor Red;exit 1}
