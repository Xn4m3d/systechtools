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
$global:selectedActions = @()
$global:userChoices = @{}

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
                    $global:actionsPerformed += "Nettoyage Temp: $freedGB GB"
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
    net stop wuauserv 2>&1 | Out-Null
    net stop bits 2>&1 | Out-Null
    Write-LogEntry "Services arretes" "SUCCESS"
    
    Start-Sleep -Seconds 2
    
    $cacheDir = "C:\\Windows\\SoftwareDistribution"
    if (Test-Path $cacheDir) {
        try {
            $items = Get-ChildItem -Path $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
            $size = ($items | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path "$cacheDir\\*" -Recurse -Force -ErrorAction SilentlyContinue
            $freedGB = [math]::Round($size / 1GB, 2)
            Write-LogEntry "Cache Windows Update vide: $freedGB GB" "SUCCESS"
            $global:actionsPerformed += "Windows Update Cleanup: $freedGB GB"
        }
        catch {
            Write-LogEntry "Erreur nettoyage Windows Update" "WARNING"
        }
    }
    
    Write-LogEntry "Redemarrage services..." "ACTION"
    net start wuauserv 2>&1 | Out-Null
    net start bits 2>&1 | Out-Null
    Write-LogEntry "Services redemarres" "SUCCESS"
}

