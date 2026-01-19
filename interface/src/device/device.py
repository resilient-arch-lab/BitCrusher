"""

"""

from enum import Enum
import serial, ftd2xx
from time import time
from dataclasses import dataclass, fields
from .comms import Protocol
# Message = Protocol.Message
# Headers = Protocol.Headers

class DeviceError(Exception):
    pass

class DeviceResponseError(DeviceError):
    pass

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

    ftdi_conn: ftd2xx.FTD2XX
    # serial_conn: serial.Serial  # the port (e.g. "/dev/ttyUSB0") should be passed as param to __init__ so that the port is opened on serial object creation
    arming_config: ArmingConfig
    state: States

    def __init__(self, port: str = "/dev/ttyUSB0", 
                 baud_rate: int = 9600, serial_timeout: float = 3) -> None:

        print("Searching for BitCrusher...")

        # Initialize serial connection
        # self.serial_conn = serial.Serial(port, baudrate=baud_rate, timeout=serial_timeout)
        ftdi_dev_ids = ftd2xx.listDevices()
        if ftdi_dev_ids is None:
            raise DeviceError("Found no FTDI USB bridge devices")
        if len(ftdi_dev_ids) > 1:
            print("Warning: found multiple FTDI devices")
        for i, id in enumerate(ftdi_dev_ids):
            ftdi_dev = ftd2xx.openEx(id)
            print(f"Device {i}: {ftdi_dev.getDeviceInfo()}")
            # TODO: this should check if the device is a BitCrusher, and set self.ftdi_conn
            self.ftdi_conn = ftdi_dev
            break
        
        # TODO: raise error if device isn't found
        if not self.ftdi_conn:
            raise DeviceError("No BitCrusher found")
        # Finish configuring FTDI device
        print("Connecting to BitCrusher...")
        self.ftdi_conn.setTimeouts(int(serial_timeout*1000), int(serial_timeout*1000))
        self.ftdi_conn.setBaudRate(baud_rate)
        
        # Check for device activity by getting device state
        self.state = self.get_state()

        self.arming_config = Device.ArmingConfig()

    def _write_msg(self, msg: Protocol.Message):
        # self.serial_conn.write(to_msg(hdr, body))
        self.ftdi_conn.write(Protocol.to_bytes(msg))
    
    def _read_msg(self, expects: Protocol.Headers | None = None) -> Protocol.Message:
        hdr = self.ftdi_conn.read(1)
        msg_len = int(self.ftdi_conn.read(1))
        body = self.ftdi_conn.read(msg_len)
        msg = Protocol.parse_from_bytes(hdr, body)
        if (expects != None and hdr != expects):
            raise DeviceResponseError(f"Expected response with header \"{expects}\", but got \"{hdr}\"")
        return msg
    
    def _send_msg(self, msg: Protocol.Message, expects: Protocol.Headers | None = None) -> Protocol.Message:
        self._write_msg(msg)
        msg = self._read_msg(expects=expects)
        return msg

    def get_state(self) -> States:
        msg = Protocol.Message(Protocol.Headers.get_state, b"")
        self._write_msg(msg)
        resp = self._read_msg(expects=Protocol.Headers.success)
        try:
            state = self.States(resp.body)
        except KeyError as e:
            e.add_note(f"Invalid device state: {resp.body}")
            raise e
        return state

    # To change device arm config:
    #   modify device.arming_config members as desired
    #   call _apply_arming_config()
    def _apply_arming_config(self):
        for i, param in enumerate(fields(Device.ArmingConfig)):
            msg = Protocol.Message(Protocol.Headers.set_arm_param, param.name.encode("utf-8"))
            resp = self._send_msg(msg, Protocol.Headers.success)

    # configure reset, boot mode, and VBUS_Sense (make it boot normally)
    def _config_ft230x_gpio(self):
        # ucMask: Required value for bit mode mask. This sets up which bits are inputs and outputs. A bit value of
        # 0 sets the corresponding pin to an input, a bit value of 1 sets the corresponding pin to an output.
        # In the case of CBUS Bit Bang, the upper nibble of this value controls which pins are inputs and outputs,
        # while the lower nibble controls which of the outputs are high and low.
        # ucMode: Mode value. Can be one of the following:
        # 0x0 = Reset
        # 0x1 = Asynchronous Bit Bang
        # 0x2 = MPSSE (FT2232, FT2232H, FT4232H and FT232H devices only)
        # 0x4 = Synchronous Bit Bang (FT232R, FT245R, FT2232, FT2232H, FT4232H and FT232H devices only)
        # 0x8 = MCU Host Bus Emulation Mode (FT2232, FT2232H, FT4232H and FT232H devices only)
        # 0x10 = Fast Opto-Isolated Serial Mode (FT2232, FT2232H, FT4232H and FT232H devices only)
        # 0x20 = CBUS Bit Bang Mode (FT232R and FT232H devices only)
        # 0x40 = Single Channel Synchronous 245 FIFO Mode (FT2232H and FT232H devices only)
        # 0: Reset, 1: Bootsel, 2: NC, 3: VBUS sense
        self.ftdi_conn.setBitMode(0b00110001, 0x20)  # set CBUS0,1 to output; CBUS0 high, CBUS1 low
        # TODO: not sure how to configure VBUS_Sense

    
    def _config_ft230x(self):
        # TODO: set power descriptor to 0, since device is self powered
        # I can't figure out how to do this manually, so I might have to try it
        # with the FTProg utility first
        ...