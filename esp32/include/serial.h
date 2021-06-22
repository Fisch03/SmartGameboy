typedef void (*CallbackType)(); 

struct serial_packet {
    byte id;
    unsigned int size;
    volatile byte *data;
};

void init_serial(CallbackType onSerialDataCB);

void gb_send(serial_packet packet);

serial_packet get_current_packet();