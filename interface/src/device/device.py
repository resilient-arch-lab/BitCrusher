"""

"""

from enum import Enum
import serial
from time import time
from dataclasses import dataclass
from .comms import Protocol, to_msg

class Device:
    # Device States
    class States(Enum):
        null = 0x00
        init = 0x01
        idle = 0x02
        armed = 0x03
        fault = 0xf0

    # Device arming configuration
    # These might have to become real (e.g. int32) datatypes
    @dataclass
    class ArmingConfig:
        voltage: int = 0  # in [150V, 500V]
        trigger_polarity: int = 0  # 0: low, 1: high
        trigger_mode: int = 0  # 0: continuous, 1: single
        trigger_src: int = 0  # 0: HW, 1: FW

    serial_conn: serial.Serial  # the port (e.g. "/dev/ttyUSB0") should be passed as param to __init__ so that the port is opened on serial object creation
    arming_config: ArmingConfig
    state: States

    def __init__(self, port: str = "/dev/ttyUSB0", 
                 baud_rate: int = 9600, serial_timeout: float | None = 3) -> None:

        self.serial_conn = serial.Serial(port, baudrate=baud_rate, timeout=serial_timeout)
        self.arming_config = self.ArmingConfig()
        self.state = self.States.null

    def _write_msg(self, hdr: Protocol.Headers, body: bytes):
        self.serial_conn.write(to_msg(hdr, body))
    
    def _read_msg(self, expects: Protocol.Headers | None = None) -> tuple[Protocol.Headers, bytes]:
        hdr = self.serial_conn.read(1)
        msg_len = int(self.serial_conn.read(1))
        body = self.serial_conn.read(msg_len)
        hdr, body = Protocol.parse_from_bytes(hdr, body)
        if (expects != None and hdr != expects):
            raise Exception(f"Expected response with header \"{expects}\", but got \"{hdr}\"")
        return hdr, body

    def _send_msg(self, hdr: Protocol.Headers, body: bytes, expects: Protocol.Headers | None = None):
        self._write_msg(hdr, body)
        resp_hdr, resp_body = self._read_msg(expects=expects)


    def get_state(self) -> States:
        self._write_msg(Protocol.Headers.get_state, b"")
        hdr, body = self._read_msg(expects=Protocol.Headers.success)
        try:
            state = self.States(body)
        except KeyError as e:
            e.add_note(f"Invalid device state: {body}")
        return state