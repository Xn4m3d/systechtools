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

function Show-UserManagementMenu {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "GESTION UTILISATEURS ET GROUPES" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Yellow
    
    Write-Host "1. Ajouter utilisateur local"
    Write-Host "2. Supprimer utilisateur local"
    Write-Host "3. Activer administrateur"
    Write-Host "4. Desactiver utilisateur"
    Write-Host "5. Changer mot de passe utilisateur"
    Write-Host "6. Voir utilisateurs connectes"
    Write-Host "0. Retour"
    Write-Host ""
    
    $choice = Read-Host "Choisissez une option"
    
    switch ($choice) {
        "1" {
            $username = Read-Host "Nom utilisateur"
            $password = Read-Host "Mot de passe" -AsSecureString
            Write-LogEntry "Creation utilisateur $username..." "ACTION"
            net user $username $password /add 2>&1 | Out-Null
            Write-LogEntry "Utilisateur $username cre" "SUCCESS"
        }
        "2" {
            $username = Read-Host "Nom utilisateur a supprimer"
            Write-LogEntry "Suppression utilisateur $username..." "ACTION"
            net user $username /delete 2>&1 | Out-Null
            Write-LogEntry "Utilisateur $username supprim" "SUCCESS"
        }
        "3" {
            $username = Read-Host "Nom utilisateur"
            Write-LogEntry "Ajout groupe Administrateurs..." "ACTION"
            net localgroup Administrateurs $username /add 2>&1 | Out-Null
            Write-LogEntry "Utilisateur $username admin" "SUCCESS"
        }
        "4" {
            $username = Read-Host "Nom utilisateur"
            Write-LogEntry "Desactivation utilisateur..." "ACTION"
            net user $username /active:no 2>&1 | Out-Null
            Write-LogEntry "Utilisateur $username dsactiv" "SUCCESS"
        }
        "5" {
            $username = Read-Host "Nom utilisateur"
            $newpass = Read-Host "Nouveau mot de passe" -AsSecureString
            Write-LogEntry "Changement mot de passe $username..." "ACTION"
            net user $username $newpass 2>&1 | Out-Null
            Write-LogEntry "Mot de passe chang" "SUCCESS"
        }
        "6" {
            Write-LogEntry "Utilisateurs connectes:" "INFO"
            query user
        }
        "0" { return }
    }
}

function Launch-MassGravel {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Red
    Write-Host "LANCEMENT MASS GRAVEL (ACTIVATION WINDOWS)" -ForegroundColor Red
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Red
    
    $confirm = Read-Host "Vous etes sur? (O/N)"
    if ($confirm -eq "O" -or $confirm -eq "o") {
        Write-LogEntry "Lancement Mass Gravel..." "ACTION"
        Start-Process powershell.exe -ArgumentList "irm https://get.activated.win | iex" -Verb RunAs
        Write-LogEntry "Mass Gravel lanc dans une nouvelle fentre" "SUCCESS"
        $global:actionsPerformed += "Mass Gravel Launched"
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
    
    Write-Host "`nDure: $($duration.Minutes) min $($duration.Seconds) sec" -ForegroundColor Yellow
    Write-Host ""
}

function Show-Menu {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                  MAINTENANCE SYSTEME v2.1                      ║" -ForegroundColor Cyan
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
    
    Write-Host "`nGESTION:" -ForegroundColor Yellow
    Write-Host " 15. Gestion utilisateurs et groupes"
    Write-Host " 16. Mass Gravel (Activation Windows)"
    
    Write-Host "`nMODES:" -ForegroundColor Cyan
    Write-Host " 17. AUTO COMPLET (tout faire)"
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
        "15" { Show-UserManagementMenu }
        "16" { Launch-MassGravel }
        "17" {
            Write-Host "`nMODE AUTO COMPLET - Toutes les operations" -ForegroundColor Cyan
            Clean-TemporaryFiles
            Clean-WindowsUpdate
            Clean-PrintSpooler
            Clean-RecycleBin
            Clean-DiskCleanup
            Repair-SystemFiles
            Repair-WindowsImage
            Repair-AppxPackages
            Defragment-Drive
            Clear-EventLogs
            Fix-ContextMenu
            Export-ApplicationsList
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
