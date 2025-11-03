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

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  OK Privileges administrateur confirmes" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

$global:reportLog = @()
$global:errorsFound = @()
$global:actionsPerformed = @()
$global:startTime = Get-Date

function Write-LogEntry {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "ACTION")][string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    $global:reportLog += $logEntry
    
    switch ($Type) {
        "SUCCESS" { Write-Host "OK $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "ERR $Message" -ForegroundColor Red; $global:errorsFound += $Message }
        "WARNING" { Write-Host "WARN $Message" -ForegroundColor Yellow }
        "ACTION" { Write-Host ">> $Message" -ForegroundColor Cyan }
        default { Write-Host "   $Message" -ForegroundColor Gray }
    }
}

function Get-UserConfirmation {
    param([string]$Message, [bool]$AutoMode = $false)
    if ($AutoMode) { return $true }
    Write-Host "`n$Message" -ForegroundColor Yellow
    $response = Read-Host "Continuer? (O/N)"
    return ($response -eq "O" -or $response -eq "o")
}

function Invoke-CommandSafely {
    param([scriptblock]$Command, [string]$Description = "Commande systeme")
    try {
        Write-LogEntry "Execution: $Description" "ACTION"
        $result = & $Command 2>&1
        Write-LogEntry "$Description - Succes" "SUCCESS"
        return $result
    }
    catch {
        Write-LogEntry "$Description - Erreur: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Clean-TemporaryFiles {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "NETTOYAGE FICHIERS TEMPORAIRES" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    $tempPaths = @(
        "C:\\Windows\\Temp\\*",
        "C:\\Users\\*\\AppData\\Local\\Temp\\*",
        "$env:TEMP\\*"
    )
    
    $totalFreed = 0
    foreach ($path in $tempPaths) {
        if (Test-Path -Path $path) {
            try {
                $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                $size = ($items | Measure-Object -Property Length -Sum).Sum
                
                if ($items -and $size -gt 0) {
                    Write-LogEntry "Suppression: $path" "ACTION"
                    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    $freedGB = [math]::Round($size / 1GB, 2)
                    $msg = "Espace libere: $freedGB GB"
                    Write-LogEntry $msg "SUCCESS"
                    $totalFreed += $size
                    $global:actionsPerformed += "Nettoyage: $freedGB GB"
                }
            }
            catch {
                Write-LogEntry "Impossible de nettoyer $path" "WARNING"
            }
        }
    }
}

function Clean-WindowsUpdate {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "VIDAGE CACHE WINDOWS UPDATE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    Write-LogEntry "Arret services Windows Update..." "ACTION"
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
    Write-LogEntry "Services arretes" "SUCCESS"
    
    Start-Sleep -Seconds 2
    
    $cacheDir = "C:\\Windows\\SoftwareDistribution\\Download"
    if (Test-Path $cacheDir) {
        $items = Get-ChildItem -Path $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
        $size = ($items | Measure-Object -Property Length -Sum).Sum
        Remove-Item -Path "$cacheDir\\*" -Recurse -Force -ErrorAction SilentlyContinue
        $freedGB = [math]::Round($size / 1GB, 2)
        Write-LogEntry "Cache Windows Update vide: $freedGB GB" "SUCCESS"
        $global:actionsPerformed += "Windows Update Cleanup: $freedGB GB"
    }
    
    Write-LogEntry "Redemarrage services..." "ACTION"
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Start-Service -Name bits -ErrorAction SilentlyContinue
    Write-LogEntry "Services redemarres" "SUCCESS"
}

function Clean-RecycleBin {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "VIDAGE CORBEILLE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    Write-LogEntry "Vidage de la corbeille..." "ACTION"
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
    Write-LogEntry "Corbeille videe" "SUCCESS"
    $global:actionsPerformed += "Corbeille videe"
}

function Clean-DiskCleanup {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "NETTOYAGE DISQUE (DISK CLEANUP)" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    Write-LogEntry "Lancement Disk Cleanup..." "ACTION"
    $diskCleanupPaths = @(
        "C:\\Windows\\Temp",
        "C:\\Windows\\Prefetch",
        "C:\\Windows\\System32\\dllcache",
        "C:\\ProgramData\\Package Cache"
    )
    
    foreach ($cleanPath in $diskCleanupPaths) {
        if (Test-Path $cleanPath) {
            try {
                $size = (Get-ChildItem -Path $cleanPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                if ($size -gt 0) {
                    Remove-Item -Path "$cleanPath\\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $freedGB = [math]::Round($size / 1GB, 2)
                    $msg = "Nettoyage $cleanPath - $freedGB GB"
                    Write-LogEntry $msg "SUCCESS"
                    $global:actionsPerformed += "Cleanup: $freedGB GB"
                }
            } catch {
                Write-LogEntry "Erreur nettoyage $cleanPath" "WARNING"
            }
        }
    }
}

function Repair-SystemFiles {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "REPARATION FICHIERS SYSTEME (SFC)" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    Write-LogEntry "Lancement SFC /scannow (peut prendre 15-30 min)..." "ACTION"
    Invoke-CommandSafely { & sfc /scannow } "System File Check Scan"
    $global:actionsPerformed += "SFC /scannow"
}

function Repair-WindowsImage {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "REPARATION IMAGE WINDOWS (DISM)" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    Write-LogEntry "Lancement DISM RestoreHealth..." "ACTION"
    Invoke-CommandSafely { & DISM /Online /Cleanup-Image /RestoreHealth } "DISM Restore Health"
    $global:actionsPerformed += "DISM Restore Health"
}

function Defragment-Drive {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "OPTIMISATION DISQUE" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Blue
    
    Write-LogEntry "Optimisation des lecteurs..." "ACTION"
    Get-Volume -DriveLetter C -ErrorAction SilentlyContinue | Optimize-Volume -Defrag -Verbose -ErrorAction SilentlyContinue
    Write-LogEntry "Optimisation terminee" "SUCCESS"
    $global:actionsPerformed += "Defragmentation"
}

function Clear-EventLogs {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "VIDAGE JOURNAUX D'EVENEMENTS" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Yellow
    
    $logs = @("System", "Application", "Security")
    foreach ($log in $logs) {
        Write-LogEntry "Vidage journal $log..." "ACTION"
        Clear-EventLog -LogName $log -ErrorAction SilentlyContinue
        Write-LogEntry "Journal $log vide" "SUCCESS"
    }
    $global:actionsPerformed += "Journaux vides"
}

function Generate-Report {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                        RAPPORT FINAL                          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $duration = (Get-Date) - $global:startTime
    
    Write-Host "Actions effectuees:" -ForegroundColor Green
    foreach ($action in $global:actionsPerformed) {
        Write-Host "  OK $action" -ForegroundColor Green
    }
    
    if ($global:errorsFound.Count -gt 0) {
        Write-Host "`nErreurs detectees:" -ForegroundColor Red
        foreach ($error in $global:errorsFound) {
            Write-Host "  ERR $error" -ForegroundColor Red
        }
    }
    
    Write-Host "`nDuree: $($duration.Minutes) min $($duration.Seconds) sec" -ForegroundColor Yellow
    Write-Host ""
}

function Show-Menu {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  MAINTENANCE SYSTEME                           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "NETTOYAGE:" -ForegroundColor Green
    Write-Host "  1. Fichiers temporaires"
    Write-Host "  2. Cache Windows Update"
    Write-Host "  3. Corbeille"
    Write-Host "  4. Disk Cleanup"
    Write-Host "  5. AUTO - Tous les nettoyages"
    
    Write-Host "`nREPARATION:" -ForegroundColor Magenta
    Write-Host "  6. SFC (Reparation fichiers)"
    Write-Host "  7. DISM (Reparation image)"
    Write-Host "  8. AUTO - Toutes les reparations"
    
    Write-Host "`nOPTIMISATION:" -ForegroundColor Blue
    Write-Host "  9. Defragmentation disque"
    Write-Host " 10. Journaux d'evenements"
    
    Write-Host "`nMODES:" -ForegroundColor Yellow
    Write-Host " 11. AUTO COMPLET (tout faire)"
    Write-Host "  0. Quitter"
    Write-Host ""
}

$continue = $true
while ($continue) {
    Show-Menu
    $choice = Read-Host "Choisissez une option"
    
    switch ($choice) {
        "1" { Clean-TemporaryFiles }
        "2" { Clean-WindowsUpdate }
        "3" { Clean-RecycleBin }
        "4" { Clean-DiskCleanup }
        "5" {
            Clean-TemporaryFiles
            Clean-WindowsUpdate
            Clean-RecycleBin
            Clean-DiskCleanup
        }
        "6" { Repair-SystemFiles }
        "7" { Repair-WindowsImage }
        "8" {
            Repair-SystemFiles
            Repair-WindowsImage
        }
        "9" { Defragment-Drive }
        "10" { Clear-EventLogs }
        "11" {
            Write-Host "`nMODE AUTO COMPLET - Toutes les operations" -ForegroundColor Yellow
            Clean-TemporaryFiles
            Clean-WindowsUpdate
            Clean-RecycleBin
            Clean-DiskCleanup
            Repair-SystemFiles
            Repair-WindowsImage
            Defragment-Drive
            Clear-EventLogs
        }
        "0" {
            $continue = $false
            Generate-Report
            Write-Host "Au revoir!" -ForegroundColor Green
        }
        default {
            Write-Host "Option invalide" -ForegroundColor Red
        }
    }
    
    if ($continue -and $choice -ne "0") {
        Read-Host "`nAppuyez sur Entree pour continuer"
    }
}
