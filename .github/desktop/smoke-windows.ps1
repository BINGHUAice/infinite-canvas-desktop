#Requires -Version 7.0
param(
    [Parameter(Mandatory)] [string] $Artifacts,
    [Parameter(Mandatory)] [ValidatePattern('^v[0-9]+\.[0-9]+\.[0-9]+$')] [string] $Tag
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$artifactPath = (Resolve-Path -LiteralPath $Artifacts).Path
$name = "InfiniteCanvas-$Tag-win-x64"
$testRoot = [IO.Directory]::CreateTempSubdirectory('infinite-canvas-smoke-').FullName
$portablePath = Join-Path $testRoot 'portable'
$installPath = Join-Path $testRoot 'installed'
$installer = Join-Path $artifactPath "$name-setup.exe"
$registryKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\InfiniteCanvasDesktop_is1'
if (Test-Path -LiteralPath $registryKey) { throw 'Run installer validation under a Windows user without an existing Infinite Canvas installation.' }

function Test-Workbench([string] $appPath) {
    $profilePath = Join-Path $appPath 'smoke-profile'
    $electronPath = Join-Path $profilePath 'electron'
    [void][IO.Directory]::CreateDirectory($electronPath)
    $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $debugListener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
    $listener.Start()
    $debugListener.Start()
    $port = $listener.LocalEndpoint.Port
    $debugPort = $debugListener.LocalEndpoint.Port
    $listener.Stop()
    $debugListener.Stop()
    $app = [Diagnostics.ProcessStartInfo]::new((Join-Path $appPath '无限画布.exe'))
    $app.UseShellExecute = $false
    $app.WorkingDirectory = $appPath
    $app.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $app.Environment['USERPROFILE'] = $profilePath
    $app.Environment['PATH'] = "$env:SystemRoot\System32;$env:SystemRoot"
    foreach ($key in @('NODE_PATH','NODE_OPTIONS','ELECTRON_RUN_AS_NODE','PNPM_HOME')) { [void]$app.Environment.Remove($key) }
    foreach ($argument in @("--user-data-dir=$electronPath", "--remote-debugging-port=$debugPort", '--remote-debugging-address=127.0.0.1', '--port', "$port")) { $app.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::Start($app)
    try {
        node (Join-Path $PSScriptRoot 'probe-renderer.cjs') $debugPort $port
        if (!(Test-Path -LiteralPath (Join-Path $profilePath '.infinite-canvas/workspace/.canvas.url'))) {
            throw "No workspace was initialized by $appPath"
        }
        Write-Output "Started workbench from $appPath"
    } finally {
        if (!$process.HasExited -and (!$process.CloseMainWindow() -or !$process.WaitForExit(5000))) {
            $process.Kill($true)
            $process.WaitForExit()
        }
        $process.Dispose()
    }
}

[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $artifactPath "$name-portable.zip"), $portablePath)
Test-Workbench $portablePath
try {
    $setup = Start-Process -FilePath $installer -ArgumentList @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/NOICONS', "/DIR=`"$installPath`"") -WindowStyle Hidden -PassThru -Wait
    if ($setup.ExitCode -ne 0) { throw "Installer exited $($setup.ExitCode)" }
    $actualVersion = (Get-ItemProperty -LiteralPath $registryKey).DisplayVersion
    if ($actualVersion -ne $Tag.Substring(1)) { throw "Unexpected installed version $actualVersion" }
    Test-Workbench $installPath
} finally {
    $uninstaller = Join-Path $installPath 'unins000.exe'
    if (Test-Path -LiteralPath $uninstaller) {
        $uninstall = Start-Process -FilePath $uninstaller -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART' -WindowStyle Hidden -PassThru -Wait
        if ($uninstall.ExitCode -ne 0) { throw "Uninstaller exited $($uninstall.ExitCode)" }
    }
}
