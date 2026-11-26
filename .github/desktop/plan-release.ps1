#Requires -Version 7.0
param([string] $Tag, [switch] $Publish)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$upstream = 'basketikun/infinite-canvas'
$versionPattern = '^v[0-9]+\.[0-9]+\.[0-9]+$'
$published = @()
if ($Publish) {
    $published = @(gh api --paginate "repos/$env:GITHUB_REPOSITORY/releases?per_page=100" --jq '.[] | select(.draft == false) | .tag_name')
}
if ($Tag) {
    if ($Tag -cnotmatch $versionPattern) { throw "Expected an upstream version tag such as v1.0.0, got $Tag" }
    $release = gh api "repos/$upstream/releases/tags/$Tag" | ConvertFrom-Json
    if ($release.draft -or $release.prerelease) { throw "$Tag is not a stable upstream Release" }
    if ($Tag -cin $published) { return }
} else {
    $releases = @(gh api --paginate "repos/$upstream/releases?per_page=100" --jq '.[] | select(.draft == false and .prerelease == false) | .tag_name' |
        Where-Object { $_ -cmatch $versionPattern -and [version]$_.Substring(1) -ge [version]'1.0.0' -and $_ -cnotin $published })
    if (!$releases.Count) { return }
    $Tag = $releases | Sort-Object { [version]$_.Substring(1) } | Select-Object -First 1
}
$commit = gh api "repos/$upstream/commits/$Tag" --jq '.sha'
if ($commit -cnotmatch '^[0-9a-f]{40}$') { throw "Invalid upstream commit for $Tag" }
@("tag=$Tag", "commit=$commit") >> $env:GITHUB_OUTPUT
Write-Output "$Tag at $commit"
