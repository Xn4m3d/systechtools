# ============================================================================
# SCRIPT MAINTENANCE SYSTÈME - VERSION FINALE
# Avec vérification privilèges admin au lancement
# À copier/coller directement dans PowerShell
# ============================================================================

# ============================================================================
# VÉRIFICATION PRIVILÈGES ADMINISTRATEUR (PRIORITAIRE)
# ============================================================================

$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)

if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                      ❌ ACCÈS REFUSÉ                          ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  Ce script nécessite les PRIVILÈGES ADMINISTRATEUR" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Comment procéder:" -ForegroundColor Yellow
    Write-Host "  1. Appuyez sur ⊞ Win + X" -ForegroundColor Gray
    Write-Host "  2. Sélectionnez 'Windows PowerShell (Admin)'" -ForegroundColor Gray
    Write-Host "  3. Relancez le script" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Ou: Clic droit sur PowerShell → Exécuter en tant qu'administrateur" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Appuyez sur Entrée pour fermer"
    exit 1
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✓ Privilèges administrateur confirmés" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

# ============================================================================
# DÉBUT DU SCRIPT (Bloc principal)
# ============================================================================

&{

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
        $result = & $Command 2>&1
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
        Write-LogEntry "SMART: Impossible de vérifier" "WARNING"
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
                
                if ($items -and $size -gt 0) {
                    Write-LogEntry "Suppression des fichiers temporaires: $path" "ACTION"
                    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    $freedGB = [math]::Round($size / 1GB, 2)
                    Write-LogEntry "Espace libéré: $freedGB GB" "SUCCESS"
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
    Write-Host "🧹 VIDAGE CACHE WINDOWS UPDATE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    if (Get-UserConfirmation "Arrêter services Windows Update et vider le cache?") {
        Write-LogEntry "Arrêt services..." "ACTION"
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
        Write-LogEntry "Services arrêtés" "SUCCESS"
        
        Start-Sleep -Seconds 2
        
        $cacheDir = "C:\Windows\SoftwareDistribution\Download"
        if (Test-Path $cacheDir) {
            $items = Get-ChildItem -Path $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            $size = ($items | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path "$cacheDir\*" -Recurse -Force -ErrorAction SilentlyContinue
            $freedGB = [math]::Round($size / 1GB, 2)
            Write-LogEntry "Cache Windows Update vidé: $freedGB GB" "SUCCESS"
            $global:actionsPerformed += "Windows Update Cleanup: $freedGB GB"
        }
        
        Write-LogEntry "Redémarrage services..." "ACTION"
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Start-Service -Name bits -ErrorAction SilentlyContinue
        Write-LogEntry "Services redémarrés" "SUCCESS"
    }
}

# ============================================================================
# MENU PRINCIPAL
# ============================================================================

function Show-MainMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "║      🛠️  MAINTENANCE SYSTÈME - MENU PRINCIPAL                 ║" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "SECTION 1 - DIAGNOSTICS" -ForegroundColor Yellow
    Write-Host "  1. Diagnostic disque dur" -ForegroundColor Gray
    Write-Host "  2. Diagnostic intégrité Windows" -ForegroundColor Gray
    Write-Host "  3. Diagnostic mémoire" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "SECTION 2 - RÉPARATIONS" -ForegroundColor Yellow
    Write-Host "  4. Réparation image Windows (DISM)" -ForegroundColor Gray
    Write-Host "  5. Réparation fichiers système (SFC)" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "SECTION 3 - NETTOYAGE" -ForegroundColor Yellow
    Write-Host "  6. Nettoyage fichiers temporaires" -ForegroundColor Gray
    Write-Host "  7. Vidage cache Windows Update" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "AUTRE" -ForegroundColor Yellow
    Write-Host "  8. Rapport final" -ForegroundColor Gray
    Write-Host "  0. Quitter" -ForegroundColor Gray
    Write-Host ""
}

function Generate-FinalReport {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║             RAPPORT DE MAINTENANCE SYSTÈME                     ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $endTime = Get-Date
    $duration = $endTime - $global:startTime
    
    Write-Host "`n📋 RÉSUMÉ EXÉCUTION" -ForegroundColor Cyan
    Write-Host "Début: $($global:startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "Fin: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host "Durée: $([math]::Round($duration.TotalMinutes, 2)) minutes`n" -ForegroundColor Gray
    
    if ($global:actionsPerformed.Count -gt 0) {
        Write-Host "✓ ACTIONS EFFECTUÉES ($($global:actionsPerformed.Count))" -ForegroundColor Green
        foreach ($action in $global:actionsPerformed) {
            Write-Host "  • $action" -ForegroundColor Green
        }
        Write-Host ""
    }
    
    if ($global:errorsFound.Count -gt 0) {
        Write-Host "❌ PROBLÈMES DÉTECTÉS ($($global:errorsFound.Count))" -ForegroundColor Red
        foreach ($error in $global:errorsFound) {
            Write-Host "  • $error" -ForegroundColor Red
        }
    }
    
    Write-Host "`n✓ Prêt à l'emploi ! 🚀" -ForegroundColor Green
}

# ============================================================================
# BOUCLE PRINCIPALE
# ============================================================================

do {
    Show-MainMenu
    $choice = Read-Host "Sélectionnez une option"
    
    switch ($choice) {
        "1" { Diagnose-DiskHealth }
        "2" { Diagnose-WindowsHealth }
        "3" { Diagnose-MemoryHealth }
        "4" { Repair-WindowsImage }
        "5" { Repair-SystemFiles }
        "6" { Clean-TemporaryFiles }
        "7" { Clean-WindowsUpdate }
        "8" { Generate-FinalReport }
        "0" { break }
        default { Write-Host "Option invalide" -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
} while ($true)

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  À bientôt ! 👋" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

} # Fin bloc principal
