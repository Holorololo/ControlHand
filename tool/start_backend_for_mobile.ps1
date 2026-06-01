param(
    [int]$Port = 5000,
    [int]$CameraIndex = 0,
    [string]$HostIp = "",
    [string]$DeviceId = "",
    [switch]$RunFlutter,
    [switch]$ShowWindows,
    [switch]$KeepBackendRunning
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

function Get-LanIPv4Addresses {
    $privatePattern = '^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)'

    try {
        $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object {
                $_.IPAddress -ne "127.0.0.1" -and
                $_.IPAddress -notlike "169.254*"
            } |
            Sort-Object InterfaceIndex, IPAddress |
            Select-Object -ExpandProperty IPAddress -Unique
    } catch {
        $ips = @()
    }

    $privateIps = @($ips | Where-Object { $_ -match $privatePattern })
    if ($privateIps.Count -gt 0) {
        return $privateIps
    }

    return @($ips)
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$pythonExe = Join-Path $projectRoot "venv\Scripts\python.exe"
$backendScript = Join-Path $projectRoot "lib\assets\proyectoauto\main.py"
$backendUrl = "http://127.0.0.1:$Port"
$backendMode = if ($ShowWindows) { "both" } else { "backend" }

if (-not (Test-Path $pythonExe)) {
    throw "No se encontro $pythonExe"
}

if (-not (Test-Path $backendScript)) {
    throw "No se encontro $backendScript"
}

$lanIps = @(Get-LanIPv4Addresses)
$selectedIp = $HostIp.Trim()

if (-not $selectedIp -and $lanIps.Count -gt 0) {
    $selectedIp = $lanIps[0]
}

$backendStartedHere = $false
$backendProcess = $null

try {
    if (-not (Test-BackendHealth -BaseUrl $backendUrl)) {
        Write-Host "Iniciando backend Flask en tu PC..."
        $backendProcess = Start-Process `
            -FilePath $pythonExe `
            -ArgumentList @(
                $backendScript,
                "--mode",
                $backendMode,
                "--input-source",
                "mobile",
                "--host",
                "0.0.0.0",
                "--port",
                "$Port",
                "--camera-index",
                "$CameraIndex",
                "--preview-width",
                "0",
                "--preview-quality",
                "90"
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

    Write-Host ""
    Write-Host "Backend listo." -ForegroundColor Green
    Write-Host "Local: http://127.0.0.1:$Port"

    if ($lanIps.Count -gt 0) {
        foreach ($ip in $lanIps) {
            Write-Host "LAN:   http://${ip}:$Port"
        }
    } else {
        Write-Warning "No se detecto una IP LAN automaticamente. Revisa 'ipconfig' si necesitas conectarte por Wi-Fi."
    }

    if ($selectedIp) {
        Write-Host ""
        Write-Host "En el celular usa:"
        Write-Host "Host: $selectedIp"
        Write-Host "Puerto: $Port"
        Write-Host ""
        Write-Host "Comando recomendado para abrir Flutter ya apuntando a tu PC:"
        Write-Host "flutter run -d android --dart-define=BACKEND_HOST=$selectedIp --dart-define=BACKEND_PORT=$Port"
    }

    Write-Host ""
    Write-Host "Si el celular no conecta, revisa Windows Firewall y permite el puerto $Port."

    if ($backendStartedHere -and $backendProcess) {
        Write-Host "PID backend: $($backendProcess.Id)"
        if (-not $RunFlutter) {
            Write-Host "Para detenerlo: Stop-Process -Id $($backendProcess.Id)"
        }
    }

    if ($RunFlutter) {
        $flutterArgs = @("run")
        if ($DeviceId) {
            $flutterArgs += @("-d", $DeviceId)
        }
        if ($selectedIp) {
            $flutterArgs += @(
                "--dart-define=BACKEND_HOST=$selectedIp",
                "--dart-define=BACKEND_PORT=$Port"
            )
        }

        Write-Host ""
        Write-Host "Lanzando Flutter..."

        Push-Location $projectRoot
        try {
            & flutter @flutterArgs
        } finally {
            Pop-Location
        }
    }
} finally {
    if ($RunFlutter -and $backendStartedHere -and $backendProcess -and -not $KeepBackendRunning) {
        Write-Host "Deteniendo backend Flask iniciado por el lanzador..."
        Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
    }
}
