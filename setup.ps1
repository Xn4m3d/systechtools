# ============================================================================
# SETUP FINAL COMPLET - VERSION CORRIGÉE
# À exécuter UNE SEULE FOIS sur ton PC source (admin)
# NE DEMANDE QUE LES URLs DES SCRIPTS MÉTIER
# ============================================================================

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          GÉNÉRATEUR DE MENU - ONEDRIVE/SHAREPOINT SCRIPTS     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ============================================================================
# FONCTION DE TÉLÉCHARGEMENT SHAREPOINT
# ============================================================================

function Download-SharePointFile {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$false)][string]$OutFile = "$env:TEMP\downloaded.ps1"
    )
    
    Write-Host "⏬ Téléchargement depuis SharePoint..." -ForegroundColor Cyan
    
    try {
        Write-Host "  Tentative 1/3..." -ForegroundColor Gray
        $tempFile = "$env:TEMP\temp-$(Get-Random).ps1"
        Invoke-WebRequest -Uri $Url -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
        $content = Get-Content $tempFile -Raw -ErrorAction Stop
        
        if ($content -notlike "*<!DOCTYPE*" -and $content -notlike "*<html*") {
            Move-Item $tempFile $OutFile -Force
            Write-Host "  ✓ Succès" -ForegroundColor Green
            return $OutFile
        }
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  ⚠ Échec" -ForegroundColor Yellow
    }
    
    try {
        Write-Host "  Tentative 2/3..." -ForegroundColor Gray
        $urlBase = $Url -split '\?' | Select-Object -First 1
        $urlConverted = $urlBase -replace ":u:/r/", ""
        $tempFile = "$env:TEMP\temp-$(Get-Random).ps1"
        
        Invoke-WebRequest -Uri $urlConverted -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
        $content = Get-Content $tempFile -Raw -ErrorAction Stop
        
        if ($content -notlike "*<!DOCTYPE*") {
            Move-Item $tempFile $OutFile -Force
            Write-Host "  ✓ Succès" -ForegroundColor Green
            return $OutFile
        }
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  ⚠ Échec" -ForegroundColor Yellow
    }
    
    try {
        Write-Host "  Tentative 3/3 (accès local)..." -ForegroundColor Gray
        foreach ($path in @(
            "D:\OneDrive - Asgard Informatique\Documents\Scripts\menu-selector.ps1",
            "$env:USERPROFILE\OneDrive - Asgard Informatique\Documents\Scripts\menu-selector.ps1",
            "$env:USERPROFILE\OneDrive\Scripts\menu-selector.ps1"
        )) {
            if (Test-Path $path) {
                Copy-Item -Path $path -Destination $OutFile -Force
                Write-Host "  ✓ Succès (accès local)" -ForegroundColor Green
                return $OutFile
            }
        }
    } catch {
        Write-Host "  ⚠ Échec" -ForegroundColor Yellow
    }
    
    Write-Host "  ❌ Impossible de télécharger" -ForegroundColor Red
    return $null
}

# ============================================================================
# DÉTECTION AUTOMATIQUE DU CHEMIN ONEDRIVE
# ============================================================================

Write-Host "Détection du chemin OneDrive..." -ForegroundColor Yellow

$currentLocation = Get-Location
$scriptsFolder = $null

if ((Get-Item $currentLocation).Name -eq "Scripts" -or $currentLocation.Path -like "*Scripts*") {
    if (Test-Path "$currentLocation\*.ps1") {
        $scriptsFolder = $currentLocation.Path
        Write-Host "✓ Dossier Scripts détecté (depuis le répertoire courant)" -ForegroundColor Green
    }
}

if ($null -eq $scriptsFolder) {
    $possiblePaths = @(
        "$env:USERPROFILE\OneDrive\Scripts",
        "$env:USERPROFILE\OneDrive - Asgard Informatique\Scripts",
        "$env:USERPROFILE\OneDrive - Asgard Informatique\Documents\Scripts",
        "D:\OneDrive - Asgard Informatique\Scripts",
        "D:\OneDrive - Asgard Informatique\Documents\Scripts"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $scriptsFolder = $path
            Write-Host "✓ Dossier Scripts détecté: $path" -ForegroundColor Green
            break
        }
    }
}

