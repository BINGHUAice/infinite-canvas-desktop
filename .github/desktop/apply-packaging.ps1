#Requires -Version 7.0
param(
    [Parameter(Mandatory)] [string] $Desktop,
    [Parameter(Mandatory)] [string] $Source
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
# This commit introduced the upstream desktop build that the patch is based on.
$base = 'd916904'
$patch = git -C $Desktop diff --binary $base HEAD -- apps/desktop/build.mjs
if (!$patch) { throw 'The desktop packaging patch is empty.' }
$patch | git -C $Source -c core.autocrlf=false apply --3way -
