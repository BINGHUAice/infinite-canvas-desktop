#Requires -Version 7.0
param(
    [Parameter(Mandatory)] [string] $Source,
    [Parameter(Mandatory)] [string] $Output,
    [Parameter(Mandatory)] [ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+$')] [string] $Tag,
    [string] $Iscc = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$sourcePath = (Resolve-Path -LiteralPath $Source).Path
$outputPath = [IO.Path]::GetFullPath($Output)
$bundlePath = Join-Path $sourcePath 'apps/desktop/dist/无限画布-win32-x64'
$version = $Tag.Substring(1)
$name = "InfiniteCanvas-$Tag-win-x64"
$zip = Join-Path $outputPath "$name-portable.zip"
$setup = Join-Path $outputPath "$name-setup.exe"
$hashes = Join-Path $outputPath 'SHA256SUMS.txt'

if (!(Test-Path -LiteralPath $Iscc -PathType Leaf)) { throw "Inno Setup compiler not found at $Iscc" }
foreach ($outputFile in @($zip, $setup, $hashes)) {
    if (Test-Path -LiteralPath $outputFile) { throw "Output already exists at $outputFile" }
}

Push-Location -LiteralPath $sourcePath
$oldVersion = $env:INFINITE_CANVAS_DESKTOP_VERSION
try {
    $env:INFINITE_CANVAS_DESKTOP_VERSION = $version
    pnpm install --frozen-lockfile
    pnpm build:desktop
} finally {
    $env:INFINITE_CANVAS_DESKTOP_VERSION = $oldVersion
    Pop-Location
}

$manifest = Get-Content -Raw -LiteralPath (Join-Path $bundlePath 'resources/app/package.json') | ConvertFrom-Json
if ($manifest.version -cne $version) { throw "Desktop app version is $($manifest.version), expected $version" }
if (Get-ChildItem -LiteralPath $bundlePath -Recurse -Force -Attributes ReparsePoint | Select-Object -First 1) {
    throw 'The desktop bundle contains a link and might not run after relocation.'
}
Copy-Item -LiteralPath (Join-Path $sourcePath 'LICENSE') -Destination (Join-Path $bundlePath 'LICENSE-InfiniteCanvas.txt')
@('无限画布 Windows x64', '', '请完整解压后双击“无限画布.exe”。移动或分享时请保留整个目录。', '工作区默认位于当前 Windows 用户目录下的 .infinite-canvas\workspace。') |
    Set-Content -LiteralPath (Join-Path $bundlePath '使用说明.txt') -Encoding utf8BOM

[void][IO.Directory]::CreateDirectory($outputPath)
[IO.Compression.ZipFile]::CreateFromDirectory($bundlePath, $zip, [IO.Compression.CompressionLevel]::Optimal, $false)
& $Iscc '/Qp' "/DReleaseVersion=$version" "/DReleaseOutput=$outputPath" "/DBundleDir=$bundlePath" (Join-Path $PSScriptRoot 'windows.iss')
Get-FileHash -Algorithm SHA256 -LiteralPath $zip,$setup | ForEach-Object {
    '{0}  {1}' -f $_.Hash.ToLowerInvariant(), (Split-Path -Leaf $_.Path)
} | Set-Content -LiteralPath $hashes -Encoding ascii
