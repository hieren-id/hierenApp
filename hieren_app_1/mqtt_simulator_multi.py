"""
MQTT Multi-Device Simulator - Python Version
Publish ke semua device dan sensor type sekaligus
Install: pip install paho-mqtt
Run: python mqtt_simulator_multi.py
"""

import paho.mqtt.client as mqtt
import json
import time
import random
from datetime import datetime

# Configuration
BROKER = "test.mosquitto.org"
PORT = 1883
INTERVAL = 2  # seconds (setiap 2 detik publish semua device)

# Device & Sensor Configuration
DEVICES = {
    'SP003': {  # Solar Panel untuk user1
        'name': 'Solar Panel User1',
        'sensors': {
            'pzem': {'voltage': (10, 15), 'current': (1.5, 3.5), 'power': (15, 52.5)},
            'piezo': {'voltage': (4, 6), 'current': (0.8, 1.5), 'power': (3.2, 9)},
            'teg': {'voltage': (2, 5), 'current': (0.5, 1.2), 'power': (1, 6)},
            'encoder': {'angle': (0, 90)},
            'ldr1': {'light_intensity': (500, 1000)},
            'ldr2': {'light_intensity': (600, 950)},
        }
    },
}

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print(f"\n✅ Connected to {BROKER}:{PORT}")
        print(f"📡 Will publish {len(DEVICES)} devices with multiple sensors")
        print("Press Ctrl+C to stop...\n")
    else:
        print(f"❌ Connection failed with code {rc}")

def generate_sensor_data(sensor_type, ranges):
    """Generate random sensor data berdasarkan range"""
    data = {}
    for field, (min_val, max_val) in ranges.items():
        if isinstance(min_val, int) and isinstance(max_val, int):
            data[field] = random.randint(min_val, max_val)
        else:
            data[field] = round(random.uniform(min_val, max_val), 2)
    return data

def main():
    print("\n🚀 MQTT Multi-Device Simulator (Python)")
    print("=" * 50)
    
    # Create MQTT client
    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=f"simulator_{int(time.time())}"
    )
    client.on_connect = on_connect
    
    try:
        client.connect(BROKER, PORT, 60)
        client.loop_start()
        
        count = 1
        while True:
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"\n[{timestamp}] Publish Round #{count}")
            print("-" * 50)
            
            # Iterate setiap device
            for device_id, device_info in DEVICES.items():
                device_name = device_info['name']
                sensors = device_info['sensors']
                
                # Iterate setiap sensor di device ini
                for sensor_type, ranges in sensors.items():
                    # Generate data
                    payload_data = generate_sensor_data(sensor_type, ranges)
                    payload_str = json.dumps(payload_data)
                    
                    # Build topic
                    topic = f"hieren/{device_id}/{sensor_type}"
                    
                    # Publish
                    result = client.publish(topic, payload_str, qos=1)
                    
                    if result.rc == mqtt.MQTT_ERR_SUCCESS:
                        # Format output
                        data_str = ", ".join([f"{k}={v}" for k, v in payload_data.items()])
                        print(f"  ✓ {topic:30} → {data_str}")
                    else:
                        print(f"  ✗ {topic:30} → FAILED ({result.rc})")
            
            count += 1
            print(f"\n⏳ Next publish in {INTERVAL} seconds...")
            time.sleep(INTERVAL)
            
    except KeyboardInterrupt:
        print("\n\n⏹️  Simulator stopped by user")
    except Exception as e:
        print(f"\n❌ Error: {e}")
    finally:
        client.loop_stop()
        client.disconnect()
        print("👋 Disconnected from broker")

if __name__ == "__main__":
    main()
