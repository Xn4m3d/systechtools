# ============================================================================
# SCRIPT JITTER - VERSION AMÉLIORÉE AVEC AFFICHAGE PROFESSIONNEL
# Analyse de latence réseau et écart-type
# ============================================================================

param(
    [string]$ComputerName = $null,
    [int]$Count = $null,
    [int]$BufferSize = $null
)

# Valeurs par défaut
$defaultComputer = "8.8.8.8"
$defaultCount = 100
$defaultBuffer = 1250

# ============================================================================
# AFFICHAGE BANNIÈRE
# ============================================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "║           🌐 ANALYSEUR JITTER - LATENCE RÉSEAU               ║" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "║              Mesure de stabilité de connexion                 ║" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# MENU INTERACTIF
# ============================================================================

function Show-InteractiveMenu {
    Write-Host "📝 CONFIGURATION DU TEST" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Yellow
    
    # Saisie du nom d'hôte/IP
    Write-Host "1️⃣  Cible (nom d'hôte ou adresse IP)" -ForegroundColor Cyan
    Write-Host "   Défaut: $defaultComputer" -ForegroundColor Gray
    $computer = Read-Host "   → Votre choix"
    if ([string]::IsNullOrWhiteSpace($computer)) {
        $computer = $defaultComputer
    }
    
    # Saisie du nombre de pings
    Write-Host ""
    Write-Host "2️⃣  Nombre de tentatives de ping" -ForegroundColor Cyan
    Write-Host "   Défaut: $defaultCount" -ForegroundColor Gray
    $countInput = Read-Host "   → Votre choix"
    if ([string]::IsNullOrWhiteSpace($countInput)) {
        $count = $defaultCount
    } else {
        try { $count = [int]$countInput } catch { $count = $defaultCount }
    }
    
    # Saisie de la taille du buffer
    Write-Host ""
    Write-Host "3️⃣  Taille du buffer (bytes)" -ForegroundColor Cyan
    Write-Host "   Défaut: $defaultBuffer" -ForegroundColor Gray
    $bufferInput = Read-Host "   → Votre choix"
    if ([string]::IsNullOrWhiteSpace($bufferInput)) {
        $buffer = $defaultBuffer
    } else {
        try { $buffer = [int]$bufferInput } catch { $buffer = $defaultBuffer }
    }
    
    return @{
        Computer = $computer
        Count = $count
        Buffer = $buffer
    }
}

# ============================================================================
# ANALYSE JITTER
# ============================================================================

function Invoke-JitterAnalysis {
    param(
        [string]$Computer,
        [int]$Count,
        [int]$Buffer
    )
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                  EXÉCUTION DU TEST DE PING                     ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta
    
    Write-Host "Paramètres:" -ForegroundColor Yellow
    Write-Host "  • Cible: $Computer" -ForegroundColor Gray
    Write-Host "  • Tentatives: $Count" -ForegroundColor Gray
    Write-Host "  • Buffer: $Buffer bytes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Envoi de pings..." -ForegroundColor Cyan
    
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
        
        # Calcul du jitter (écart-type)
        $variance = ($latencies | ForEach-Object { [math]::Pow($_ - $avgLatency, 2) } | Measure-Object -Sum).Sum / $latencies.Count
        $stdDeviation = [math]::Sqrt($variance)
        
        # Affichage des résultats
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                     ✓ RÉSULTATS ANALYSE                        ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
        
        Write-Host "📊 STATISTIQUES" -ForegroundColor Yellow
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Hôte testé" -ForegroundColor Cyan -NoNewline
        Write-Host " . . . . . . . . . . . . $Computer" -ForegroundColor White
        Write-Host "  Pings réussis" -ForegroundColor Cyan -NoNewline
        Write-Host " . . . . . . . . . . . $($latencies.Count)/$Count" -ForegroundColor White
        
        Write-Host ""
        Write-Host "  Latence moyenne" -ForegroundColor Yellow -NoNewline
        Write-Host " . . . . . . . . . . $([math]::Round($avgLatency, 2)) ms" -ForegroundColor White
        Write-Host "  Latence minimale" -ForegroundColor Cyan -NoNewline
        Write-Host " . . . . . . . . . . $minLatency ms" -ForegroundColor White
        Write-Host "  Latence maximale" -ForegroundColor Cyan -NoNewline
        Write-Host " . . . . . . . . . . $maxLatency ms" -ForegroundColor White
        
        Write-Host ""
        Write-Host "  Jitter (écart-type)" -ForegroundColor Magenta -NoNewline
        Write-Host " . . . . . . . . . $([math]::Round($stdDeviation, 2)) ms" -ForegroundColor White
        Write-Host ""
        
        # Évaluation de la qualité
        Write-Host "📈 ANALYSE DE QUALITÉ" -ForegroundColor Yellow
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        
        if ($stdDeviation -lt 5) {
            Write-Host "  ✓ EXCELLENTE stabilité de connexion" -ForegroundColor Green
            Write-Host "    Votre connexion est très stable et fiable pour:" -ForegroundColor Green
            Write-Host "    • Jeux en ligne compétitifs" -ForegroundColor Gray
            Write-Host "    • Appels vidéo/audio haute qualité" -ForegroundColor Gray
            Write-Host "    • Transactions financières" -ForegroundColor Gray
        } elseif ($stdDeviation -lt 15) {
            Write-Host "  ○ BONNE stabilité" -ForegroundColor Cyan
            Write-Host "    Votre connexion est adaptée pour:" -ForegroundColor Cyan
            Write-Host "    • Streaming vidéo HD" -ForegroundColor Gray
            Write-Host "    • Appels vidéo" -ForegroundColor Gray
            Write-Host "    • Navigation générale" -ForegroundColor Gray
        } elseif ($stdDeviation -lt 30) {
            Write-Host "  ⚠ STABILITÉ MOYENNE" -ForegroundColor Yellow
            Write-Host "    Vous pourriez expérimenter:" -ForegroundColor Yellow
            Write-Host "    • Lag occasionnel en jeux" -ForegroundColor Gray
            Write-Host "    • Décalages dans appels vidéo" -ForegroundColor Gray
            Write-Host "    • Buffering en streaming" -ForegroundColor Gray
        } else {
            Write-Host "  ✗ INSTABILITÉ ÉLEVÉE DÉTECTÉE" -ForegroundColor Red
            Write-Host "    Problèmes attendus:" -ForegroundColor Red
            Write-Host "    • Déconnexions fréquentes" -ForegroundColor Gray
            Write-Host "    • Lag important en jeux" -ForegroundColor Gray
            Write-Host "    • Problèmes d'appels vidéo" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
        
    } catch {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║  ✗ ERREUR LORS DU TEST" -ForegroundColor Red
        Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Red
        Write-Host "  Message: $_" -ForegroundColor Red
    }
}

# ============================================================================
# PROGRAMME PRINCIPAL
# ============================================================================

function Main {
    Show-Banner
    
    # Configuration
    if ($PSBoundParameters.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($ComputerName)) {
        $config = @{
            Computer = $ComputerName
            Count = if ($Count -gt 0) { $Count } else { $defaultCount }
            Buffer = if ($BufferSize -gt 0) { $BufferSize } else { $defaultBuffer }
        }
    } else {
        $config = Show-InteractiveMenu
    }
    
    # Analyse
    Invoke-JitterAnalysis -Computer $config.Computer -Count $config.Count -Buffer $config.Buffer
}

Main
