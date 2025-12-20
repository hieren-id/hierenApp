# Test MQTT Publisher - Kirim data ampere ke broker
# Install mosquitto_pub terlebih dahulu atau gunakan MQTTX

# Contoh kirim data dengan mosquitto_pub:
# mosquitto_pub -h broker.emqx.io -t "hieren/sensor/ampere" -m '{"ampere":3.2,"voltage":221.5}'

# Atau gunakan MQTTX untuk publish manual ke:
# Broker: broker.emqx.io
# Port: 1883
# Topic: hieren/sensor/ampere
# Payload: {"ampere":3.2,"voltage":221.5}

# Jika menggunakan broker lokal (Mosquitto):
# 1. Install Mosquitto di Windows
# 2. Ganti broker di mqtt_service.dart dari 'broker.emqx.io' ke 'localhost' atau IP lokal
# 3. Jalankan: mosquitto_pub -h localhost -t "hieren/sensor/ampere" -m '{"ampere":2.5,"voltage":220.0}'

Write-Host "MQTT Test Publisher Guide" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green
Write-Host ""
Write-Host "1. Buka MQTTX atau MQTT Explorer" -ForegroundColor Yellow
Write-Host "2. Connect ke broker: broker.emqx.io:1883" -ForegroundColor Yellow
Write-Host "3. Publish ke topic: hieren/sensor/ampere" -ForegroundColor Cyan
Write-Host "4. Payload format JSON:" -ForegroundColor Cyan
Write-Host '   {"ampere":3.5,"voltage":222.0}' -ForegroundColor White
Write-Host ""
Write-Host "5. Data akan otomatis:" -ForegroundColor Green
Write-Host "   - Tampil realtime di Flutter UI" -ForegroundColor White
Write-Host "   - Tersimpan ke database hieren_db" -ForegroundColor White
Write-Host ""
Write-Host "Test dengan curl (jika ada curl):" -ForegroundColor Magenta
Write-Host 'curl -X POST "http://192.168.1.16/hieren_api/save_sensor_ampere.php" -d "ampere=5.0&voltage=225.0"' -ForegroundColor White
