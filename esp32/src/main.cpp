#include <Arduino.h>
#include <WiFi.h>

#include "smartgb.h"
#include "secret.h"
#include "serial.h"

//load modules (yes having the modules reside in header files probably isnt the best idea but its the best i could come up with)
#include "modules/discord.h"
Module* modules[] = {new Discord};

//const byte gif[] = {0x47,0x49,0x46,0x38,0x39,0x61,0x02,0x00,0x02,0x00,0x70,0x00,0x00,0x2C,0x00,0x00,0x00,0x00,0x02,0x00,0x02,0x00,0x81,0xFF,0x00,0x08,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x02,0x02,0x84,0x51,0x00,0x3B};

volatile bool rcv_complete = false;

void IRAM_ATTR onSerialData() { rcv_complete = true; }

void setup() {
  Serial.begin(115200);

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
  }
  Serial.println("WiFi connected.");

  init_serial(&onSerialData);

  modules[0]->typing_start();
  delay(3000);
  modules[0]->send((char*)"Hello World!");
}

//Terrible function i use for debugging
String id_names[] = {"ping", "ack", "req", "res", "stat", "msg"};
void printBuf() {
  serial_packet packet = get_current_packet();
  String msg = "ID: ";
  msg.concat(id_names[packet.id]);
  msg.concat(", Length: ");
  msg.concat(packet.size);
  msg.concat(", Data: ");
  for(int i = 0; i < packet.size; i++) {
    msg.concat(packet.data[i]);
    msg.concat(" ");
  }
  Serial.println(msg);
}

void loop() {
  if(rcv_complete) {
    //printBuf();
    serial_packet packet = get_current_packet();
    /* switch (packet.id) {
    case ID_REQ:
    
      break;
    
    default:
      Serial.print("Received unknown packet: ");
      printBuf();
      break;
    } */

    rcv_complete = false;
  }
}