# External Tools - Activation & Tweaks

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

function Require-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    
    if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Ce script nécessite les droits administrateur. Redémarrage..." -ForegroundColor Red
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

Require-Admin

$global:logReport = @()
$global:startTime = Get-Date

function Write-Log-Entry {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "ACTION")][string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    $global:logReport += $logEntry
    
    switch ($Type) {
        "SUCCESS" { Write-Host "OK $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "ERR $Message" -ForegroundColor Red }
        "WARNING" { Write-Host "WARN $Message" -ForegroundColor Yellow }
        "ACTION" { Write-Host ">> $Message" -ForegroundColor Cyan }
        default { Write-Host "   $Message" -ForegroundColor Gray }
    }
}

function Launch-Mass-Grave {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "MASS GRAVE ACTIVATION" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Red
    
    Write-Log-Entry "Lancement MASS GRAVE ACTIVATION..." "ACTION"
    Write-Host "La fenêtre d'activation s'ouvrira dans quelques secondes..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    Start-Process powershell.exe -ArgumentList "irm https://get.activated.win | iex" -Verb RunAs
    Write-Log-Entry "MASS GRAVE lancé" "SUCCESS"
}

function Launch-Win-Util {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "WINUTIL" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    Write-Log-Entry "Lancement WinUtil..." "ACTION"
    Write-Host "L'interface WinUtil s'ouvrira dans quelques secondes..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    Start-Process powershell.exe -ArgumentList "irm https://christitus.com/win | iex" -Verb RunAs
    Write-Log-Entry "WinUtil lancé" "SUCCESS"
}

function Show-Main-Menu {
    Clear-Host
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                   EXTERNAL TOOLS v2.2                          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "┌─ ACTIVATION ────────────────────────────────────────────────────┐" -ForegroundColor Red
    Write-Host "│  1. MASS GRAVE ACTIVATION      - Activation Windows            │" -ForegroundColor Red
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Red
    
    Write-Host "`n┌─ TWEAKS ────────────────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "│  2. WinUtil                    - Suite d'optimisation          │" -ForegroundColor Magenta
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Magenta
    
    Write-Host "`n┌─ NAVIGATION ────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│  0. Retour au menu principal                                   │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    
    $choice = Read-Host "`nChoisissez une option (0-2)"
    return $choice
}

function Generate-Report {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                       RAPPORT FINAL                           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $duration = (Get-Date) - $global:startTime
    Write-Host "Durée: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Yellow
}

$continue = $true
while ($continue) {
    $choice = Show-Main-Menu
    
    switch ($choice) {
        "1" { Launch-Mass-Grave }
        "2" { Launch-Win-Util }
        "0" {
            $continue = $false
            Generate-Report
            Write-Host "`nRetour au launcher...`n" -ForegroundColor Green
        }
        default {
            Write-Host "Option invalide" -ForegroundColor Red
        }
    }
    
    if ($continue -and $choice -ne "0") {
        Read-Host "`nAppuyez ENTREE pour continuer"
    }
}