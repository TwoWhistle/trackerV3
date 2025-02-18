#include <Wire.h>
#include "MAX30105.h"
#include "heartRate.h" 
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

MAX30105 particleSensor;

#define SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define HR_CHARACTERISTIC "abcd1234-ab12-cd34-ef56-abcdef123456"
#define EEG_CHARACTERISTIC "abcd5678-ab12-cd34-ef56-abcdef123456"

BLECharacteristic heartRateCharacteristic(
  HR_CHARACTERISTIC,
  BLECharacteristic::PROPERTY_NOTIFY);

BLECharacteristic eegCharacteristic(
  EEG_CHARACTERISTIC,
  BLECharacteristic::PROPERTY_NOTIFY);

bool deviceConnected = false;

// Heart Rate Variables
const byte RATE_SIZE = 4;  //Increase this for more averaging. 4 is good.
byte rates[RATE_SIZE];     //Array of heart rates
byte rateSpot = 0;
long lastBeat = 0;  //Time at which the last beat occurred
float beatsPerMinute;
int beatAvg;

class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  }
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    Serial.println("❌ Disconnected! Restarting advertising...");
    pServer->getAdvertising()->start();
  }
};

void setup() {
  Serial.begin(115200);

  // ✅ Initialize MAX30102 Heart Rate Sensor
  if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("❌ MAX30102 not found. Check connections.");
    while (1)
      ;
  }

  particleSensor.setup();  // Configures sensor with default settings
  particleSensor.setPulseAmplitudeRed(0x0A);  //Turn Red LED to low to indicate sensor is running
  particleSensor.setPulseAmplitudeGreen(0);   //Turn off Green LED

  // ✅ Initialize BLE
  BLEDevice::init("ESP32_Health_Monitor");
  BLEServer* pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);
  pService->addCharacteristic(&heartRateCharacteristic);
  pService->addCharacteristic(&eegCharacteristic);

  // ✅ Add BLE2902 Descriptors
  heartRateCharacteristic.addDescriptor(new BLE2902());
  eegCharacteristic.addDescriptor(new BLE2902());

  pService->start();
  pServer->getAdvertising()->start();
}

void loop() {
    
    // Heart Rate Calculation
    long irValue = particleSensor.getIR();

    if (checkForBeat(irValue)) {
      long delta = millis() - lastBeat;
      lastBeat = millis();

      beatsPerMinute = 60 / (delta / 1000.0);
      if (beatsPerMinute < 255 && beatsPerMinute > 20) {  // Ignore unrealistic values
        rates[rateSpot++] = (byte)beatsPerMinute;
        rateSpot %= RATE_SIZE;

        beatAvg = 0;
        for (byte i = 0; i < RATE_SIZE; i++) {
          beatAvg += rates[i];
        }
        beatAvg /= RATE_SIZE;
      }
    }

    Serial.print("Raw IR Value: ");
    Serial.print(irValue);
    Serial.print(" | BPM: ");
    Serial.print(beatsPerMinute);
    Serial.print(" | Avg BPM: ");
    Serial.println(beatAvg);

    String hrString = String(beatsPerMinute);
    //String hrString = String(beatAvg);
    heartRateCharacteristic.setValue(hrString.c_str());
    heartRateCharacteristic.notify();
    Serial.println("🔵 Sent HR over BLE: " + hrString);
    

    // ✅ EEG Data Collection
    int eegSignal = analogRead(1);
    Serial.print("EEG Raw=");
    String eegString = String(eegSignal);
    eegCharacteristic.setValue(eegString.c_str());
    eegCharacteristic.notify();
    Serial.println(" Sent EEG: " + eegString);

  //delay(50);
}
