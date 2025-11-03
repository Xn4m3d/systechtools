# Script PowerShell - Analyse Jitter via Ping
# Fonction interactive pour mesurer la latence et l'écart-type (jitter)

param(
    [string]$ComputerName = $null,
    [int]$Count = $null,
    [int]$BufferSize = $null
)

# Valeurs par défaut
$defaultComputer = "8.8.8.8"
$defaultCount = 100
$defaultBuffer = 1250

function Show-InteractiveMenu {
    <#
    .SYNOPSIS
    Affiche un menu interactif pour la saisie des paramètres de ping
    #>
    
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║    Analyseur Jitter - Ping Avancé     ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Saisie du nom d'hôte/IP
    Write-Host "1. Nom d'hôte ou adresse IP à tester" -ForegroundColor Yellow
    Write-Host "   Défaut: $defaultComputer" -ForegroundColor Gray
    $computer = Read-Host "   Entrez la valeur (ou appuyez sur Entrée pour le défaut)"
    if ([string]::IsNullOrWhiteSpace($computer)) {
        $computer = $defaultComputer
    }
    
    # Saisie du nombre de pings
    Write-Host ""
    Write-Host "2. Nombre de tentatives de ping" -ForegroundColor Yellow
    Write-Host "   Défaut: $defaultCount" -ForegroundColor Gray
    $countInput = Read-Host "   Entrez la valeur (ou appuyez sur Entrée pour le défaut)"
    if ([string]::IsNullOrWhiteSpace($countInput)) {
        $count = $defaultCount
    } else {
        $count = [int]$countInput
    }
    
    # Saisie de la taille du buffer
    Write-Host ""
    Write-Host "3. Taille du buffer en bytes" -ForegroundColor Yellow
    Write-Host "   Défaut: $defaultBuffer" -ForegroundColor Gray
    $bufferInput = Read-Host "   Entrez la valeur (ou appuyez sur Entrée pour le défaut)"
    if ([string]::IsNullOrWhiteSpace($bufferInput)) {
        $buffer = $defaultBuffer
    } else {
        $buffer = [int]$bufferInput
    }
    
    return @{
        Computer = $computer
        Count = $count
        Buffer = $buffer
    }
}

function Invoke-JitterAnalysis {
    <#
    .SYNOPSIS
    Exécute l'analyse de latence et calcule le jitter (écart-type)
    #>
    
    param(
        [string]$Computer,
        [int]$Count,
        [int]$Buffer
    )
    
    Write-Host ""
    Write-Host "▶ Lancement du test de ping..." -ForegroundColor Cyan
    Write-Host "  Cible: $Computer | Tentatives: $Count | Buffer: $Buffer bytes" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # Exécution du ping
        $pingResults = Test-Connection -ComputerName $Computer -Count $Count -BufferSize $Buffer -ErrorAction Stop
        
        # Extraction des latences
        $latencies = @()
        foreach ($result in $pingResults) {
            if ($result.PSObject.Properties.Name -contains 'Latency') {
                $latencies += $result.Latency
            } elseif ($result.PSObject.Properties.Name -contains 'ResponseTime') {
                $latencies += $result.ResponseTime
            }
        }
        
        if ($latencies.Count -eq 0) {
            Write-Host "✗ Erreur : Aucune réponse valide reçue." -ForegroundColor Red
            return
        }
        
        # Calcul des statistiques
        $avgLatency = ($latencies | Measure-Object -Average).Average
        $minLatency = ($latencies | Measure-Object -Minimum).Minimum
        $maxLatency = ($latencies | Measure-Object -Maximum).Maximum
        
        # Calcul de l'écart-type (jitter/std deviation)
        $variance = ($latencies | ForEach-Object { [math]::Pow($_ - $avgLatency, 2) } | Measure-Object -Sum).Sum / $latencies.Count
        $stdDeviation = [math]::Sqrt($variance)
        
        # Affichage des résultats
        Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║          RÉSULTATS DE L'ANALYSE       ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "Hôte testé      : $Computer" -ForegroundColor White
        Write-Host "Pings réussis   : $($latencies.Count)/$Count" -ForegroundColor White
        Write-Host ""
        Write-Host "Latence moyenne : $([math]::Round($avgLatency, 2)) ms" -ForegroundColor Yellow
        Write-Host "Latence min     : $minLatency ms" -ForegroundColor Cyan
        Write-Host "Latence max     : $maxLatency ms" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Jitter (écart-type) : $([math]::Round($stdDeviation, 2)) ms" -ForegroundColor Magenta
        Write-Host ""
        
        # Évaluation de la qualité de la connexion
        Write-Host "Analyse de qualité :" -ForegroundColor Yellow
        if ($stdDeviation -lt 5) {
            Write-Host "  ✓ Excellente stabilité de connexion" -ForegroundColor Green
        } elseif ($stdDeviation -lt 15) {
            Write-Host "  ○ Bonne stabilité" -ForegroundColor Cyan
        } elseif ($stdDeviation -lt 30) {
            Write-Host "  ⚠ Stabilité moyenne" -ForegroundColor Yellow
        } else {
            Write-Host "  ✗ Instabilité élevée détectée" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
    } catch {
        Write-Host "✗ Erreur lors du ping: $_" -ForegroundColor Red
    }
}

# Point d'entrée principal
function Main {
    # Si les paramètres sont fournis en ligne de commande, les utiliser
    if ($PSBoundParameters.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($ComputerName)) {
        $config = @{
            Computer = $ComputerName
            Count = if ($Count -gt 0) { $Count } else { $defaultCount }
            Buffer = if ($BufferSize -gt 0) { $BufferSize } else { $defaultBuffer }
        }
    } else {
        # Sinon, afficher le menu interactif
        $config = Show-InteractiveMenu
    }
    
    # Lancer l'analyse
    Invoke-JitterAnalysis -Computer $config.Computer -Count $config.Count -Buffer $config.Buffer
}

# Exécution du script
Main
