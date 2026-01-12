"""

"""

import serial
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
                 baud_rate: int = 9600) -> None:

        self.serial_conn = serial.Serial(port, baudrate=baud_rate)

    def get_state(self) -> str:
        self.serial_conn.write(to_msg(Protocol.get_state, b""))
        # Need some kind of method to await a response from the device