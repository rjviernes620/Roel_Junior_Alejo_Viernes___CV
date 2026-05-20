$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = (Resolve-Path (Join-Path $scriptRoot '..')).ProviderPath
$destinationRoot = "G:\My Drive\Complete CV's"

$cvDirs = Get-ChildItem -Path $workspaceRoot -Directory | Where-Object {
    $_.Name -ne '.vscode' -and $_.Name -ne '.git'
}

function Get-MainTexFiles {
    param([string]$dirPath)
    Get-ChildItem -Path $dirPath -Filter '*.tex' -File | Where-Object {
        $_.Name -notmatch '^page(1|2)sidebar\.tex$'
    }
}

function Build-And-CopyDirectory {
    param([string]$dirPath)

    $texFiles = Get-MainTexFiles -dirPath $dirPath
    if (-not $texFiles) {
        Write-Host "No main .tex files found in $dirPath"
        return
    }

    foreach ($texFile in $texFiles) {
        $pdfName = [System.IO.Path]::ChangeExtension($texFile.Name, 'pdf')
        $pdfPath = Join-Path $dirPath $pdfName
        $destPath = Join-Path $destinationRoot $pdfName

        Write-Host "Building $texFile in $projectName..."
        Set-Location $dirPath
        latexmk -pdf -interaction=nonstopmode $texFile.Name
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and (Test-Path $pdfPath)) {
            Copy-Item -LiteralPath $pdfPath -Destination $destPath -Force
            Write-Host "Built $pdfName and copied to $destPath"
        } else {
            Write-Host "Build failed for $texFile in $projectName (exit code $exitCode)"
        }
    }
}

function Build-AllDirectories {
    foreach ($dir in $cvDirs) {
        Build-And-CopyDirectory -dirPath $dir.FullName
    }
}

$pendingDirs = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$timer = New-Object System.Timers.Timer 1000
$timer.AutoReset = $false

$timer.Add_Elapsed({
    $dirsToBuild = $pendingDirs.ToArray()
    $pendingDirs.Clear()
    foreach ($dir in $dirsToBuild) {
        Build-And-CopyDirectory -dirPath $dir
    }
})

$watchers = @()
foreach ($dir in $cvDirs) {
    $watcher = New-Object System.IO.FileSystemWatcher $dir.FullName, '*.tex'
    $watcher.IncludeSubdirectories = $false
    $watcher.NotifyFilter = [System.IO.NotifyFilters]'LastWrite'

    Register-ObjectEvent $watcher Changed -Action {
        $changedDir = Split-Path -Parent $Event.SourceEventArgs.FullPath
        $pendingDirs.Add($changedDir) | Out-Null
        if ($timer.Enabled) { $timer.Stop() }
        $timer.Start()
    } | Out-Null

    $watcher.EnableRaisingEvents = $true
    $watchers += $watcher
}

New-Item -ItemType Directory -Force -Path $destinationRoot | Out-Null
Write-Host "Initial build for all CV folders..."
Build-AllDirectories
Write-Host "Watching CV directories for .tex changes. Copies go to $destinationRoot"
Write-Host "Press Ctrl+C to stop."

while ($true) {
    Start-Sleep -Seconds 1
}
