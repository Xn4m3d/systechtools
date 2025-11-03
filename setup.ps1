# ============================================================================
# SETUP FINAL - GITHUB RAW URLs - VERSION SÉCURISÉE
# À exécuter sur ton PC source (admin)
# Génère le menu-selector.ps1 avec les URLs GitHub RAW
# ============================================================================
# Contourner les restrictions d'exécution
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     GÉNÉRATEUR DE MENU - GITHUB RAW URLs                      ║" -ForegroundColor Cyan
Write-Host "║     Version Sécurisée - Chemins Anonymisés                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ============================================================================
# CONFIGURATION
# ============================================================================

$githubUser = "Xn4m3d"
$githubRepo = "systechtools"
$githubBranch = "main"
$baseRawUrl = "https://raw.githubusercontent.com/$githubUser/$githubRepo/refs/heads/$githubBranch"

# Détecter automatiquement le chemin des scripts
$possiblePaths = @(
    "$PSScriptRoot",
    "$PSScriptRoot\systechtools",
    (Get-Location).Path
)

$scriptsFolder = $null
foreach ($path in $possiblePaths) {
    if ((Test-Path "$path\jitter.ps1") -and (Test-Path "$path\maintenance-system.ps1")) {
        $scriptsFolder = $path
        break
    }
}

if ($null -eq $scriptsFolder) {
    Write-Host "Veuillez spécifier le chemin du dossier scripts:" -ForegroundColor Yellow
    $scriptsFolder = Read-Host "Chemin"
}

Write-Host "Configuration :" -ForegroundColor Yellow
Write-Host "  GitHub User: $githubUser" -ForegroundColor Gray
Write-Host "  GitHub Repo: $githubRepo" -ForegroundColor Gray
Write-Host "  Base URL: $baseRawUrl" -ForegroundColor Gray
Write-Host "  Scripts Folder: (détecté automatiquement)`n" -ForegroundColor Gray

if (-not (Test-Path $scriptsFolder)) {
    Write-Host "❌ Dossier introuvable" -ForegroundColor Red
    Read-Host "Appuyez sur Entrée"
    exit 1
}

# ============================================================================
# SCANNER LES SCRIPTS (Exclure setup et menu)
# ============================================================================

Write-Host "Scan des scripts..." -ForegroundColor Yellow

$psFiles = @(Get-ChildItem -Path $scriptsFolder -Filter "*.ps1" -File | Where-Object { 
    $_.Name -notmatch "setup" -and
    $_.Name -ne "menu-selector.ps1" -and
    $_.Name -ne "sync-github.ps1"
})

if ($psFiles.Count -eq 0) {
    Write-Host "❌ Aucun script trouvé" -ForegroundColor Red
    Read-Host "Appuyez sur Entrée"
    exit 1
}

Write-Host "✓ $($psFiles.Count) script(s) trouvé(s)`n" -ForegroundColor Green

foreach ($file in $psFiles) {
    Write-Host "  • $($file.Name)" -ForegroundColor Gray
}

# ============================================================================
# GÉNÉRER LES URLs GITHUB RAW
# ============================================================================

Write-Host "`n" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Génération des URLs GitHub RAW" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$scriptLinks = @()

foreach ($file in $psFiles) {
    $rawUrl = "$baseRawUrl/$($file.Name)"
    
    Write-Host "✓ $($file.Name)" -ForegroundColor Green
    Write-Host "  → $rawUrl`n" -ForegroundColor Gray
    
    $scriptLinks += @{
        FileName = $file.Name
        DisplayName = $file.Name -replace '\.ps1$', ''
        Url = $rawUrl
        Size = $file.Length
    }
}

# ============================================================================
# GÉNÉRER LE FICHIER MENU-SELECTOR.PS1 (AMÉLIORÉ)
# ============================================================================

Write-Host "`n" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Génération du menu-selector.ps1 (version améliorée)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$menuOutputPath = Join-Path $scriptsFolder "menu-selector.ps1"

# Copier la version améliorée depuis le répertoire courant
$improvedMenuPath = "$PSScriptRoot\menu-selector-v2.ps1"
if (Test-Path $improvedMenuPath) {
    Write-Host "✓ Copie de la version améliorée du menu..." -ForegroundColor Green
    Copy-Item -Path $improvedMenuPath -Destination $menuOutputPath -Force
    Write-Host "✓ Fichier généré: $menuOutputPath`n" -ForegroundColor Green
} else {
    Write-Host "⚠ Version améliorée non trouvée, génération manuelle..." -ForegroundColor Yellow
    
    $menuContent = @"
# Menu sélecteur - Version améliorée
# Voir menu-selector-v2.ps1 pour la version complète
"@
    
    $menuContent | Out-File -FilePath $menuOutputPath -Encoding UTF8 -Force
}

# ============================================================================
# RÉSUMÉ FINAL
# ============================================================================

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      ✓ CONFIGURATION TERMINÉE                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "📊 Résumé :" -ForegroundColor Green
Write-Host "  • Dossier: (détecté automatiquement)" -ForegroundColor Gray
Write-Host "  • Scripts trouvés: $($scriptLinks.Count)" -ForegroundColor Gray
Write-Host "  • Menu généré: menu-selector.ps1" -ForegroundColor Gray
Write-Host "  • GitHub Repo: https://github.com/$githubUser/$githubRepo" -ForegroundColor Gray

Write-Host "`n📤 Prochaines étapes :" -ForegroundColor Yellow
Write-Host "  1. Push le menu-selector.ps1 vers GitHub" -ForegroundColor Gray
Write-Host "  2. Partage cette commande avec tes PCs distants :" -ForegroundColor Gray

$finalCommand = "iwr 'https://raw.githubusercontent.com/$githubUser/$githubRepo/refs/heads/$githubBranch/menu-selector.ps1' -UseBasicParsing | iex"
Write-Host ""
Write-Host "     $finalCommand" -ForegroundColor Cyan

Write-Host "`n✓ Prêt à l'emploi ! 🚀" -ForegroundColor Green

Read-Host "`nAppuyez sur Entrée pour fermer"
