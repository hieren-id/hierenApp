# Quick MQTT Simulator - No dependencies needed (if Mosquitto installed)
# Just run: .\quick_simulator.ps1

Write-Host "`n🎯 Quick MQTT Simulator" -ForegroundColor Green
Write-Host "=====================`n" -ForegroundColor Green

# Check Mosquitto installation
$mosquittoPath = "C:\Program Files\mosquitto\mosquitto_pub.exe"
if (-not (Test-Path $mosquittoPath)) {
    Write-Host "❌ Mosquitto not found at: $mosquittoPath" -ForegroundColor Red
    Write-Host "`nDownload from: https://mosquitto.org/download/`n" -ForegroundColor Yellow
    
    Write-Host "Or use Python simulator instead:" -ForegroundColor Cyan
    Write-Host "  pip install paho-mqtt" -ForegroundColor White
    Write-Host "  python mqtt_simulator.py`n" -ForegroundColor White
    exit
}

$broker = "test.mosquitto.org"
$topic = "hieren/sensor/ampere/user_12345"
$interval = 3

Write-Host "Broker: $broker" -ForegroundColor Cyan
Write-Host "Topic: $topic" -ForegroundColor Cyan
Write-Host "Interval: $interval seconds" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop...`n" -ForegroundColor Red

$count = 1
try {
    while ($true) {
        # Random ampere: 2.0 - 5.0A
        $ampere = [math]::Round((Get-Random -Minimum 200 -Maximum 500) / 100, 2)
        
        # Random voltage: 218.0 - 225.0V
        $voltage = [math]::Round(218 + (Get-Random -Minimum 0 -Maximum 700) / 100, 1)
        
        # Create JSON payload
        $payload = "{`"ampere`":$ampere,`"voltage`":$voltage}"
        
        # Publish using mosquitto_pub
        & $mosquittoPath -h $broker -t $topic -m $payload -q 1
        
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestamp] #$count $payload" -ForegroundColor Green
        
        $count++
        Start-Sleep -Seconds $interval
    }
}
catch {
    Write-Host "`n⏹️  Stopped" -ForegroundColor Yellow
}
