"""

"""

import serial
from time import time
from dataclasses import dataclass
from .comms import Protocol, to_msg

# These might have to become real (e.g. int32) datatypes
@dataclass
class ArmingConfig:
    voltage: int  # in [150V, 500V]
    trigger_polarity: int  # 0: low, 1: high
    trigger_mode: int  # 0: continuous, 1: single
    trigger_src: int  # 0: HW, 1: FW



class Device:
    # USB information to configure and use the USB->UART bridge. See https://www.silabs.com/documents/public/data-sheets/cp2102n-datasheet.pdf
    # This might require working with the bridge configuration software

    # Serial connection
    serial_conn: serial.Serial  # the port (e.g. "/dev/ttyUSB0") should be passed as param to __init__ so that the port is opened on serial object creation

    def __init__(self, port: str = "/dev/ttyUSB0", 
                 baud_rate: int = 9600, serial_timeout: float | None = 3) -> None:

        self.serial_conn = serial.Serial(port, baudrate=baud_rate, timeout=serial_timeout)

    def _send_msg(self, hdr: bytes, body: bytes):
        self.serial_conn.write(to_msg(hdr, body))
    
    def _get_msg(self):
        hdr = self.serial_conn.read(1)
        msg_len = int(self.serial_conn.read(1))
        body = self.serial_conn.read(msg_len)




    def get_state(self) -> str:
        self._send_msg(Protocol.Headers.get_state.value, b"")
        # Need some kind of method to await a response from the device