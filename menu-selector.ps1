Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$scripts = @()
$scripts += @{ Name = 'jitter'; Url = 'https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/jitter.ps1' }
$scripts += @{ Name = 'maintenance-system'; Url = 'https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/maintenance-system.ps1' }

$continue = $true
while ($continue) {
    Write-Host ""
    Write-Host "MENU SYSTECHTOOLS" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $scripts.Count; $i++) {
        Write-Host "$($i + 1). $($scripts[$i].Name)" -ForegroundColor Yellow
    }
    Write-Host "0. Quitter" -ForegroundColor Yellow
    
    $choice = Read-Host "Choisissez"
    
    if ($choice -eq "0") {
        Write-Host "Au revoir !" -ForegroundColor Green
        $continue = $false
    } else {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $scripts.Count) {
            $script = $scripts[$index]
            Write-Host "Execution de $($script.Name)..." -ForegroundColor Green
            iex (New-Object Net.WebClient).DownloadString($script.Url)
            Read-Host "Appuyez sur Entree"
        }
    }
}
