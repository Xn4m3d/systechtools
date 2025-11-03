# ============================================================================
# MENU SÉLECTEUR DE SCRIPTS - GÉNÉRÉ AUTOMATIQUEMENT
# À exécuter depuis n'importe quel PC distant (admin)
# GitHub Repo: systechtools
# Date génération : 2025-11-03 15:38:13
# ============================================================================

# Array des scripts disponibles
$scripts = @(    @{
        Name = "jitter"
        FileName = "jitter.ps1"
        Url = "https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/jitter.ps1"
        Size = 6596
        Index = 1
    },    @{
        Name = "maintenance-system"
        FileName = "maintenance-system.ps1"
        Url = "https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/maintenance-system.ps1"
        Size = 20028
        Index = 2
    })

# ============================================================================
# MENU INTERACTIF
# ============================================================================

do {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         SCRIPTS DISPONIBLES - SÉLECTIONNEZ UN SCRIPT           ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝
" -ForegroundColor Cyan
    
    Write-Host "Scripts disponibles :
" -ForegroundColor Yellow
    
    foreach ($script in $scripts) {
        $sizeKB = [math]::Round($script.Size / 1KB, 1)
        Write-Host "  $($script.Index). $($script.Name) ($($sizeKB) KB)" -ForegroundColor Cyan
    }
    
    Write-Host "
  0. Quitter
" -ForegroundColor Yellow
    
    $choice = Read-Host "Sélectionnez un script"
    
    if ($choice -eq "0") {
        Write-Host "Au revoir! 👋" -ForegroundColor Cyan
        break
    }
    
    try {
        $selectedScript = $scripts | Where-Object { $_.Index -eq [int]$choice }
    }
    catch {
        $selectedScript = $null
    }
    
    if ($null -ne $selectedScript) {
        Write-Host "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
        Write-Host "⏬ $($selectedScript.FileName)" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
" -ForegroundColor Cyan
        
        try {
            Write-Host "Téléchargement..." -ForegroundColor Cyan
            $tempFile = "$env:TEMP\asgard-$(Get-Random).ps1"
            Invoke-WebRequest -Uri $selectedScript.Url -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
            
            Write-Host "✓ Téléchargé - Exécution...
" -ForegroundColor Green
            & $tempFile
        }
        catch {
            Write-Host "❌ Erreur: $_" -ForegroundColor Red
            Read-Host "Appuyez sur Entrée"
        }
        finally {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "❌ Choix invalide" -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
    
    Read-Host "
Appuyez sur Entrée pour continuer"
    
} while ($true)
