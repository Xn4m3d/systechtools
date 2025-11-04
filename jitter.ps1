# ============================================================================
# JITTER ANALYZER - Network Latency & Stability Test
# Version: 2.2.2
# ============================================================================

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

param(
    [string]$ComputerName = $null,
    [int]$Count = $null,
    [int]$BufferSize = $null
)

# Default values
$defaultComputer = "8.8.8.8"
$defaultCount = 100
$defaultBuffer = 1250

# ============================================================================
# BANNER DISPLAY
# ============================================================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "║           🌐 JITTER ANALYZER - Network Stability              ║" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "║              Connection Stability Measurement                 ║" -ForegroundColor Cyan
    Write-Host "║                                                                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# ESCAPE KEY HANDLER
# ============================================================================

function Check-Escape-Key {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Escape) {
            return $true
        }
    }
    return $false
}

function Get-User-Input-With-Validation {
    param(
        [string]$Prompt,
        [string]$DefaultValue,
        [string]$InputType = "String"
    )
    
    Write-Host "   → $Prompt" -ForegroundColor Gray -NoNewline
    Write-Host " (ou ESC pour retour)" -ForegroundColor Yellow
    
    $input = Read-Host ""
    
    # Check for ESC (via empty input simulation - ESC returns null)
    if ($null -eq $input) {
        return $null
    }
    
    # If user pressed ENTER without input, use default
    if ([string]::IsNullOrWhiteSpace($input)) {
        return $DefaultValue
    }
    
    # If integer input expected, try to convert
    if ($InputType -eq "Integer") {
        try {
            return [int]$input
        } catch {
            Write-Host "   ⚠ Valeur invalide, utilisation défaut: $DefaultValue" -ForegroundColor Yellow
            return $DefaultValue
        }
    }
    
    return $input
}

# ============================================================================
# INTERACTIVE MENU
# ============================================================================

function Show-Interactive-Menu {
    Write-Host "📝 TEST CONFIGURATION" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Yellow
    
    # Target input with validation
    Write-Host "1️⃣  Target (hostname or IP address)" -ForegroundColor Cyan
    Write-Host "   Default: $defaultComputer" -ForegroundColor Gray
    $computer = Get-User-Input-With-Validation "Your choice" $defaultComputer "String"
    if ($null -eq $computer) {
        return $null  # ESC pressed
    }
    
    # Ping count input
    Write-Host ""
    Write-Host "2️⃣  Number of ping attempts" -ForegroundColor Cyan
    Write-Host "   Default: $defaultCount" -ForegroundColor Gray
    $count = Get-User-Input-With-Validation "Your choice" $defaultCount "Integer"
    if ($null -eq $count) {
        return $null  # ESC pressed
    }
    
    # Buffer size input
    Write-Host ""
    Write-Host "3️⃣  Buffer size (bytes)" -ForegroundColor Cyan
    Write-Host "   Default: $defaultBuffer" -ForegroundColor Gray
    $buffer = Get-User-Input-With-Validation "Your choice" $defaultBuffer "Integer"
    if ($null -eq $buffer) {
        return $null  # ESC pressed
    }
    
    return @{
        Computer = $computer
        Count = $count
        Buffer = $buffer
    }
}

# ============================================================================
# JITTER ANALYSIS
# ============================================================================

