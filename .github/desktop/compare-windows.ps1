param([Parameter(Mandatory)] [string] $Variant)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$upstream = Join-Path $env:GITHUB_WORKSPACE 'upstream'
$desktop = Join-Path $env:GITHUB_WORKSPACE 'desktop'
$buildScript = Join-Path $upstream 'apps/desktop/build.mjs'

if ($Variant -eq 'pnpm-invocation-only') {
    $script = [IO.File]::ReadAllText($buildScript) -replace '\r\n', "`n"
    $previous = $script
    $script = $script -replace '(?m)^    const (?:require|cliRequire|pnpm) = [^\n]+\n', ''
    $setup = [regex]::Match([IO.File]::ReadAllText((Join-Path $desktop 'apps/desktop/build.mjs')), '(?s)const pnpmPath = .*?(?=const pkg =)').Value
    if (!$setup -or $script -eq $previous -or !$script.Contains('pnpm.resolveInstalledBinary(), [')) { throw 'Could not apply the pnpm-only change' }
    $script = $script.Replace('const pkg =', $setup + 'const pkg =').Replace('pnpm.resolveInstalledBinary(), [', 'pnpmExecutable, [...pnpmArgs, ')
    [IO.File]::WriteAllText($buildScript, $script)
} elseif ($Variant -eq 'desktop-fixed') {
    & (Join-Path $PSScriptRoot 'apply-packaging.ps1') -Desktop $desktop -Source $upstream
}
Set-Location -LiteralPath $upstream
$env:INFINITE_CANVAS_DESKTOP_VERSION = '1.0.0'
"Node $(node --version), pnpm $(pnpm --version)"
pnpm install --frozen-lockfile
$PSNativeCommandUseErrorActionPreference = $false
$buildLog = Join-Path $env:RUNNER_TEMP 'desktop-comparison.log'
pnpm build:desktop *> $buildLog
$buildExit = $LASTEXITCODE
Get-Content -LiteralPath $buildLog -Tail 45
$PSNativeCommandUseErrorActionPreference = $true
"$Variant packaging exit: $buildExit" >> $env:GITHUB_STEP_SUMMARY
if ($buildExit -ne 0) {
    $match = Select-String -LiteralPath $buildLog -Pattern 'Cannot find module|ERR_|Error:' | Select-Object -First 1
    if ($match) { ("`n    " + $match.Line) >> $env:GITHUB_STEP_SUMMARY }
    if ($Variant -eq 'desktop-fixed') { throw 'The control build failed' }
    return
}
$bundle = Join-Path $upstream 'apps/desktop/dist/无限画布-win32-x64'
$express = Get-Item -Force -LiteralPath (Join-Path $bundle 'resources/app/cli/node_modules/express') -ErrorAction SilentlyContinue
if ($express) {
    $kind = if ($express.LinkType) { $express.LinkType } else { 'regular directory' }
    $exists = Test-Path -LiteralPath (Join-Path $express.FullName 'package.json')
    $layout = "express is a $kind. Its package.json is readable: $exists"
    $layout
    $layout >> $env:GITHUB_STEP_SUMMARY
}
$env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
$env:ELECTRON_RUN_AS_NODE = '1'
Remove-Item Env:NODE_PATH -ErrorAction SilentlyContinue
$executable = Join-Path $bundle '无限画布.exe'
$cli = Join-Path $bundle 'resources/app/cli/dist/index.js'
$process = Start-Process -FilePath $executable -ArgumentList @("`"$cli`"", '--help') -WorkingDirectory $bundle -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput (Join-Path $env:RUNNER_TEMP 'cli-out.txt') -RedirectStandardError (Join-Path $env:RUNNER_TEMP 'cli-err.txt')
$cliExit = $process.ExitCode
Get-Content -LiteralPath (Join-Path $env:RUNNER_TEMP 'cli-out.txt'), (Join-Path $env:RUNNER_TEMP 'cli-err.txt')
"Bundled CLI exit: $cliExit" >> $env:GITHUB_STEP_SUMMARY
$failure = Select-String -LiteralPath (Join-Path $env:RUNNER_TEMP 'cli-err.txt') -Pattern '^Error' | Select-Object -First 1
if ($failure) { ("`n    " + $failure.Line) >> $env:GITHUB_STEP_SUMMARY }
if ($Variant -eq 'desktop-fixed' -and $cliExit -ne 0) { throw 'The control bundle failed at startup' }
