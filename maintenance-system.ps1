# ============================================================================
# SCRIPT MAINTENANCE SYSTÈME - VERSION COMPLÈTE AVEC MENU AVANCÉ
# À copier/coller directement dans PowerShell (admin)
# ============================================================================

&{
# Vérification privilèges administrateur
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ Ce script nécessite les privilèges administrateur." -ForegroundColor Red
    Write-Host "Relancez PowerShell en tant qu'administrateur." -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée pour fermer"
    exit 1
}

# ============================================================================
# VARIABLES GLOBALES
# ============================================================================
$global:reportLog = @()
$global:errorsFound = @()
$global:actionsPerformed = @()
$global:startTime = Get-Date

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

function Write-LogEntry {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "ACTION")][string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    $global:reportLog += $logEntry
    
    switch ($Type) {
        "SUCCESS" { Write-Host "✓ $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "✗ $Message" -ForegroundColor Red; $global:errorsFound += $Message }
        "WARNING" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
        "ACTION" { Write-Host "→ $Message" -ForegroundColor Cyan }
        default { Write-Host "ℹ $Message" -ForegroundColor Gray }
    }
}

function Get-UserConfirmation {
    param([string]$Message)
    Write-Host "`n⚠️  $Message" -ForegroundColor Yellow
    $response = Read-Host "Continuer? (O/N)"
    return ($response -eq "O" -or $response -eq "o")
}

function Invoke-CommandSafely {
    param([scriptblock]$Command, [string]$Description = "Commande système")
    try {
        Write-LogEntry "Exécution: $Description" "ACTION"
        $result = & $Command
        Write-LogEntry "$Description - Succès" "SUCCESS"
        return $result
    }
    catch {
        Write-LogEntry "$Description - Erreur: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# ============================================================================
# SECTION 1 : DIAGNOSTICS
# ============================================================================

function Diagnose-DiskHealth {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "📊 DIAGNOSTIC DISQUE DUR" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    Write-LogEntry "Vérification état SMART des disques..." "INFO"
    try {
        $smartInfo = Get-WmiObject -Namespace root\wmi -Class MSStorageDriver_FailurePredictStatus 2>$null
        foreach ($disk in $smartInfo) {
            if ($disk.PredictFailure) {
                Write-LogEntry "⚠️  Disque $($disk.Name): Défaillance prédite!" "WARNING"
            } else {
                Write-LogEntry "Disque $($disk.Name): État normal" "SUCCESS"
            }
        }
    }
    catch {
        Write-LogEntry "SMART: Impossible de vérifier (peut nécessiter des pilotes)" "WARNING"
    }
    
    Write-LogEntry "Analyse espace disque..." "INFO"
    $drives = Get-Volume | Where-Object {$_.FileSystemLabel -ne ""}
    foreach ($drive in $drives) {
        $sizeGB = [math]::Round($drive.Size / 1GB, 2)
        $freeGB = [math]::Round($drive.SizeRemaining / 1GB, 2)
        $percentUsed = [math]::Round(($drive.Size - $drive.SizeRemaining) / $drive.Size * 100, 1)
        
        if ($percentUsed -gt 90) {
            Write-LogEntry "$($drive.DriveLetter): $freeGB/$sizeGB GB libres ($percentUsed% utilisé)" "WARNING"
        } else {
            Write-LogEntry "$($drive.DriveLetter): $freeGB/$sizeGB GB libres ($percentUsed% utilisé)" "SUCCESS"
        }
    }
}

function Diagnose-WindowsHealth {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "🔧 DIAGNOSTIC INTÉGRITÉ WINDOWS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    Write-LogEntry "Vérification services critiques..." "INFO"
    $criticalServices = @("WinDefend", "Winlogon", "PlugPlay", "BITS", "wuauserv")
    foreach ($service in $criticalServices) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -eq "Running") {
                Write-LogEntry "Service $service`: En cours d'exécution" "SUCCESS"
            } else {
                Write-LogEntry "Service $service`: Arrêté - Attention!" "WARNING"
            }
        }
    }
}

function Diagnose-MemoryHealth {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "💾 DIAGNOSTIC MÉMOIRE" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    $memInfo = Get-CimInstance -Class Win32_ComputerSystem
    $totalMemGB = [math]::Round($memInfo.TotalPhysicalMemory / 1GB, 2)
    Write-LogEntry "Mémoire totale: $totalMemGB GB" "INFO"
    
    $os = Get-CimInstance -Class Win32_OperatingSystem
    $freeMemGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedPercent = [math]::Round((1 - ($os.FreePhysicalMemory / $memInfo.TotalPhysicalMemory)) * 100, 1)
    
    Write-LogEntry "Mémoire libre: $freeMemGB GB / Utilisée: $usedPercent%" "INFO"
    
    if ($usedPercent -gt 90) {
        Write-LogEntry "⚠️  Utilisation mémoire critique!" "WARNING"
    }
}

# ============================================================================
# SECTION 2 : RÉPARATIONS
# ============================================================================