function Clean-PrintSpooler {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "NETTOYAGE SPOOL IMPRIMANTE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    Write-LogEntry "Arret service Spooler..." "ACTION"
    net stop spooler 2>&1 | Out-Null
    Write-LogEntry "Service arrete" "SUCCESS"
    
    Start-Sleep -Seconds 2
    
    $spoolDir = "C:\\Windows\\System32\\spool\\PRINTERS"
    if (Test-Path $spoolDir) {
        try {
            $items = Get-ChildItem -Path $spoolDir -Recurse -Force -ErrorAction SilentlyContinue
            $size = ($items | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path "$spoolDir\\*" -Recurse -Force -ErrorAction SilentlyContinue
            $freedGB = [math]::Round($size / 1GB, 2)
            Write-LogEntry "Spool nettoy - $freedGB GB" "SUCCESS"
            $global:actionsPerformed += "Spool Cleanup: $freedGB GB"
        }
        catch {
            Write-LogEntry "Erreur nettoyage spool" "WARNING"
        }
    }
    
    Write-LogEntry "Redemarrage service Spooler..." "ACTION"
    net start spooler 2>&1 | Out-Null
    Write-LogEntry "Service redemarr" "SUCCESS"
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
    
    Write-LogEntry "Lancement DISM ComponentCleanup..." "ACTION"
    Invoke-CommandSafely { & DISM /Online /Cleanup-Image /StartComponentCleanup } "DISM Component Cleanup"
    
    $global:actionsPerformed += "DISM Restore Health + ComponentCleanup"
}

function Repair-AppxPackages {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "REPARATION PACKAGES APPX MICROSOFT" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    Write-LogEntry "Reparation packages AppX..." "ACTION"
    try {
        Get-AppXPackage -AllUsers | Repair-AppxPackage -ErrorAction SilentlyContinue
        Write-LogEntry "Packages AppX repares" "SUCCESS"
        $global:actionsPerformed += "AppX Packages Repair"
    }
    catch {
        Write-LogEntry "Erreur reparation AppX" "WARNING"
    }
}

function Defragment-Drive {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "OPTIMISATION DISQUE" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Blue
    
    try {
        $disk = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
        $diskInfo = Get-PhysicalDisk | Where-Object { $_.SerialNumber -match $disk.ObjectId }
        
        if ($diskInfo.MediaType -eq "SSD") {
            Write-LogEntry "Disque SSD detecte - Trim au lieu de defrag" "WARNING"
            Invoke-CommandSafely { & TRIM /Volume:C /Immediate } "TRIM SSD"
            $global:actionsPerformed += "SSD TRIM"
        }
        else {
            Write-LogEntry "Optimisation disque (HDD)..." "ACTION"
            $disk | Optimize-Volume -Defrag -Verbose -ErrorAction SilentlyContinue
            Write-LogEntry "Defragmentation terminee" "SUCCESS"
            $global:actionsPerformed += "Defragmentation"
        }
    }
    catch {
        Write-LogEntry "Erreur defragmentation" "WARNING"
    }
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

function Fix-ContextMenu {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "REPARATION MENU CONTEXTUEL" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Blue
    
    Write-LogEntry "Reparation menu contextuel..." "ACTION"
    try {
        Invoke-CommandSafely { & reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve } "Registry Menu Fix"
        Write-LogEntry "Redemarrage explorateur..." "ACTION"
        taskkill /f /im explorer.exe 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        start explorer.exe
        Write-LogEntry "Menu contextuel repare" "SUCCESS"
        $global:actionsPerformed += "Context Menu Fixed"
    }
    catch {
        Write-LogEntry "Erreur reparation menu" "ERROR"
    }
}

function Export-ApplicationsList {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "EXPORT LISTE APPLICATIONS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    Write-LogEntry "Recuperation liste applications..." "ACTION"
    try {
        $desktop = [Environment]::GetFolderPath("Desktop")
        $filePath = "$desktop\liste_applications.txt"
        Get-WmiObject -Class Win32_Product | Select-Object -Property Name | Out-File -FilePath $filePath -Encoding UTF8
        Write-LogEntry "Liste sauvegardee: $filePath" "SUCCESS"
        $global:actionsPerformed += "Applications List Exported"
    }
    catch {
        Write-LogEntry "Erreur export applications" "ERROR"
    }
}

function Launch-MassGraveActivation {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "LANCEMENT MASS GRAVE ACTIVATION" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Red
    
    Write-LogEntry "Lancement MASS GRAVE ACTIVATION..." "ACTION"
    Start-Process powershell.exe -ArgumentList "irm https://get.activated.win | iex" -Verb RunAs
    Write-LogEntry "MASS GRAVE ACTIVATION lancee dans une nouvelle fenetre" "SUCCESS"
    $global:actionsPerformed += "MASS GRAVE ACTIVATION Launched"
}

function Launch-WinUtil {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "LANCEMENT WINUTIL" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    Write-LogEntry "Lancement WinUtil..." "ACTION"
    Start-Process powershell.exe -ArgumentList "irm https://christitus.com/win | iex" -Verb RunAs
    Write-LogEntry "WinUtil lancee dans une nouvelle fenetre" "SUCCESS"
    $global:actionsPerformed += "WinUtil Launched"
}

function Show-ActionSelectionMenu {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              CONFIGURATION MODE AUTO PERSONNALISE              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "Selectionnez les actions a executer (entrez les numeros separes par des virgules)" -ForegroundColor Yellow
    Write-Host "Exemple: 1,2,5,7,11 pour lancer les actions 1, 2, 5, 7 et 11`n" -ForegroundColor Yellow
    
    Write-Host "NETTOYAGE:" -ForegroundColor Green
    Write-Host "  1. Fichiers temporaires"
    Write-Host "  2. Cache Windows Update"
    Write-Host "  3. Spool Imprimante"
    Write-Host "  4. Corbeille"
    Write-Host "  5. Disk Cleanup"
    
    Write-Host "`nREPARATION:" -ForegroundColor Magenta
    Write-Host "  6. SFC (Reparation fichiers) - Duree: 15-30 min"
    Write-Host "  7. DISM (Reparation image + Component)"
    Write-Host "  8. Packages AppX"
    
    Write-Host "`nOPTIMISATION:" -ForegroundColor Blue
    Write-Host "  9. Defragmentation (HDD) ou TRIM (SSD)"
    Write-Host " 10. Journaux d'evenements"
    Write-Host " 11. Menu contextuel"
    Write-Host " 12. Export liste applications"
    
    Write-Host "`nOUTILS EXTERNES:" -ForegroundColor Red
    Write-Host " 13. MASS GRAVE ACTIVATION"
    Write-Host " 14. WinUtil"
    Write-Host ""
    Write-Host "Tapez 'quit' pour annuler`n" -ForegroundColor Yellow
    
    $input = Read-Host "Vos choix"
    
    if ($input -eq "quit" -or $input -eq "") {
        return $false
    }
    
    $choices = $input -split "," | ForEach-Object { $_.Trim() }
    $global:selectedActions = $choices
    
    return $true
}

function Get-UserPreConfigurations {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          PRE-CONFIGURATION DES ACTIONS INTERACTIVES           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    if ($global:selectedActions -contains "6") {
        Write-Host "`n[ACTION 6 - SFC]" -ForegroundColor Magenta
        Write-Host "La reparation des fichiers systeme peut prendre 15-30 minutes."
        Write-Host "Confirmez-vous? (O/N)" -ForegroundColor Yellow
        $confirm = Read-Host ""
        $global:userChoices["SFC"] = ($confirm -eq "O" -or $confirm -eq "o")
    }
    
    if ($global:selectedActions -contains "13") {
        Write-Host "`n[ACTION 13 - MASS GRAVE ACTIVATION]" -ForegroundColor Red
        Write-Host "Cet outil lancera une fenetre externe pour l'activation Windows."
        Write-Host "Confirmez-vous? (O/N)" -ForegroundColor Yellow
        $confirm = Read-Host ""
        $global:userChoices["MassGrave"] = ($confirm -eq "O" -or $confirm -eq "o")
    }
    
    if ($global:selectedActions -contains "14") {
        Write-Host "`n[ACTION 14 - WINUTIL]" -ForegroundColor Magenta
        Write-Host "Cet outil lancera une interface graphique pour l'optimisation Windows."
        Write-Host "Confirmez-vous? (O/N)" -ForegroundColor Yellow
        $confirm = Read-Host ""
        $global:userChoices["WinUtil"] = ($confirm -eq "O" -or $confirm -eq "o")
    }
    
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              CONFIGURATION COMPLETE - PRET A DEMARRER         ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "Appuyez sur Entree pour demarrer le mode auto configure..." -ForegroundColor Green
    Read-Host ""
}

function Execute-CustomAutoMode {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    MODE AUTO PERSONNALISE EN COURS            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    foreach ($action in $global:selectedActions) {
        switch ($action) {
            "1" { Clean-TemporaryFiles }
            "2" { Clean-WindowsUpdate }
            "3" { Clean-PrintSpooler }
            "4" { Clean-RecycleBin }
            "5" { Clean-DiskCleanup }
            "6" {
                if ($global:userChoices["SFC"]) {
                    Repair-SystemFiles
                } else {
                    Write-LogEntry "SFC skipped par l'utilisateur" "WARNING"
                }
            }
            "7" { Repair-WindowsImage }
            "8" { Repair-AppxPackages }
            "9" { Defragment-Drive }
            "10" { Clear-EventLogs }
            "11" { Fix-ContextMenu }
            "12" { Export-ApplicationsList }
            "13" {
                if ($global:userChoices["MassGrave"]) {
                    Launch-MassGraveActivation
                } else {
                    Write-LogEntry "MASS GRAVE ACTIVATION skipped par l'utilisateur" "WARNING"
                }
            }
            "14" {
                if ($global:userChoices["WinUtil"]) {
                    Launch-WinUtil
                } else {
                    Write-LogEntry "WinUtil skipped par l'utilisateur" "WARNING"
                }
            }
            default {
                Write-LogEntry "Action inconnue: $action" "WARNING"
            }
        }
    }
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
    Write-Host "║                  MAINTENANCE SYSTEME v2.1+                      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "NETTOYAGE:" -ForegroundColor Green
    Write-Host "  1. Fichiers temporaires"
    Write-Host "  2. Cache Windows Update"
    Write-Host "  3. Spool Imprimante"
    Write-Host "  4. Corbeille"
    Write-Host "  5. Disk Cleanup"
    Write-Host "  6. AUTO - Tous les nettoyages"
    
    Write-Host "`nREPARATION:" -ForegroundColor Magenta
    Write-Host "  7. SFC (Reparation fichiers)"
    Write-Host "  8. DISM (Reparation image + Component)"
    Write-Host "  9. Packages AppX"
    Write-Host " 10. AUTO - Toutes les reparations"
    
    Write-Host "`nOPTIMISATION:" -ForegroundColor Blue
    Write-Host " 11. Defragmentation (HDD) ou TRIM (SSD)"
    Write-Host " 12. Journaux d'evenements"
    Write-Host " 13. Menu contextuel"
    Write-Host " 14. Export liste applications"
    
    Write-Host "`nOUTILS EXTERNES:" -ForegroundColor Red
    Write-Host " 15. MASS GRAVE ACTIVATION (Activation Windows)"
    Write-Host " 16. WinUtil (Suite d'optimisation complete)"
    
    Write-Host "`nMODES:" -ForegroundColor Cyan
    Write-Host " 17. AUTO PERSONNALISE - Selectionnez vos actions"
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
        "3" { Clean-PrintSpooler }
        "4" { Clean-RecycleBin }
        "5" { Clean-DiskCleanup }
        "6" {
            Clean-TemporaryFiles
            Clean-WindowsUpdate
            Clean-PrintSpooler
            Clean-RecycleBin
            Clean-DiskCleanup
        }
        "7" { Repair-SystemFiles }
        "8" { Repair-WindowsImage }
        "9" { Repair-AppxPackages }
        "10" {
            Repair-SystemFiles
            Repair-WindowsImage
            Repair-AppxPackages
        }
        "11" { Defragment-Drive }
        "12" { Clear-EventLogs }
        "13" { Fix-ContextMenu }
        "14" { Export-ApplicationsList }
        "15" { Launch-MassGraveActivation }
        "16" { Launch-WinUtil }
        "17" {
            if (Show-ActionSelectionMenu) {
                Get-UserPreConfigurations
                Execute-CustomAutoMode
            }
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