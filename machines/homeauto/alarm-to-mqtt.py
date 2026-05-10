import paho.mqtt.client as mqtt
from alarmdecoder import AlarmDecoder
from alarmdecoder.devices import SerialDevice
from functools import partial


def main():
    """
    Connects AlarmDecoder to MQTT
    """
    try:
        mqttc = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
        device = AlarmDecoder(SerialDevice(interface='/dev/ttyUSB0'))
        mqttc.on_connect = on_connect
        mqttc.on_message = partial(on_mqtt_message, device)
        mqttc.connect("localhost", 1883, 60)

        device.on_arm += partial(alarm_armed, mqttc)
        device.on_disarm += partial(alarm_disarmed, mqttc)
        # TODO: Handle on_alarm and on_alarm_restored

        with device.open(baudrate=115200):
            mqttc.loop_forever()

    except Exception as ex:
        print('Exception:', ex)


def on_mqtt_message(adDevice, client, userdata, msg):
    adDevice.send(msg.payload)
    print(msg.topic+" "+str(msg.payload))


# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, reason_code, properties):
    print(f"Connected with result code {reason_code}")
    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("homealarm/set/#")


def alarm_armed(mqttc, device, stay):
    # TODO: Handle stay to communicate how it was armed
    if stay:
        mqttc.publish("homealarm/armed_stay", True, retain=True)
    else:
        mqttc.publish("homealarm/armed_away", True, retain=True)
    mqttc.publish("homealarm/armed", True, retain=True)


def alarm_disarmed(mqttc, device):
    mqttc.publish("homealarm/armed", False)
    mqttc.publish("homealarm/armed_stay", False)
    mqttc.publish("homealarm/armed_away", False)


if __name__ == '__main__':
    main()
