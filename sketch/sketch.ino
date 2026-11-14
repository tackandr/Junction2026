#include <Arduino_Modulino.h>
#include <Arduino_RouterBridge.h>

ModulinoThermo thermo;

float readTemperature() {
  return thermo.getTemperature();
}

float readHumidity() {
  return thermo.getHumidity();
}

void setup() {
  Modulino.begin();
  thermo.begin();

  Bridge.begin();
  Bridge.provide("read_temperature", readTemperature);
  Bridge.provide("read_humidity", readHumidity);
}

void loop() {
  // The Linux app requests a reading every 10 seconds.
}
