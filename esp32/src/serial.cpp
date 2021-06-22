#include <Arduino.h>

#include "smartgb.h"
#include "serial.h"

volatile byte buf[8192]; //8KiB 
volatile int buf_ptr = 0;
volatile int byte_progress = 0;

CallbackType onSerialData;

hw_timer_t * int_clk = NULL;
volatile bool int_clk_state = true;

void IRAM_ATTR ext_clk_isr();

void init_send() {
  byte_progress = 7;
  detachInterrupt(digitalPinToInterrupt(GPIO_CLK));
  pinMode(GPIO_CLK, OUTPUT);
  timerAlarmEnable(int_clk);
}

void switch_to_slave() {
  buf_ptr = 0;
  byte_progress = 0;
  timerAlarmDisable(int_clk);
  pinMode(GPIO_CLK, INPUT);
  attachInterrupt(digitalPinToInterrupt(GPIO_CLK), ext_clk_isr, RISING);
}

void gb_send(serial_packet packet) {
  if(packet.size != 0) {
    buf[packet.size+2] = packet.id;
    buf[packet.size+1] = ((packet.size >> 8) & 0xFF);
    buf[packet.size] = (packet.size & 0xFF);

    for(int i = 0; i < packet.size; i++) {
      buf[packet.size-i-1] = packet.data[i];
    }
    buf_ptr = packet.size + 3;
  } else {
    buf[0] = packet.id;
    buf_ptr = 1;
  }

  if(packet.id==ID_RES) { //We dont send the ID if the message is a response to save resources on the gameboy
    buf_ptr--;
  }

  init_send();
}

void IRAM_ATTR ext_clk_isr() {
  buf[buf_ptr] = buf[buf_ptr] << 1;
  buf[buf_ptr] += digitalRead(GPIO_GOCI);
  
  byte_progress++;
  if(byte_progress > 7) {
    byte_progress = 0;
    buf_ptr++;

    if(buf[0] == ID_PING || buf[0] == ID_ACK) { //ID_PING + ID_ACK are the only messages without header/content the gameboy can send
      onSerialData();
    } else if(buf_ptr == ((buf[1]<<8) | buf[2]) + 3 && buf_ptr > 2) { //convert the two 8bit headers back into one 16 bit number and check if received message is the same length
      onSerialData();
    }
  }
}

void IRAM_ATTR int_clk_isr() {
  int_clk_state = !int_clk_state;
  digitalWrite(GPIO_CLK, int_clk_state);

  if(!int_clk_state) { //negative edge
    digitalWrite(GPIO_GICO, bitRead(buf[buf_ptr-1], byte_progress));

    byte_progress--;
    if(byte_progress < 0) {
      byte_progress = 7;
      buf_ptr--;
    }
  } else { //positive edge
    if(buf_ptr == 0) {
        switch_to_slave();
      }
  }
}

void init_serial(CallbackType onSerialDataCB) {
  onSerialData = onSerialDataCB;

  pinMode(GPIO_GOCI, INPUT);
  pinMode(GPIO_GICO, OUTPUT);
  
  int_clk = timerBegin(0, 80, true);
  timerAttachInterrupt(int_clk, int_clk_isr, CHANGE);
  timerAlarmWrite(int_clk, 150, true); //~ 8kHz, a bit more because stuff wont work sometimes otherwise

  switch_to_slave();
}

serial_packet get_current_packet() {
  struct serial_packet packet;
  packet.id = buf[0];
  packet.size = (buf[1]<<8 | buf[2]);
  packet.data = buf+3;
  return packet;
}