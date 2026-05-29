<#
.SYNOPSIS
Zoro-Zero: Pre-Flight Hardware Detection and Launch Script

.DESCRIPTION
This script acts as the primary turnkey entrypoint for the Zoro-Zero agent stack. 
It performs critical pre-flight dependency checks to ensure Docker Desktop is running. 
It then dynamically probes the host system for an NVIDIA GPU via `nvidia-smi`.
Based on the hardware detected, it securely boots the Docker Compose stack using 
either the CPU-only baseline or the GPU-accelerated override profile.

.LICENSE
MIT License (https://opensource.org/license/mit)

.AUTHOR
Team-404, Michelle Stonecastle-20260527: v1.0.0

.NOTES
REMEDIATIONS: If the script fails to detect the Docker daemon, it will pause
and explicitly guide the student to launch Docker Desktop.
#>

# --- CONSTANTS ---
$ErrorActionPreference = "Stop"

# --- FUNCTIONS ---
function Write-Header {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "      Zoro-Zero: Turnkey Local Agent Stack Deployment      " -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Dependencies {
    Write-Host "[*] Phase 1: Validating System Dependencies..." -ForegroundColor Cyan

    # Check if Docker CLI is installed
    if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Host "[!] FATAL: Docker command not found." -ForegroundColor Red
        Write-Host "    Please ensure Docker Desktop is installed and added to your system PATH." -ForegroundColor Yellow
        Write-Host "    Download: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
        Exit
    }

    # Check if Docker Daemon is running
    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[!] FATAL: Docker Daemon is not running." -ForegroundColor Red
        Write-Host "    Please open the Docker Desktop application and wait for the engine to start." -ForegroundColor Yellow
        Write-Host "    Once the Docker icon in your system tray is green, run this script again." -ForegroundColor Yellow
        Exit
    } else {
        Write-Host "  -> Docker Daemon is online." -ForegroundColor Green
    }
}

function Test-Hardware {
    Write-Host ""
    Write-Host "[*] Phase 2: Probing Hardware Capabilities..." -ForegroundColor Cyan
    
    # Probe for NVIDIA GPU
    if (Get-Command "nvidia-smi" -ErrorAction SilentlyContinue) {
        $null = nvidia-smi 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  -> Hardware Detected: NVIDIA GPU found. Hardware acceleration enabled." -ForegroundColor Green
            return $true
        }
    }
    
    Write-Host "  -> Hardware Detected: Standard CPU. Deploying in CPU-only mode." -ForegroundColor Yellow
    Write-Host "     (Note: If you have an NVIDIA GPU, ensure drivers and the NVIDIA Container Toolkit are installed.)" -ForegroundColor Gray
    return $false
}

function Start-Stack {
    param([bool]$HasGPU)

    Write-Host ""
    Write-Host "[*] Phase 3: Orchestrating Container Launch..." -ForegroundColor Cyan

    if ($HasGPU) {
        Write-Host "  -> Applying GPU override profile (docker-compose.gpu.yml)..." -ForegroundColor Magenta
        docker compose -f docker-compose.yml -f docker-compose.gpu.yml up -d
    } else {
        Write-Host "  -> Applying default CPU profile (docker-compose.yml)..." -ForegroundColor Magenta
        docker compose -f docker-compose.yml up -d
    }

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " [SUCCESS] Zoro-Zero stack initialization sequence dispatched." -ForegroundColor Green
    Write-Host " -> PLEASE NOTE: The model compiler (zoro-ollama-init) will take several minutes to finish." -ForegroundColor Yellow
    Write-Host "    If you are worried it is stuck, open Docker Desktop, click on the 'zoro-zero' stack," -ForegroundColor Gray
    Write-Host "    then click the 'zoro-ollama-init' container and view the 'Logs' tab." -ForegroundColor Gray
    Write-Host "    You will see it 'transferring' or 'writing layer'. When complete, it says 'success'." -ForegroundColor Gray
    Write-Host " -> Access Dashboard: http://127.0.0.1:9119" -ForegroundColor Gray
    Write-Host " -> Access Console:   docker exec -it zoro-gateway hermes chat" -ForegroundColor Gray
    Write-Host "================================================================" -ForegroundColor Cyan
}

# --- EXECUTION BLOCK ---
Write-Header
Test-Dependencies
$gpuDetected = Test-Hardware
Start-Stack -HasGPU $gpuDetected
