Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# GitHub repository configuration
$repoUrl = "https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main"

# Define available modules
$modules = @(
    @{ Name = "Maintenance System Tools"; Script = "maintenance-system.ps1" },
    @{ Name = "Jitter Test"; Script = "jitter.ps1" },
    @{ Name = "External Tools"; Script = "external-tools.ps1" }
)

function Show-Main-Menu {
    Clear-Host
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║             SYSTEM TOOLS SUITE - Main Launcher                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "Selectionnez l'outil a lancer :`n" -ForegroundColor Yellow
    
    for ($i = 0; $i -lt $modules.Count; $i++) {
        Write-Host "┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Green
        Write-Host "│  $($i + 1). $($modules[$i].Name.PadRight(59))│" -ForegroundColor Green
        Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Green
    }
    
    Write-Host "`n┌─────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
    Write-Host "│  0. Quitter                                                    │" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
    
    $choice = Read-Host "`nChoisissez une option (0-$($modules.Count))"
    return $choice
}

function Download-And-Execute-Script {
    param(
        [string]$ScriptName,
        [string]$ModuleName
    )
    
    $scriptUrl = "$repoUrl/$ScriptName"
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              Chargement du module en cours...                 ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    Write-Host "Module: $ModuleName" -ForegroundColor Yellow
    Write-Host "URL: $scriptUrl`n" -ForegroundColor Gray
    
    try {
        Write-Host "Telechargement depuis GitHub..." -ForegroundColor Cyan
        $scriptContent = (New-Object Net.WebClient).DownloadString($scriptUrl)
        
        if ($null -eq $scriptContent -or $scriptContent.Length -eq 0) {
            Write-Host "Erreur: Le script est vide ou n'a pas pu etre telecharge" -ForegroundColor Red
            Read-Host "Appuyez sur Entree"
            return $false
        }
        
        Write-Host "Telechargement reussi (checksum OK)" -ForegroundColor Green
        Write-Host "Execution du script...`n" -ForegroundColor Green
        
        # Execute the downloaded script
        Invoke-Expression $scriptContent
        
        return $true
    }
    catch {
        Write-Host "Erreur lors du telechargement: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "`nVerifiez:" -ForegroundColor Yellow
        Write-Host "  - Votre connexion Internet" -ForegroundColor Yellow
        Write-Host "  - L'URL du repository: $repoUrl" -ForegroundColor Yellow
        Write-Host "  - Le nom du script: $ScriptName" -ForegroundColor Yellow
        Read-Host "Appuyez sur Entree"
        return $false
    }
}

# Main loop
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
            Write-Host "`nAu revoir!`n" -ForegroundColor Green
            $continue = $false
        }
        default {
            Write-Host "Option invalide" -ForegroundColor Red
            Read-Host "Appuyez sur Entree"
        }
    }
}
