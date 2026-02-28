"""
MQTT Ampere Simulator - Python Version
Install: pip install paho-mqtt
Run: python mqtt_simulator.py
"""

import paho.mqtt.client as mqtt
import json
import time
import random
from datetime import datetime

# Configuration
BROKER = "test.mosquitto.org"
PORT = 1883
TOPIC = "hieren/sensor/user_12345"
INTERVAL = 1  # seconds

def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print(f"\n✅ Connected to {BROKER}:{PORT}")
        print(f"📡 Publishing to topic: {TOPIC}")
        print(f"⏱️  Interval: {INTERVAL} seconds")
        print("Press Ctrl+C to stop...\n")
    else:
        print(f"❌ Connection failed with code {rc}")

def generate_random_data():
    """Generate random ampere and voltage data"""
    ampere = round(random.uniform(2.0, 5.0), 2)
    voltage = round(random.uniform(218.0, 225.0), 1)
    return ampere, voltage

def main():
    print("\n🚀 MQTT Ampere Simulator (Python)")
    print("=" * 40)
    
    # Create MQTT client (compatible with paho-mqtt v2.x)
    client = mqtt.Client(
        callback_api_version=mqtt.CallbackAPIVersion.VERSION2,
        client_id=f"simulator_{int(time.time())}"
    )
    client.on_connect = on_connect
    
    try:
        # Connect to broker
        client.connect(BROKER, PORT, 60)
        client.loop_start()
        
        count = 1
        while True:
            ampere, voltage = generate_random_data()

            payload = {
                "ampere": ampere,
                "voltage": voltage
            }
            payload_str = json.dumps(payload)
            
            result = client.publish(TOPIC, payload_str, qos=1)
            
            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                timestamp = datetime.now().strftime("%H:%M:%S")
                print(f"[{timestamp}] #{count} Published: {payload_str}")
            else:
                print(f"❌ Publish failed: {result.rc}")
            
            count += 1
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
