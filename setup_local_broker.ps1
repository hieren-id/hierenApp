# Install Mosquitto MQTT Broker di Windows
# Download dari: https://mosquitto.org/download/

# Setelah install, jalankan:
# net start mosquitto

# Atau jalankan manual:
# C:\Program Files\mosquitto\mosquitto.exe -v

# Test publish dari komputer:
# mosquitto_pub -h localhost -t "hieren/sensor/ampere" -m '{"ampere":3.5,"voltage":222.0}'

Write-Host "Setup Local MQTT Broker" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Download Mosquitto:" -ForegroundColor Yellow
Write-Host "   https://mosquitto.org/download/" -ForegroundColor White
Write-Host ""
Write-Host "2. Install dan jalankan service" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Update mqtt_service.dart:" -ForegroundColor Yellow
Write-Host "   broker = '192.168.1.16'" -ForegroundColor White
Write-Host ""
Write-Host "4. Restart Flutter app" -ForegroundColor Yellow