function Invoke-Jitter-Analysis {
    param(
        [string]$Computer,
        [int]$Count,
        [int]$Buffer
    )
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                  RUNNING PING TEST                           ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta
    
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  • Target: $Computer" -ForegroundColor Gray
    Write-Host "  • Attempts: $Count" -ForegroundColor Gray
    Write-Host "  • Buffer: $Buffer bytes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Sending pings..." -ForegroundColor Cyan
    
    try {
        # Execute ping
        $pingResults = Test-Connection -ComputerName $Computer -Count $Count -BufferSize $Buffer -ErrorAction Stop
        
        # Extract latencies
        $latencies = @()
        foreach ($result in $pingResults) {
            if ($result.PSObject.Properties.Name -contains 'Latency') {
                $latencies += $result.Latency
            } elseif ($result.PSObject.Properties.Name -contains 'ResponseTime') {
                $latencies += $result.ResponseTime
            }
        }
        
        if ($latencies.Count -eq 0) {
            Write-Host "✗ Error: No valid responses received." -ForegroundColor Red
            return
        }
        
        # Calculate statistics
        $avgLatency = ($latencies | Measure-Object -Average).Average
        $minLatency = ($latencies | Measure-Object -Minimum).Minimum
        $maxLatency = ($latencies | Measure-Object -Maximum).Maximum
        
        # Calculate jitter (standard deviation)
        $variance = ($latencies | ForEach-Object { [math]::Pow($_ - $avgLatency, 2) } | Measure-Object -Sum).Sum / $latencies.Count
        $stdDeviation = [math]::Sqrt($variance)
        
        # Display results
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                     ✓ ANALYSIS RESULTS                        ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
        
        Write-Host "📊 STATISTICS" -ForegroundColor Yellow
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Tested host" -ForegroundColor Cyan -NoNewline
        Write-Host " . . . . . . . . . . . . . . . . $Computer" -ForegroundColor White
        Write-Host "  Successful pings" -ForegroundColor Cyan -NoNewline
        Write-Host " . . . . . . . . . . . . . . $($latencies.Count)/$Count" -ForegroundColor White
        
        Write-Host ""
        Write-Host "  Average latency" -ForegroundColor Yellow -NoNewline
        Write-Host " . . . . . . . . . . . . . $([math]::Round($avgLatency, 2)) ms" -ForegroundColor White
        Write-Host "  Minimum latency" -ForegroundColor Cyan -NoNewline
        Write-Host " . . . . . . . . . . . . . . $minLatency ms" -ForegroundColor White
        Write-Host "  Maximum latency" -ForegroundColor Cyan -NoNewline
        Write-Host " . . . . . . . . . . . . . . $maxLatency ms" -ForegroundColor White
        
        Write-Host ""
        Write-Host "  Jitter (std deviation)" -ForegroundColor Magenta -NoNewline
        Write-Host " . . . . . . . . . . $([math]::Round($stdDeviation, 2)) ms" -ForegroundColor White
        Write-Host ""
        
        # Quality assessment
        Write-Host "📈 QUALITY ANALYSIS" -ForegroundColor Yellow
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""
        
        if ($stdDeviation -lt 5) {
            Write-Host "  ✓ EXCELLENT connection stability" -ForegroundColor Green
            Write-Host "    Your connection is very stable and reliable for:" -ForegroundColor Green
            Write-Host "    • Competitive online gaming" -ForegroundColor Gray
            Write-Host "    • High-quality video/audio calls" -ForegroundColor Gray
            Write-Host "    • Financial transactions" -ForegroundColor Gray
        } elseif ($stdDeviation -lt 15) {
            Write-Host "  ○ GOOD stability" -ForegroundColor Cyan
            Write-Host "    Your connection is suitable for:" -ForegroundColor Cyan
            Write-Host "    • HD video streaming" -ForegroundColor Gray
            Write-Host "    • Video calls" -ForegroundColor Gray
            Write-Host "    • General browsing" -ForegroundColor Gray
        } elseif ($stdDeviation -lt 30) {
            Write-Host "  ⚠ AVERAGE stability" -ForegroundColor Yellow
            Write-Host "    You may experience:" -ForegroundColor Yellow
            Write-Host "    • Occasional lag in gaming" -ForegroundColor Gray
            Write-Host "    • Delays in video calls" -ForegroundColor Gray
            Write-Host "    • Buffering while streaming" -ForegroundColor Gray
        } else {
            Write-Host "  ✗ HIGH INSTABILITY DETECTED" -ForegroundColor Red
            Write-Host "    Expected issues:" -ForegroundColor Red
            Write-Host "    • Frequent disconnections" -ForegroundColor Gray
            Write-Host "    • Severe lag in gaming" -ForegroundColor Gray
            Write-Host "    • Video call problems" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
        
    } catch {
        Write-Host ""
        Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║  ✗ ERROR DURING TEST" -ForegroundColor Red
        Write-Host "╚════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Red
        Write-Host "  Message: $_" -ForegroundColor Red
    }
}

# ============================================================================
# MAIN PROGRAM
# ============================================================================

function Main {
    $continue = $true
    while ($continue) {
        Show-Banner
        
        # Configuration
        if ($PSBoundParameters.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($ComputerName)) {
            $config = @{
                Computer = $ComputerName
                Count = if ($Count -gt 0) { $Count } else { $defaultCount }
                Buffer = if ($BufferSize -gt 0) { $BufferSize } else { $defaultBuffer }
            }
        } else {
            $config = Show-Interactive-Menu
            if ($null -eq $config) {
                # ESC pressed
                Write-Host ""
                Write-Host "Retour au menu principal..." -ForegroundColor Yellow
                $continue = $false
                break
            }
        }
        
        # Analysis
        Invoke-Jitter-Analysis -Computer $config.Computer -Count $config.Count -Buffer $config.Buffer
        
        # Ask to continue
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  • Appuyez sur ENTREE pour relancer le test" -ForegroundColor Gray
        Write-Host "  • Appuyez sur ESC pour retour au menu" -ForegroundColor Yellow
        
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Escape) {
            Write-Host ""
            Write-Host "Retour au menu principal..." -ForegroundColor Yellow
            $continue = $false
        }
        
        Write-Host ""
    }
}

Main