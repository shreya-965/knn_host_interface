import serial
from protocol import RUN_DEFAULT_DATASET

class UARTInterface:
    def __init__(self, port, baudrate=115200):
        self.ser = serial.Serial(
            port=port,
            baudrate=baudrate,
            timeout=1
        )

    def run_default_dataset(self):
        self.ser.write(bytes([RUN_DEFAULT_DATASET]))

    def read_byte(self):
        data = self.ser.read(1)
        if len(data):
            return data[0]
        return None

    def close(self):
        self.ser.close()