if ($null -eq $scriptsFolder) {
    Write-Host "`n⚠ Impossible de détecter automatiquement le chemin OneDrive" -ForegroundColor Yellow
    Write-Host "📁 Veuillez fournir le chemin complet du dossier Scripts :" -ForegroundColor Yellow
    $scriptsFolder = Read-Host "Chemin"
    
    if (-not (Test-Path $scriptsFolder)) {
        Write-Host "❌ Chemin invalide : $scriptsFolder" -ForegroundColor Red
        Read-Host "Appuyez sur Entrée"
        exit 1
    }
}

Write-Host "✓ Chemin utilisé: $scriptsFolder`n" -ForegroundColor Green

$menuOutputPath = Join-Path $scriptsFolder "menu-selector.ps1"

# ============================================================================
# SCANNER LES SCRIPTS MÉTIER (Exclure le setup)
# ============================================================================

Write-Host "Scan des scripts PowerShell..." -ForegroundColor Yellow

$psFiles = @(Get-ChildItem -Path $scriptsFolder -Filter "*.ps1" -File | Where-Object { 
    $_.Name -notmatch "setup" -and
    $_.Name -ne "menu-selector.ps1"
})

if ($psFiles.Count -eq 0) {
    Write-Host "❌ Aucun script trouvé (autres que setup/menu)" -ForegroundColor Red
    Write-Host "Placez vos scripts métier .ps1 dans $scriptsFolder" -ForegroundColor Yellow
    Read-Host "Appuyez sur Entrée"
    exit 1
}

Write-Host "✓ $($psFiles.Count) script(s) métier trouvé(s)`n" -ForegroundColor Green

foreach ($file in $psFiles) {
    Write-Host "  • $($file.Name) ($([math]::Round($file.Length / 1KB, 1)) KB)" -ForegroundColor Gray
}

# ============================================================================
# DEMANDER LES URLs DES SCRIPTS MÉTIER UNIQUEMENT
# ============================================================================

Write-Host "`n" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "ÉTAPE 1 : Générer les URLs des scripts MÉTIER" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "Pour chaque script, générer une URL OneDrive/SharePoint :" -ForegroundColor Yellow
Write-Host "  1. Sur SharePoint, clic droit sur le fichier" -ForegroundColor Gray
Write-Host "  2. 'Copier le lien'" -ForegroundColor Gray
Write-Host "  3. Coller l'URL ci-dessous`n" -ForegroundColor Gray

Write-Host "ℹ Formats acceptés :" -ForegroundColor Cyan
Write-Host "  • OneDrive : https://1drv.ms/u/s!AxxxXXXXXXX?download=1" -ForegroundColor Gray
Write-Host "  • SharePoint : https://asgardinformatique-my.sharepoint.com/:u:/r/personal/.../file.ps1" -ForegroundColor Gray
Write-Host ""

$scriptLinks = @()

for ($i = 0; $i -lt $psFiles.Count; $i++) {
    $file = $psFiles[$i]
    $fileIndex = $i + 1
    
    Write-Host "Script $fileIndex/$($psFiles.Count) : $($file.Name)" -ForegroundColor Cyan
    
    $url = ""
    $isValid = $false
    
    while (-not $isValid) {
        $url = Read-Host "  Collez l'URL"
        
        if ([string]::IsNullOrEmpty($url)) {
            Write-Host "  ⚠ URL vide, nouvelle tentative..." -ForegroundColor Yellow
            continue
        }
        
        if ($url -like "*1drv.ms*" -or $url -like "*sharepoint.com*") {
            Write-Host "  ✓ URL valide" -ForegroundColor Green
            $isValid = $true
        } else {
            Write-Host "  ❌ URL invalide (OneDrive ou SharePoint uniquement)" -ForegroundColor Red
        }
    }
    
    $scriptLinks += @{
        FileName = $file.Name
        DisplayName = $file.Name -replace '\.ps1$', ''
        Url = $url
        Size = $file.Length
    }
    
    Write-Host ""
}

if ($scriptLinks.Count -eq 0) {
    Write-Host "❌ Aucune URL valide fournie" -ForegroundColor Red
    Read-Host "Appuyez sur Entrée"
    exit 1
}

# ============================================================================
# GÉNÉRER LE FICHIER MENU-SELECTOR.PS1
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "ÉTAPE 2 : Génération du menu-selector.ps1" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$menuContent = @"
# ============================================================================
# MENU SÉLECTEUR DE SCRIPTS - GÉNÉRÉ AUTOMATIQUEMENT
# À exécuter depuis n'importe quel PC distant (admin)
# Date génération : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ============================================================================

