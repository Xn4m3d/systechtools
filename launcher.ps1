Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$repoUrl = "https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main"

$modules = @(
    @{ Name = "Maintenance System Tools"; Script = "maintenance-system.ps1" },
    @{ Name = "Jitter Test"; Script = "jitter.ps1" },
    @{ Name = "External Tools"; Script = "external-tools.ps1" }
)

function Show-Main-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║             SYSTEM TOOLS SUITE - Main Launcher                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Selectionnez l'outil a lancer :" -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 0; $i -lt $modules.Count; $i++) {
        Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
        Write-Host "│  $($i + 1). $($modules[$i].Name.PadRight(59))│" -ForegroundColor Green
        Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│  0. Quitter                                                    │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    Write-Host ""
    
    $choice = Read-Host "Choisissez une option (0-$($modules.Count))"
    return $choice
}

function Download-And-Execute-Script {
    param(
        [string]$ScriptName,
        [string]$ModuleName
    )
    
    $scriptUrl = "$repoUrl/$ScriptName"
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              Chargement du module en cours...                 ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Module: $ModuleName" -ForegroundColor Yellow
    Write-Host "URL: $scriptUrl" -ForegroundColor Gray
    Write-Host ""
    
    try {
        Write-Host "Telechargement depuis GitHub..." -ForegroundColor Cyan
        
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        $scriptContent = (New-Object Net.WebClient).DownloadString($scriptUrl)
        
        if ($null -eq $scriptContent -or $scriptContent.Length -eq 0) {
            Write-Host "Erreur: Le script est vide" -ForegroundColor Red
            Read-Host "Appuyez sur Entree"
            return $false
        }
        
        Write-Host "Telechargement reussi" -ForegroundColor Green
        Write-Host "Execution du script..." -ForegroundColor Green
        Write-Host ""
        
        Invoke-Expression $scriptContent
        
        return $true
    }
    catch {
        Write-Host ""
        Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "Verifiez:" -ForegroundColor Yellow
        Write-Host "  - Votre connexion Internet" -ForegroundColor Yellow
        Write-Host "  - L'URL: $repoUrl" -ForegroundColor Yellow
        Write-Host "  - Le script: $ScriptName" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Appuyez sur Entree"
        return $false
    }
}

$continue = $true
while ($continue) {
    $choice = Show-Main-Menu
    
    switch ($choice) {
        "1" {
            Download-And-Execute-Script -ScriptName $modules[0].Script -ModuleName $modules[0].Name
        }
        "2" {
            Download-And-Execute-Script -ScriptName $modules[1].Script -ModuleName $modules[1].Name
        }
        "3" {
            Download-And-Execute-Script -ScriptName $modules[2].Script -ModuleName $modules[2].Name
        }
        "0" {
            Write-Host ""
            Write-Host "Au revoir!" -ForegroundColor Green
            Write-Host ""
            $continue = $false
        }
        default {
            Write-Host "Option invalide" -ForegroundColor Red
            Read-Host "Appuyez sur Entree"
        }
    }
}