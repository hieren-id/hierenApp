# MQTT Realtime Integration - Hieren App

## 📡 Cara Kerja

```
[Sensor Ampere] → [MQTT Broker] → [Flutter App] → [MySQL Database]
                        ↓                ↓
                   Topic: hieren/      UI Update
                   sensor/ampere       Realtime
```

## 🔧 Konfigurasi MQTT

### File: `lib/services/mqtt_service.dart`

```dart
// Default menggunakan public broker
static const String broker = 'broker.emqx.io';
static const String ampereTopic = 'hieren/sensor/ampere';
```

### Ganti ke Broker Lokal (Opsional)

Jika ingin pakai broker lokal (Mosquitto/EMQX):

1. Install MQTT Broker (Mosquitto recommended)
2. Ubah di `mqtt_service.dart`:
   ```dart
   static const String broker = '192.168.1.16'; // IP komputer
   static const int port = 1883;
   ```

## 📤 Format Data MQTT

### Topic: `hieren/sensor/ampere`

### Payload JSON:
```json
{
  "ampere": 3.2,
  "voltage": 221.5
}
```

### Contoh Minimal (tanpa voltage):
```json
{
  "ampere": 2.5
}
```

## 🧪 Testing dengan MQTTX

### 1. Download MQTTX
- Link: https://mqttx.app/

### 2. Buat Koneksi Baru
- **Name**: Hieren Test
- **Host**: mqtt://broker.emqx.io
- **Port**: 1883
- **Client ID**: (biarkan auto-generate)

### 3. Publish Test Data
- **Topic**: `hieren/sensor/ampere`
- **QoS**: 1
- **Payload**:
  ```json
  {"ampere":3.5,"voltage":222.0}
  ```

### 4. Lihat Hasil
- ✅ Flutter UI update otomatis (angka ampere berubah)
- ✅ Data tersimpan ke database `sensor_ampere`
- ✅ Indikator "MQTT Live" hijau di header

## 🗄️ Database Auto-Save

Setiap data MQTT yang diterima **otomatis disimpan** ke database:

```sql
INSERT INTO sensor_ampere (ampere, voltage) 
VALUES (3.5, 222.0);
```

Cek database:
```sql
SELECT * FROM sensor_ampere 
ORDER BY created_at DESC 
LIMIT 10;
```

## 📊 Fitur Realtime di Flutter

### 1. Stream Subscription
```dart
_mqttService.ampereStream.listen((ampereData) {
  setState(() {
    sensorAmpere = ampereData; // UI update otomatis
  });
});
```

### 2. Display Realtime
- Current reading: **X.XX A**
- Voltage: **XXX.X V**
- Timestamp: Auto-update setiap ada data baru

### 3. MQTT Status Indicator
- 🟢 **"MQTT Live"** = Connected
- ⚪ **"MQTT Off"** = Disconnected

## 🔌 Flow Data Lengkap

### 1. Sensor → MQTT Broker
```
ESP32/Arduino → WiFi → Publish ke broker.emqx.io
Topic: hieren/sensor/ampere
Payload: {"ampere":2.8,"voltage":220.5}
```

### 2. Flutter Subscribe
```
App Start → Connect ke broker → Subscribe topic
↓
Terima data → Parse JSON → Update UI
```

### 3. Auto-Save Database
```
Data diterima → Call API → save_sensor_ampere.php
↓
MySQL INSERT → Response success
↓
Console log: "✅ Ampere data saved to DB: 2.8A"
```

### 4. Load Historical Data
```
Pull to refresh → read_sensor_ampere.php
↓
Get latest 10 records → Plot grafik
```

## 🚀 Quick Start

### 1. Jalankan Flutter App
```bash
flutter run -d windows
# atau
flutter run -d chrome
```

### 2. Pastikan MQTT Connect
Lihat console log:
```
🔌 Connecting to MQTT broker: broker.emqx.io:1883
✅ Connected to MQTT broker
📡 Subscribing to topic: hieren/sensor/ampere
```

### 3. Test Publish (MQTTX)
```json
Topic: hieren/sensor/ampere
Payload: {"ampere":4.2,"voltage":223.0}
```

### 4. Lihat Hasil di App
- Angka ampere berubah **instant**
- Indikator MQTT hijau
- Database otomatis update

## 🛠️ Troubleshooting

### MQTT Not Connected
- ❌ Cek internet connection
- ❌ Cek firewall (port 1883 harus terbuka)
- ✅ Pastikan broker address benar

### Data Tidak Update
- ❌ Cek topic name (case-sensitive)
- ❌ Cek format JSON payload
- ✅ Lihat console log untuk error

### Database Tidak Save
- ❌ XAMPP Apache/MySQL running?
- ❌ IP address masih `192.168.1.16`?
- ✅ Test manual: `http://192.168.1.16/hieren_api/save_sensor_ampere.php`

## 📝 Log Reference

### Success Logs
```
✅ Connected to MQTT broker
📡 Subscribing to topic: hieren/sensor/ampere
📩 Received from hieren/sensor/ampere: {"ampere":2.5,"voltage":220.0}
✅ Ampere data saved to DB: 2.5A
📊 UI Updated: 2.5A
```

### Error Logs
```
❌ MQTT Connection failed: SocketException
❌ Error parsing ampere data: FormatException
⚠️ Failed to save: Connection timeout
```

## 🔐 Production Setup (Opsional)

### 1. Private Broker dengan Auth
```dart
final connMessage = MqttConnectMessage()
    .withClientIdentifier(clientId)
    .authenticateAs('username', 'password')
    .startClean();
```

### 2. SSL/TLS Connection
```dart
client = MqttServerClient.withPort(broker, clientId, 8883);
client!.secure = true;
```

### 3. Custom Topic per Device
```dart
static const String ampereTopic = 'hieren/device001/sensor/ampere';
```

## 📱 Integration dengan Hardware

### ESP32/Arduino Example
```cpp
#include <WiFi.h>
#include <PubSubClient.h>

const char* mqtt_server = "broker.emqx.io";
const char* topic = "hieren/sensor/ampere";

void loop() {
  float ampere = analogRead(A0) * 0.01; // Baca sensor
  float voltage = 220.0;
  
  String payload = "{\"ampere\":" + String(ampere) + 
                   ",\"voltage\":" + String(voltage) + "}";
  
  client.publish(topic, payload.c_str());
  delay(5000); // Kirim setiap 5 detik
}
```

---

**Created**: December 12, 2025  
**Version**: 1.0  
**Status**: ✅ Production Ready
