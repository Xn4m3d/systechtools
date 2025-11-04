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
Write-Host "║  OK Droits administrateur confirmés" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

$global:logReport = @()
$global:errorsFound = @()
$global:actionsPerformed = @()
$global:startTime = Get-Date
$global:selectedActions = @()
$global:userChoices = @{}

function Write-Log-Entry {
    param([string]$Message, [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "ACTION")][string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Type] $Message"
    $global:logReport += $logEntry
    
    switch ($Type) {
        "SUCCESS" { Write-Host "OK $Message" -ForegroundColor Green }
        "ERROR" { Write-Host "ERR $Message" -ForegroundColor Red; $global:errorsFound += $Message }
        "WARNING" { Write-Host "WARN $Message" -ForegroundColor Yellow }
        "ACTION" { Write-Host ">> $Message" -ForegroundColor Cyan }
        default { Write-Host "   $Message" -ForegroundColor Gray }
    }
}

function Invoke-Command-Safely {
    param([scriptblock]$Command, [string]$Description = "System Command")
    try {
        Write-Log-Entry "Exécution: $Description" "ACTION"
        $result = & $Command 2>&1
        Write-Log-Entry "$Description - Succès" "SUCCESS"
        return $result
    }
    catch {
        Write-Log-Entry "$Description - Erreur: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Show-Interactive-Menu-MultiSelect {
    param([array]$Items, [string]$Title)
    
    $selectedIndices = @()
    $currentIndex = 0
    
    while ($true) {
        Clear-Host
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║  $($Title.PadRight(62))║" -ForegroundColor Cyan
        Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
        
        Write-Host "Navigation: FLECHES ↑↓ | Sélection: ESPACE | Valider: ENTREE | Annuler: ESC`n" -ForegroundColor Yellow
        
        for ($i = 0; $i -lt $Items.Count; $i++) {
            if ($Items[$i] -eq "") {
                Write-Host ""
                continue
            }
            
            $checkbox = if ($selectedIndices -contains $i) { "[✓]" } else { "[ ]" }
            
            if ($i -eq $currentIndex) {
                Write-Host "► $checkbox $($Items[$i])" -ForegroundColor Green -BackgroundColor DarkGray
            } else {
                Write-Host "  $checkbox $($Items[$i])" -ForegroundColor White
            }
        }
        
        Write-Host "`nSélectionnées: $($selectedIndices.Count) option(s)" -ForegroundColor Cyan
        
        $key = [Console]::ReadKey($true)
        
        switch ($key.Key) {
            "UpArrow" {
                do {
                    $currentIndex = if ($currentIndex -gt 0) { $currentIndex - 1 } else { $Items.Count - 1 }
                } while ($Items[$currentIndex] -eq "")
            }
            "DownArrow" {
                do {
                    $currentIndex = if ($currentIndex -lt $Items.Count - 1) { $currentIndex + 1 } else { 0 }
                } while ($Items[$currentIndex] -eq "")
            }
            "Spacebar" {
                if ($Items[$currentIndex] -ne "") {
                    if ($selectedIndices -contains $currentIndex) {
                        $selectedIndices = $selectedIndices -ne $currentIndex
                    } else {
                        $selectedIndices += $currentIndex
                    }
                }
            }
            "Enter" {
                if ($selectedIndices.Count -gt 0) {
                    return $selectedIndices
                }
            }
            "Escape" {
                return $null
            }
        }
    }
}

function Clean-Temporary-Files {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "1. NETTOYAGE FICHIERS TEMPORAIRES" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    $tempPaths = @("C:\\Windows\\Temp\\*", "C:\\Users\\*\\AppData\\Local\\Temp\\*", "$env:TEMP\\*")
    foreach ($path in $tempPaths) {
        if (Test-Path -Path $path) {
            try {
                $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                $size = ($items | Measure-Object -Property Length -Sum).Sum
                if ($items -and $size -gt 0) {
                    Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    $freedGB = [math]::Round($size / 1GB, 2)
                    Write-Log-Entry "Temp nettoyé: $freedGB GB" "SUCCESS"
                    $global:actionsPerformed += "1. Nettoyage Temp: $freedGB GB"
                }
            } catch { Write-Log-Entry "Erreur temp" "WARNING" }
        }
    }
}

function Clean-Windows-Update {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "2. VIDAGE CACHE WINDOWS UPDATE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    net stop wuauserv 2>&1 | Out-Null
    net stop bits 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    
    $cacheDir = "C:\\Windows\\SoftwareDistribution"
    if (Test-Path $cacheDir) {
        try {
            $size = (Get-ChildItem -Path $cacheDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path "$cacheDir\\*" -Recurse -Force -ErrorAction SilentlyContinue
            $freedGB = [math]::Round($size / 1GB, 2)
            Write-Log-Entry "Windows Update: $freedGB GB" "SUCCESS"
            $global:actionsPerformed += "2. Windows Update: $freedGB GB"
        } catch { Write-Log-Entry "Erreur Update" "WARNING" }
    }
    
    net start wuauserv 2>&1 | Out-Null
    net start bits 2>&1 | Out-Null
}

function Clean-Print-Spooler {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "3. NETTOYAGE SPOOL IMPRIMANTE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    net stop spooler 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    $spoolDir = "C:\\Windows\\System32\\spool\\PRINTERS"
    if (Test-Path $spoolDir) {
        try {
            $size = (Get-ChildItem -Path $spoolDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Remove-Item -Path "$spoolDir\\*" -Recurse -Force -ErrorAction SilentlyContinue
            $freedGB = [math]::Round($size / 1GB, 2)
            Write-Log-Entry "Spool: $freedGB GB" "SUCCESS"
            $global:actionsPerformed += "3. Spool: $freedGB GB"
        } catch { Write-Log-Entry "Erreur Spool" "WARNING" }
    }
    net start spooler 2>&1 | Out-Null
}

function Clean-Recycle-Bin {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "4. VIDAGE CORBEILLE" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
    Write-Log-Entry "Corbeille vidée" "SUCCESS"
    $global:actionsPerformed += "4. Corbeille vidée"
}

function Clean-Disk-Cleanup {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host "5. NETTOYAGE DISQUE (DISK CLEANUP)" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Green
    
    $paths = @("C:\\Windows\\Prefetch", "C:\\Windows\\System32\\dllcache", "C:\\ProgramData\\Package Cache")
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try {
                $size = (Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                if ($size -gt 0) {
                    Remove-Item -Path "$path\\*" -Recurse -Force -ErrorAction SilentlyContinue
                    $freedGB = [math]::Round($size / 1GB, 2)
                    Write-Log-Entry "Nettoyage disque: $freedGB GB" "SUCCESS"
                    $global:actionsPerformed += "5. Disk Cleanup: $freedGB GB"
                }
            } catch { Write-Log-Entry "Erreur Disk Cleanup" "WARNING" }
        }
    }
}

function Repair-System-Files {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "7. RÉPARATION FICHIERS SYSTÈME (SFC)" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    Write-Log-Entry "SFC /scannow (15-30 min)..." "ACTION"
    Invoke-Command-Safely { & sfc /scannow } "SFC Scan"
    $global:actionsPerformed += "7. SFC /scannow"
}

function Repair-Windows-Image {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "8. RÉPARATION IMAGE WINDOWS (DISM)" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    Invoke-Command-Safely { & DISM /Online /Cleanup-Image /RestoreHealth } "DISM Restore"
    Invoke-Command-Safely { & DISM /Online /Cleanup-Image /StartComponentCleanup } "DISM Component"
    $global:actionsPerformed += "8. DISM Restore + Component"
}

function Repair-Appx-Packages {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
    Write-Host "9. RÉPARATION PACKAGES APPX" -ForegroundColor Magenta
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Magenta
    
    try {
        Get-AppXPackage -AllUsers | Repair-AppxPackage -ErrorAction SilentlyContinue
        Write-Log-Entry "AppX réparés" "SUCCESS"
        $global:actionsPerformed += "9. AppX Repair"
    } catch { Write-Log-Entry "Erreur AppX" "WARNING" }
}

function Defragment-Drive {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "11. OPTIMISATION DISQUE" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Blue
    
    try {
        Write-Log-Entry "Détection type de disque..." "ACTION"
        $disk = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
        
        if ($null -eq $disk) {
            Write-Log-Entry "Impossible de détecter le disque" "ERROR"
            return
        }
        
        $isDrive = Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" }
        
        if ($isDrive) {
            Write-Log-Entry "Disque SSD détecté - Lancement TRIM" "WARNING"
            Write-Log-Entry "Optimisation SSD (TRIM)..." "ACTION"
            $disk | Optimize-Volume -Trim -Verbose -ErrorAction SilentlyContinue
            Write-Log-Entry "TRIM SSD exécuté" "SUCCESS"
            $global:actionsPerformed += "11. SSD TRIM optimisé"
        } else {
            Write-Log-Entry "Disque HDD détecté - Lancement Défragmentation" "WARNING"
            Write-Log-Entry "Défragmentation disque (peut prendre 30-60 min)..." "ACTION"
            $disk | Optimize-Volume -Defrag -Verbose -ErrorAction SilentlyContinue
            Write-Log-Entry "Défragmentation complète" "SUCCESS"
            $global:actionsPerformed += "11. HDD Défragmentation complète"
        }
    } catch { 
        Write-Log-Entry "Erreur defrag/trim: $($_.Exception.Message)" "ERROR"
        Write-Log-Entry "Tentative méthode alternative..." "ACTION"
        try {
            Write-Log-Entry "Utilisation de Optimize-Volume standard..." "ACTION"
            Get-Volume -DriveLetter C -ErrorAction SilentlyContinue | Optimize-Volume -Verbose -ErrorAction SilentlyContinue
            Write-Log-Entry "Optimisation standard complète" "SUCCESS"
            $global:actionsPerformed += "11. Optimisation disque (mode standard)"
        } catch {
            Write-Log-Entry "Erreur optimisation disque" "ERROR"
        }
    }
}

function Clear-Event-Logs {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "12. VIDAGE JOURNAUX D'ÉVÉNEMENTS" -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Yellow
    
    @("System", "Application", "Security") | ForEach-Object {
        Clear-EventLog -LogName $_ -ErrorAction SilentlyContinue
        Write-Log-Entry "Journal $_ vidé" "SUCCESS"
    }
    $global:actionsPerformed += "12. Journaux vidés"
}

function Fix-Context-Menu {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    Write-Host "13. RÉPARATION MENU CONTEXTUEL" -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Blue
    
    try {
        reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve 2>&1 | Out-Null
        taskkill /f /im explorer.exe 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        start explorer.exe
        Write-Log-Entry "Menu réparé" "SUCCESS"
        $global:actionsPerformed += "13. Context Menu Fixed"
    } catch { Write-Log-Entry "Erreur menu" "ERROR" }
}

function Export-Applications-List {
    Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "14. EXPORT LISTE APPLICATIONS" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    try {
        $filePath = "$([Environment]::GetFolderPath('Desktop'))\liste_applications.txt"
        Get-WmiObject -Class Win32_Product | Select-Object -Property Name | Out-File -FilePath $filePath -Encoding UTF8
        Write-Log-Entry "Sauvegarde: $filePath" "SUCCESS"
        $global:actionsPerformed += "14. Apps List Exported"
    } catch { Write-Log-Entry "Erreur export" "ERROR" }
}

function Get-User-Pre-Configurations {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         PRÉ-CONFIGURATION AVANT LANCEMENT                      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    if ($global:selectedActions -contains 6) {
        Write-Host "[ACTION 7 - SFC]: Durée: 15-30 minutes" -ForegroundColor Magenta
        $confirm = Read-Host "Confirmer? (O/N)"
        $global:userChoices["SFC"] = ($confirm -eq "O" -or $confirm -eq "o")
    }
    
    Read-Host "`n╔════════════════════════════════════════════════════════════════╗`nAppuyez ENTREE pour lancer`n╚════════════════════════════════════════════════════════════════╝"
}

function Execute-Custom-Auto-Mode {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║            MODE AUTO PERSONNALISÉ EN COURS                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $map = @{
        0={Clean-Temporary-Files};1={Clean-Windows-Update};2={Clean-Print-Spooler};3={Clean-Recycle-Bin};4={Clean-Disk-Cleanup}
        6={if($global:userChoices["SFC"]){Repair-System-Files}else{Write-Log-Entry "SFC ignoré" "WARNING"}}
        7={Repair-Windows-Image};8={Repair-Appx-Packages};10={Defragment-Drive};11={Clear-Event-Logs}
    }
    
    foreach ($idx in $global:selectedActions) {
        if ($map.ContainsKey($idx)) { & $map[$idx] }
    }
}

function Generate-Report {
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                       RAPPORT FINAL                           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    $duration = (Get-Date) - $global:startTime
    
    Write-Host "✓ Actions effectuées: $($global:actionsPerformed.Count)" -ForegroundColor Green
    $global:actionsPerformed | ForEach-Object { Write-Host "  ├─ $_" -ForegroundColor Green }
    
    if ($global:errorsFound.Count -gt 0) {
        Write-Host "`n✗ Erreurs: $($global:errorsFound.Count)" -ForegroundColor Red
        $global:errorsFound | ForEach-Object { Write-Host "  ├─ $_" -ForegroundColor Red }
    }
    
    Write-Host "`nDurée: $($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Yellow
}

$continue = $true
while ($continue) {
    Clear-Host
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         MAINTENANCE SYSTEM TOOLS v2.2 - FINAL                 ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "┌─ NETTOYAGE ─────────────────────────────────────────────────────┐" -ForegroundColor Green
    Write-Host "│  1. Fichiers temporaires          2. Cache Windows Update      │" -ForegroundColor Green
    Write-Host "│  3. Spool Imprimante              4. Corbeille                 │" -ForegroundColor Green
    Write-Host "│  5. Disk Cleanup                  6. AUTO - Tous nettoyages   │" -ForegroundColor Green
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    
    Write-Host "`n┌─ RÉPARATION ────────────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "│  7. SFC (Réparation fichiers)     8. DISM (Réparation image)  │" -ForegroundColor Magenta
    Write-Host "│  9. Packages AppX                 10. AUTO - Toutes réparations│" -ForegroundColor Magenta
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Magenta
    
    Write-Host "`n┌─ OPTIMISATION ──────────────────────────────────────────────────┐" -ForegroundColor Blue
    Write-Host "│  11. Defrag/TRIM                  12. Journaux d'événements    │" -ForegroundColor Blue
    Write-Host "│  13. Menu contextuel              14. Export applications     │" -ForegroundColor Blue
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Blue
    
    Write-Host "`n┌─ MODES ────────────────────────────────────────────────────────┐" -ForegroundColor Cyan
    Write-Host "│  17. AUTO PERSONNALISÉ - Sélectionnez vos actions  (MULTI)   │" -ForegroundColor Cyan
    Write-Host "│   0. Retour au menu principal                                  │" -ForegroundColor Cyan
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Cyan
    
    $choice = Read-Host "`nChoisissez une option (0-17)"
    
    switch ($choice) {
        "1" { Clean-Temporary-Files }
        "2" { Clean-Windows-Update }
        "3" { Clean-Print-Spooler }
        "4" { Clean-Recycle-Bin }
        "5" { Clean-Disk-Cleanup }
        "6" { Clean-Temporary-Files; Clean-Windows-Update; Clean-Print-Spooler; Clean-Recycle-Bin; Clean-Disk-Cleanup }
        "7" { Repair-System-Files }
        "8" { Repair-Windows-Image }
        "9" { Repair-Appx-Packages }
        "10" { Repair-System-Files; Repair-Windows-Image; Repair-Appx-Packages }
        "11" { Defragment-Drive }
        "12" { Clear-Event-Logs }
        "13" { Fix-Context-Menu }
        "14" { Export-Applications-List }
        "17" {
            $selectionItems = @(
                "1. Fichiers temporaires",
                "2. Cache Windows Update",
                "3. Spool Imprimante",
                "4. Corbeille",
                "5. Disk Cleanup",
                "",
                "6. SFC (Réparation)",
                "7. DISM",
                "8. AppX",
                "",
                "9. Defrag/TRIM",
                "10. Journaux"
            )
            
            $result = Show-Interactive-Menu-MultiSelect -Items $selectionItems -Title "SÉLECTION DES ACTIONS"
            if ($result -ne $null -and $result.Count -gt 0) {
                $global:selectedActions = $result
                Get-User-Pre-Configurations
                Execute-Custom-Auto-Mode
            }
        }
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