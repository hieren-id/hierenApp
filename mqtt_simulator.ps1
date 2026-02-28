# MQTT Simulator - Kirim data ampere random setiap 3 detik
# Butuh: npm install -g mqtt (install Node.js dulu)

param(
    [int]$interval = 3  # detik
)

Write-Host "`n🚀 MQTT Ampere Simulator" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host "Broker: test.mosquitto.org:1883" -ForegroundColor Cyan
Write-Host "Topic: hieren/sensor/ampere/user_12345" -ForegroundColor Cyan
Write-Host "Interval: $interval seconds" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop...`n" -ForegroundColor Red

# Check if mosquitto_pub installed
$mosquittoPath = Get-Command mosquitto_pub -ErrorAction SilentlyContinue

if (-not $mosquittoPath) {
    Write-Host "❌ mosquitto_pub not found!" -ForegroundColor Red
    Write-Host "`nInstall options:" -ForegroundColor Yellow
    Write-Host "1. Download Mosquitto: https://mosquitto.org/download/" -ForegroundColor White
    Write-Host "2. Or use Python script below" -ForegroundColor White
    exit
}

$count = 1
while ($true) {
    # Generate random ampere (2.0 - 5.0A) and voltage (218-225V)
    $ampere = [math]::Round((Get-Random -Minimum 200 -Maximum 500) / 100, 2)
    $voltage = [math]::Round((Get-Random -Minimum 218 -Maximum 225) + ((Get-Random -Minimum 0 -Maximum 100) / 100), 1)
    
    $payload = "{`"ampere`":$ampere,`"voltage`":$voltage}"
    
    # Publish to MQTT
    & mosquitto_pub -h test.mosquitto.org -t "hieren/sensor/ampere/user_12345" -m $payload
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] #$count Published: $payload" -ForegroundColor Green
    
    $count++
    Start-Sleep -Seconds $interval
}