function Repair-WindowsImage {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "🔨 RÉPARATION IMAGE WINDOWS (DISM)" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    if (Get-UserConfirmation "Exécuter DISM /Online /Cleanup-Image /RestoreHealth?") {
        Invoke-CommandSafely { & DISM /Online /Cleanup-Image /RestoreHealth } "DISM Image Health Restore"
        $global:actionsPerformed += "DISM Restore Health"
    }
}

function Repair-SystemFiles {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "🔨 RÉPARATION FICHIERS SYSTÈME (SFC)" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    if (Get-UserConfirmation "Exécuter SFC /scannow (⚠️  Peut prendre 15-30 minutes)?") {
        Write-LogEntry "Lancement SFC /scannow - Veuillez patienter..." "ACTION"
        Invoke-CommandSafely { & sfc /scannow } "System File Check Scan"
        $global:actionsPerformed += "SFC /scannow"
    }
}

# ============================================================================
# SECTION 3 : NETTOYAGE
# ============================================================================

function Clean-TemporaryFiles {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "🧹 NETTOYAGE FICHIERS TEMPORAIRES" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    $tempPaths = @(
        "C:\Windows\Temp\*",
        "C:\Users\*\AppData\Local\Temp\*",
        "$env:TEMP\*"
    )
    
    $totalFreed = 0
    
    foreach ($path in $tempPaths) {
        if (Test-Path -Path $path) {
            try {
                $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                $size = ($items | Measure-Object -Property Length -Sum).Sum
                
                if ($items) {
                    Write-LogEntry "Suppression des fichiers temporaires: $path" "ACTION"
                    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    $freedGB = [math]::Round($size / 1GB, 2)
                    Write-LogEntry "Espace libéré: $freedGB GB" "SUCCESS"
                    $totalFreed += $size
                    $global:actionsPerformed += "Nettoyage: $path"
                }
            }
            catch {
                Write-LogEntry "Impossible de nettoyer $path - Fichiers verrouillés" "WARNING"
            }
        }
    }
    
    $totalFreedGB = [math]::Round($totalFreed / 1GB, 2)
    Write-LogEntry "Total espace libéré: $totalFreedGB GB" "SUCCESS"
}

# ============================================================================
# SECTION 4 : VIDAGE WINDOWS UPDATE (NOUVEAU)
# ============================================================================

function Clean-WindowsUpdate {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "🧹 VIDAGE DU CACHE WINDOWS UPDATE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    if (Get-UserConfirmation "Cela va arrêter les services Windows Update et vider le cache. Continuer?") {
        
        Write-LogEntry "Arrêt des services..." "ACTION"
        try {
            Stop-Service -Name wuauserv -Force -ErrorAction Stop
            Write-LogEntry "Service wuauserv arrêté" "SUCCESS"
        }
        catch {
            Write-LogEntry "Impossible d'arrêter wuauserv: $_" "ERROR"
        }
        
        try {
            Stop-Service -Name bits -Force -ErrorAction Stop
            Write-LogEntry "Service BITS arrêté" "SUCCESS"
        }
        catch {
            Write-LogEntry "Impossible d'arrêter BITS: $_" "ERROR"
        }
        
        # Donner du temps aux services pour s'arrêter
        Start-Sleep -Seconds 2
        
        Write-LogEntry "Suppression des fichiers en cache..." "ACTION"
        
        $cacheDirectory = "C:\Windows\SoftwareDistribution"
        
        if (Test-Path -Path "$cacheDirectory\Download") {
            try {
                $downloadDir = Get-ChildItem -Path "$cacheDirectory\Download" -Recurse -Force -ErrorAction SilentlyContinue
                $cacheSize = ($downloadDir | Measure-Object -Property Length -Sum).Sum
                
                Remove-Item -Path "$cacheDirectory\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
                
                $freedGB = [math]::Round($cacheSize / 1GB, 2)
                Write-LogEntry "Dossier Download vidé - Espace libéré: $freedGB GB" "SUCCESS"
                $global:actionsPerformed += "Windows Update Cache Cleanup: $freedGB GB"
            }
            catch {
                Write-LogEntry "Erreur lors du nettoyage du cache: $_" "ERROR"
            }
        }
        
        Write-LogEntry "Redémarrage des services..." "ACTION"
        
        try {
            Start-Service -Name wuauserv -ErrorAction Stop
            Write-LogEntry "Service wuauserv redémarré" "SUCCESS"
        }
        catch {
            Write-LogEntry "Impossible de redémarrer wuauserv: $_" "ERROR"
        }
        
        try {
            Start-Service -Name bits -ErrorAction Stop
            Write-LogEntry "Service BITS redémarré" "SUCCESS"
        }
        catch {
            Write-LogEntry "Impossible de redémarrer BITS: $_" "ERROR"
        }
        
        Write-LogEntry "Vidage Windows Update terminé" "SUCCESS"
    }
}

