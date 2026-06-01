param(
    [string]$DeviceId = "",
    [switch]$KeepBackendRunning
)

$ErrorActionPreference = "Stop"
$backendPort = 5000

function Test-BackendHealth {
    param(
        [string]$BaseUrl
    )

    try {
        $response = Invoke-WebRequest -Uri "$BaseUrl/health" -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Wait-ForBackend {
    param(
        [string]$BaseUrl,
        [int]$TimeoutSeconds = 20
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-BackendHealth -BaseUrl $BaseUrl) {
            return $true
        }
        Start-Sleep -Milliseconds 500
    }

    return $false
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$pythonExe = Join-Path $projectRoot "venv\Scripts\python.exe"
$backendScript = Join-Path $projectRoot "backend\backend.py"
$adbExe = Join-Path $env:LOCALAPPDATA "Android\sdk\platform-tools\adb.exe"
$backendUrl = "http://127.0.0.1:$backendPort"

if (-not (Test-Path $pythonExe)) {
    throw "No se encontro $pythonExe"
}

if (-not (Test-Path $backendScript)) {
    throw "No se encontro $backendScript"
}

if (-not (Test-Path $adbExe)) {
    throw "No se encontro adb en $adbExe"
}

$backendStartedHere = $false
$backendProcess = $null

try {
    if (-not (Test-BackendHealth -BaseUrl $backendUrl)) {
        Write-Host "Iniciando backend Flask local..."
        $backendProcess = Start-Process `
            -FilePath $pythonExe `
            -ArgumentList @(
                $backendScript,
                "--mode",
                "backend",
                "--input-source",
                "mobile",
                "--host",
                "0.0.0.0",
                "--port",
                "$backendPort",
                "--preview-width",
                "480",
                "--preview-quality",
                "65",
                "--processing-width",
                "640"
            ) `
            -WorkingDirectory $projectRoot `
            -PassThru `
            -WindowStyle Hidden

        $backendStartedHere = $true

        if (-not (Wait-ForBackend -BaseUrl $backendUrl)) {
            throw "El backend no respondio en $backendUrl/health a tiempo."
        }
    } else {
        Write-Host "Ya existe un backend Flask local en $backendUrl"
    }

    $adbArgs = @()
    if ($DeviceId) {
        $adbArgs += @("-s", $DeviceId)
    }
    $adbArgs += @("reverse", "tcp:$backendPort", "tcp:$backendPort")

    Write-Host "Configurando adb reverse tcp:$backendPort -> tcp:$backendPort..."
    & $adbExe @adbArgs

    Push-Location $projectRoot
    try {
        if ($DeviceId) {
            flutter run -d $DeviceId
        } else {
            flutter run
        }
    } finally {
        Pop-Location
    }
} finally {
    if ($backendStartedHere -and $backendProcess -and -not $KeepBackendRunning) {
        Write-Host "Deteniendo backend Flask iniciado por el lanzador..."
        Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
    }
}
