#Requires -Version 7.0
param([Parameter(Mandatory)] [string] $Source)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$base = 'd916904c13664d4492c85a2c28f3b4f137187d16'
$target = 'apps/desktop/build.mjs'
$patch = Join-Path $PSScriptRoot 'windows-packaging.patch'

# Later releases are checked out shallowly. Fetch the patch base for three-way application.
if ((git -C $Source rev-parse HEAD) -cne $base) {
    git -C $Source fetch --no-tags --depth=1 origin $base
}
git -C $Source apply --cached --3way $patch
git -C $Source checkout-index -f -- $target