function Clean-OldWindowsFiles {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "🧹 NETTOYAGE FICHIERS WINDOWS ANCIENS" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    if (Get-UserConfirmation "Nettoyer les fichiers Windows.old (anciennes installations)?") {
        Invoke-CommandSafely { & Disk Cleanup /sageset:1; & Disk Cleanup /sagerun:1 } "Disk Cleanup Utility"
        $global:actionsPerformed += "Disk Cleanup - Old Windows Files"
    }
}

# ============================================================================
# RAPPORT FINAL
# ============================================================================

function Generate-FinalReport {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║             RAPPORT DE MAINTENANCE SYSTÈME                     ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $endTime = Get-Date
    $duration = $endTime - $global:startTime
    
    Write-Host "`n📋 RÉSUMÉ EXÉCUTION" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "Début: $($global:startTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "Fin: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Host "Durée: $([math]::Round($duration.TotalMinutes, 2)) minutes`n"
    
    if ($global:actionsPerformed.Count -gt 0) {
        Write-Host "✓ ACTIONS EFFECTUÉES ($($global:actionsPerformed.Count))" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        foreach ($action in $global:actionsPerformed) {
            Write-Host "  • $action"
        }
        Write-Host ""
    }
    
    if ($global:errorsFound.Count -gt 0) {
        Write-Host "❌ PROBLÈMES DÉTECTÉS ($($global:errorsFound.Count))" -ForegroundColor Red
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
        foreach ($error in $global:errorsFound) {
            Write-Host "  • $error"
        }
        Write-Host ""
    }
    
    $reportPath = "$env:USERPROFILE\Desktop\SysReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $global:reportLog | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "📄 Rapport exporté: $reportPath`n" -ForegroundColor Cyan
}

# ============================================================================
# MENU PRINCIPAL
# ============================================================================

function Show-MainMenu {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     MAINTENANCE SYSTÈME - DIAGNOSTIC, RÉPARATION, NETTOYAGE    ║" -ForegroundColor Cyan
    Write-Host "║              (Administrateur - Mode Interactif)                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "📊 DIAGNOSTICS" -ForegroundColor Cyan
    Write-Host "  1. Diagnostic disque dur"
    Write-Host "  2. Diagnostic intégrité Windows"
    Write-Host "  3. Diagnostic mémoire"
    Write-Host "  4. Tous les diagnostics`n"
    
    Write-Host "🔨 RÉPARATIONS" -ForegroundColor Magenta
    Write-Host "  5. Réparation image Windows (DISM)"
    Write-Host "  6. Réparation fichiers système (SFC)"
    Write-Host "  7. Toutes les réparations`n"
    
    Write-Host "🧹 NETTOYAGE" -ForegroundColor Green
    Write-Host "  8. Nettoyage fichiers temporaires"
    Write-Host "  9. Vidage cache Windows Update (NOUVEAU)"
    Write-Host "  10. Nettoyage fichiers Windows anciens"
    Write-Host "  11. Nettoyage complet`n"
    
    Write-Host "📋 MAINTENANCE COMPLÈTE" -ForegroundColor Blue
    Write-Host "  99. Diagnostic + Réparation + Nettoyage (Mode expert)`n"
    
    Write-Host "  0. Quitter et générer rapport`n"
}

function Main {
    do {
        Show-MainMenu
        $choice = Read-Host "Sélectionnez une option"
        
        switch ($choice) {
            "1" { Diagnose-DiskHealth }
            "2" { Diagnose-WindowsHealth }
            "3" { Diagnose-MemoryHealth }
            "4" {
                Diagnose-DiskHealth
                Diagnose-WindowsHealth
                Diagnose-MemoryHealth
            }
            "5" { Repair-WindowsImage }
            "6" { Repair-SystemFiles }
            "7" {
                Repair-WindowsImage
                Repair-SystemFiles
            }
            "8" { Clean-TemporaryFiles }
            "9" { Clean-WindowsUpdate }
            "10" { Clean-OldWindowsFiles }
            "11" {
                Clean-TemporaryFiles
                Clean-WindowsUpdate
                Clean-OldWindowsFiles
            }
            "99" {
                Write-Host "`n⚠️  MODE EXPERT - Exécution complète" -ForegroundColor Red
                if (Get-UserConfirmation "Diagnostics + Réparations + Nettoyage (⚠️  Peut prendre 1-2 heures)?") {
                    Diagnose-DiskHealth
                    Diagnose-WindowsHealth
                    Diagnose-MemoryHealth
                    Repair-WindowsImage
                    Repair-SystemFiles
                    Clean-TemporaryFiles
                    Clean-WindowsUpdate
                    Clean-OldWindowsFiles
                }
            }
            "0" {
                Generate-FinalReport
                Write-Host "Au revoir! 👋" -ForegroundColor Cyan
                Read-Host "Appuyez sur Entrée pour fermer"
                exit 0
            }
            default {
                Write-Host "Option invalide." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        
        if ($choice -ne "0") {
            Read-Host "`nAppuyez sur Entrée pour continuer"
        }
    }
    while ($true)
}

# ============================================================================
# EXÉCUTION
# ============================================================================
Main
}