# FONCTION DE TÉLÉCHARGEMENT SHAREPOINT
function Download-SharePointFile {
    param(
        [Parameter(Mandatory=`$true)][string]`$Url,
        [Parameter(Mandatory=`$false)][string]`$OutFile = "`$env:TEMP\downloaded.ps1"
    )
    
    Write-Host "⏬ Téléchargement depuis SharePoint..." -ForegroundColor Cyan
    
    try {
        Write-Host "  Tentative 1/3..." -ForegroundColor Gray
        `$tempFile = "`$env:TEMP\temp-`$(Get-Random).ps1"
        Invoke-WebRequest -Uri `$Url -OutFile `$tempFile -UseBasicParsing -ErrorAction Stop
        `$content = Get-Content `$tempFile -Raw -ErrorAction Stop
        
        if (`$content -notlike "*<!DOCTYPE*" -and `$content -notlike "*<html*") {
            Move-Item `$tempFile `$OutFile -Force
            Write-Host "  ✓ Succès" -ForegroundColor Green
            return `$OutFile
        }
        Remove-Item `$tempFile -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  ⚠ Échec" -ForegroundColor Yellow
    }
    
    try {
        Write-Host "  Tentative 2/3..." -ForegroundColor Gray
        `$urlBase = `$Url -split '\?' | Select-Object -First 1
        `$urlConverted = `$urlBase -replace ":u:/r/", ""
        `$tempFile = "`$env:TEMP\temp-`$(Get-Random).ps1"
        
        Invoke-WebRequest -Uri `$urlConverted -OutFile `$tempFile -UseBasicParsing -ErrorAction Stop
        `$content = Get-Content `$tempFile -Raw -ErrorAction Stop
        
        if (`$content -notlike "*<!DOCTYPE*") {
            Move-Item `$tempFile `$OutFile -Force
            Write-Host "  ✓ Succès" -ForegroundColor Green
            return `$OutFile
        }
        Remove-Item `$tempFile -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  ⚠ Échec" -ForegroundColor Yellow
    }
    
    try {
        Write-Host "  Tentative 3/3 (accès local)..." -ForegroundColor Gray
        foreach (`$path in @(
            "D:\OneDrive - Asgard Informatique\Documents\Scripts\menu-selector.ps1",
            "`$env:USERPROFILE\OneDrive - Asgard Informatique\Documents\Scripts\menu-selector.ps1"
        )) {
            if (Test-Path `$path) {
                Copy-Item -Path `$path -Destination `$OutFile -Force
                Write-Host "  ✓ Succès (local)" -ForegroundColor Green
                return `$OutFile
            }
        }
    } catch {
        Write-Host "  ⚠ Échec" -ForegroundColor Yellow
    }
    
    Write-Host "  ❌ Impossible de télécharger" -ForegroundColor Red
    return `$null
}

# Array des scripts disponibles
`$scripts = @(
"@

for ($i = 0; $i -lt $scriptLinks.Count; $i++) {
    $link = $scriptLinks[$i]
    $scriptIndex = $i + 1
    $menuContent += @"
    @{
        Name = "$($link.DisplayName)"
        FileName = "$($link.FileName)"
        Url = "$($link.Url)"
        Size = $($link.Size)
        Index = $scriptIndex
    },
"@
}

$menuContent = $menuContent.TrimEnd(',')
$menuContent += @"
)

# ============================================================================
# MENU INTERACTIF
# ============================================================================

do {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         SCRIPTS DISPONIBLES - SÉLECTIONNEZ UN SCRIPT           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "Scripts disponibles :`n" -ForegroundColor Yellow
    
    foreach (`$script in `$scripts) {
        `$sizeKB = [math]::Round(`$script.Size / 1KB, 1)
        Write-Host "  `$(`$script.Index). `$(`$script.Name) (`$(`$sizeKB) KB)" -ForegroundColor Cyan
    }
    
    Write-Host "`n  0. Quitter`n" -ForegroundColor Yellow
    
    `$choice = Read-Host "Sélectionnez un script"
    
    if (`$choice -eq "0") {
        Write-Host "Au revoir! 👋" -ForegroundColor Cyan
        break
    }
    
    try {
        `$selectedScript = `$scripts | Where-Object { `$_.Index -eq [int]`$choice }
    }
    catch {
        `$selectedScript = `$null
    }
    
    if (`$null -ne `$selectedScript) {
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "⏬ `$(`$selectedScript.FileName)" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
        
        `$tempFile = "`$env:TEMP\asgard-script-`$(Get-Random).ps1"
        `$downloadedFile = Download-SharePointFile -Url `$selectedScript.Url -OutFile `$tempFile
        
        if (`$downloadedFile) {
            Write-Host "✓ Script téléchargé - Exécution en cours...`n" -ForegroundColor Green
            try {
                & `$downloadedFile
            }
            catch {
                Write-Host "❌ Erreur lors de l'exécution: `$_" -ForegroundColor Red
                Read-Host "Appuyez sur Entrée"
            }
            finally {
                Remove-Item `$downloadedFile -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "❌ Impossible de télécharger le script" -ForegroundColor Red
            Read-Host "Appuyez sur Entrée"
        }
    } else {
        Write-Host "❌ Choix invalide" -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
    
    Read-Host "`nAppuyez sur Entrée pour continuer"
    
} while (`$true)
"@

$menuContent | Out-File -FilePath $menuOutputPath -Encoding UTF8 -Force

Write-Host "✓ Fichier généré : $menuOutputPath`n" -ForegroundColor Green

# ============================================================================
# ÉTAPE 2 : DEMANDER L'URL DU MENU (C'EST LA SEULE URL REQUISE POUR LES DISTANTS)
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "ÉTAPE 2 : Récupérer l'URL du menu-selector.ps1" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "C'est la seule URL à partager avec les PC distants :" -ForegroundColor Yellow
Write-Host "  1. Sur SharePoint, clic droit sur menu-selector.ps1" -ForegroundColor Gray
Write-Host "  2. 'Copier le lien'" -ForegroundColor Gray
Write-Host "  3. Coller l'URL ci-dessous`n" -ForegroundColor Gray

$menuUrl = ""
$isValid = $false

while (-not $isValid) {
    $menuUrl = Read-Host "Collez l'URL du menu-selector.ps1"
    
    if ([string]::IsNullOrEmpty($menuUrl)) {
        Write-Host "⚠ URL non fournie, vous pourrez l'ajouter plus tard" -ForegroundColor Yellow
        $isValid = $true
    } else {
        if ($menuUrl -like "*1drv.ms*" -or $menuUrl -like "*sharepoint.com*") {
            Write-Host "✓ URL valide" -ForegroundColor Green
            $isValid = $true
        } else {
            Write-Host "❌ URL invalide (OneDrive ou SharePoint uniquement)" -ForegroundColor Red
        }
    }
}

# ============================================================================
# AFFICHER LE RÉSUMÉ ET LA COMMANDE À UTILISER
# ============================================================================

Write-Host "`n" -ForegroundColor Cyan
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                   CONFIGURATION TERMINÉE                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "✓ Dossier scripts : $scriptsFolder" -ForegroundColor Green
Write-Host "✓ Scripts métier enregistrés : $($scriptLinks.Count)" -ForegroundColor Green
Write-Host "✓ Fichier menu généré : menu-selector.ps1" -ForegroundColor Green

Write-Host "`n" -ForegroundColor Cyan
Write-Host "📊 Scripts disponibles dans le menu :" -ForegroundColor Cyan
foreach ($link in $scriptLinks) {
    Write-Host "  • $($link.FileName)" -ForegroundColor Gray
}

if ($menuUrl) {
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "COMMANDE UNIQUE À PARTAGER AVEC LES PC DISTANTS :" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
    
    $finalCommand = @"
&{
    `$url = "$menuUrl"
    `$tempFile = "`$env:TEMP\asgard-menu.ps1"
    Invoke-WebRequest -Uri `$url -OutFile `$tempFile -UseBasicParsing
    & `$tempFile
    Remove-Item `$tempFile -Force -ErrorAction SilentlyContinue
}
"@
    
    Write-Host $finalCommand -ForegroundColor Yellow
    
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "⚠ C'est l'UNIQUE URL à utiliser. Elle contient tous les scripts !" -ForegroundColor Yellow
} else {
    Write-Host "`n⚠ Vous devrez récupérer l'URL du menu-selector.ps1" -ForegroundColor Yellow
}

Write-Host "`n✓ Prêt à l'emploi ! 🚀" -ForegroundColor Green

Read-Host "`nAppuyez sur Entrée pour fermer"
