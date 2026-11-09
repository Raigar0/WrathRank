$ErrorActionPreference = 'Stop'

$addon = Join-Path $PSScriptRoot 'WrathRank'
$manifest = Get-Content -Raw -LiteralPath (Join-Path $addon 'WrathRank.toc')
$version = [regex]::Match($manifest, '(?m)^## Version: (\d+\.\d+\.\d+)\s*$').Groups[1].Value
if (!$version) { throw 'WrathRank.toc needs a numeric version.' }

$dist = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$output = Join-Path $dist "WrathRank-$version.zip"
$temporary = "$output.tmp"

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
$archive = [IO.Compression.ZipFile]::Open($temporary, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in Get-ChildItem -LiteralPath $addon -File) {
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, "WrathRank/$($file.Name)")
    }
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $PSScriptRoot 'LICENSE'), 'WrathRank/LICENSE')
} finally {
    $archive.Dispose()
}
Move-Item -LiteralPath $temporary -Destination $output -Force
Write-Output $output
