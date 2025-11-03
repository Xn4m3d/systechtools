# Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

function Require-Admin {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    
    if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Ce script nécessite les droits administrateur. Redémarrage..." -ForegroundColor Red
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File "$PSCommandPath"" -Verb RunAs
        exit
    }
}

Require-Admin

$scripts = @(    @{ Name = "jitter"; Url = "https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/jitter.ps1" },
    @{ Name = "maintenance-system"; Url = "https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/maintenance-system.ps1" },
)

$continue = $true
while ($continue) {
    Write-Host "
╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  MENU SYSTECHTOOLS                      ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝
" -ForegroundColor Cyan

    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host "$($i + 1). $($scripts[$i].Name)" -ForegroundColor Yellow
    }
    Write-Host "0. Quitter" -ForegroundColor Yellow

    $choice = Read-Host "
Choisissez une option"

    if ($choice -eq "0") {
        Write-Host "Au revoir !" -ForegroundColor Green
        $continue = $false
    } else {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $scripts.Count) {
            $script = $scripts[$index]
            Write-Host "
Exécution de $($script.Name)...
" -ForegroundColor Green
            try {
                iex (New-Object Net.WebClient).DownloadString($script.Url)
            } catch {
                Write-Host "❌ Erreur: $_" -ForegroundColor Red
            }
            Read-Host "
Appuyez sur Entrée pour retourner au menu"
        } else {
            Write-Host "❌ Option invalide" -ForegroundColor Red
        }
    }
}
