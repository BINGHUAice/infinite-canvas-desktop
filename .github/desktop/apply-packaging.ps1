#Requires -Version 7.0
param(
    [Parameter(Mandatory)] [string] $Desktop,
    [Parameter(Mandatory)] [string] $Source
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
# This commit introduced the upstream desktop build that the patch is based on.
$base = 'd916904'
$patchFile = [IO.Path]::GetTempFileName()
try {
    git -C $Desktop diff "--output=$patchFile" --binary $base HEAD -- apps/desktop/build.mjs
    if (!(Get-Item -LiteralPath $patchFile).Length) { throw 'The desktop packaging patch is empty.' }
    git -C $Source apply --cached --3way $patchFile
    git -C $Source checkout-index -f -- apps/desktop/build.mjs
} finally {
    Remove-Item -LiteralPath $patchFile
}
