"""

"""

from ctypes import ArgumentError
from enum import Enum
from typing import Any, Callable, override
import serial, ftd2xx
from time import perf_counter, time
from dataclasses import dataclass, fields
from .comms import Protocol
from time import sleep
import subprocess
from pathlib import Path
import sys
# Message = Protocol.Message
# Headers = Protocol.Headers

import numpy as np

# The idea is to check the each property against its constraints with 
# a constraint checking function (the lambda). The most important thing
# is that the device itself doesn't use a bad config though, so this 
# isn't super important.  
class ConstrainedArmingConfig:
    voltage: tuple[int, Callable] = (0, lambda x: x>=100 and x<=500)
    trigger_polarity: tuple[int, Callable] = (0, lambda x: x in [0, 1])  # 0: low, 1: high
    trigger_mode: tuple[int, Callable] = (0, lambda x: x in [0, 1])  # 0: continuous, 1: single
    trigger_src: tuple[int, Callable] = (0, lambda x: x in [0, 1])  # 0: HW, 1: FW



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

    class ResetState(Enum):
        reset = 0b00
        set = 0b01

    class BootSelState(Enum):
        normal = 0b00
        bootloader = 0b01

    # Device arming configuration
    @dataclass
    class ArmingConfig:
        voltage: np.uint16 = np.uint16(0)  # in [150V, 500V]
        trigger_polarity: np.uint8 = np.uint8(0)  # 0: low, 1: high
        trigger_mode: np.uint8 = np.uint8(0)  # 0: continuous, 1: single
        trigger_src: np.uint8 = np.uint8(0)  # 0: HW, 1: FW

    ftdi_conn: ftd2xx.FTD2XX
    arming_config: ArmingConfig
    arming_config_params: dict[str, int] = {p : i for i, p in enumerate(ArmingConfig.__annotations__.keys())}
    state: States
    _in_bootloader: bool

    _ftd230x_gpio_reset_pin: int = 0b00
    _ftd230x_gpio_bootsel_pin: int = 0b01

    def __init__(self, port: str = "/dev/ttyUSB0", 
                 baud_rate: int = 115200, serial_timeout: float = 1) -> None:

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
        
        if not self.ftdi_conn:
            raise DeviceError("No BitCrusher found")
        # Finish configuring FTDI device
        print("Connecting to BitCrusher...")
        self.ftdi_conn.setTimeouts(int(serial_timeout*1000), int(serial_timeout*1000))
        self.ftdi_conn.setBaudRate(baud_rate)

        self.arming_config = Device.ArmingConfig()

        # configure device boot select and reset pin for normal operation at first
        self._ftd230x_normal_state_gpio()
        print("configured ftd230x GPIO")

        # Send a get arming param msg to check connection
        try:
            self._read_arming_param("voltage")
            print("device ack'd")
        except:
            # device didn't respond, probably needs a firmware flash
            print("device did not ack")
    
    def _ftd230x_gpio_set(self, pin: int, state: int):
        if (pin not in range(4)) or (state not in (0, 1)):
            raise ArgumentError()

        pin_states = self.ftdi_conn.getBitMode() & 0b00001111
        pin_states &= ~(1 << pin)
        pin_states |= state << pin
        mask = 0b0011 << 4

        bits = mask | pin_states
        try: 
            bits.to_bytes(1)
        except OverflowError as e:
            raise e
        
        print(f"setting ftd230x bitmode: {bits:08b}")

        self.ftdi_conn.setBitMode(bits, 0x20)
    
    def _ftd230x_normal_state_gpio(self):
        self._ftd230x_gpio_set(0, 1)
        self._ftd230x_gpio_set(1, 0)

    def reset(self):
        self._ftd230x_gpio_set(self._ftd230x_gpio_reset_pin, 0)
        sleep(0.5)
        self._ftd230x_gpio_set(self._ftd230x_gpio_reset_pin, 1)        

    def _enter_bootloader(self): 
        # To enter bootloader, bootsel pin set high and held high while device is reset
        self._ftd230x_gpio_set(self._ftd230x_gpio_bootsel_pin, 1)
        self.reset()
        
        self.ftdi_conn.write(b'\x7f')  # bootlader should ack with `7f 79` or just `79`
        resp = self.ftdi_conn.read(2)
        
        print(resp)
        
        if resp[-1] != b'\x79':
            raise DeviceError("Failed to enter bootloader")
        
        self._in_bootloader = True
    
    def _flash_firmware(self):
        # TODO: adapt from TestingDevice._flash_firmware
        ...

    def _exit_bootloader(self):
        self._ftd230x_gpio_set(self._ftd230x_gpio_bootsel_pin, 0)
        self.reset()

    # TODO: Message sending / receiving messages should raise if they get an error response
    def _write_msg(self, msg: Protocol.Message):
        # self.serial_conn.write(to_msg(hdr, body))
        _ = self.ftdi_conn.write(Protocol.to_bytes(msg))
    
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
    
    """
    Ask device for its current value of arming config parameter `p`. If the device responds, the 
    corresponding value for `p` in `self.arming_config` is updated.
    """
    def _read_arming_param(self, p: str) -> Any:
        # TODO: make explicit mapping from ArmingConfig fields to indices for querrying device
        if p not in self.arming_config_params.keys():
            raise ArgumentError(f"Provided arming parameter not one of expected: {list(self.arming_config_params.keys())}")
        msg = Protocol.Message(Protocol.Headers.get_arm_param, body=self.arming_config_params[p].to_bytes(1))
        self._write_msg(msg)
        resp = self._read_msg(expects=Protocol.Headers.success)

        ptype = Device.ArmingConfig.__annotations__[p]
        self.arming_config.__setattr__(p, ptype(np.frombuffer(resp.body, dtype=ptype)))  # update arming config locally

        return self.arming_config.__getattribute__(p)
    
    """
    Write value `v` to parameter `p` in the device's arming config, and update in `self.arming_config`
    if the device responds with a success. 
    """
    def _write_arming_param(self, p: str, v) -> None:
        if p not in self.arming_config_params.keys():
            raise ArgumentError(f"Provided arming parameter not one of expected: {list(self.arming_config_params.keys())}")

        ptype: type[Any] = Device.ArmingConfig.__annotations__[p]  # gets type of field p
        update_val = ptype(v)
        msg = Protocol.Message(Protocol.Headers.set_arm_param, body=self.arming_config_params[p].to_bytes(1) + update_val.tobytes())
        self._write_msg(msg)
        resp = self._read_msg(expects=Protocol.Headers.success)
        self.arming_config.__setattr__(p, ptype(v))

        return

    """
    Write all values in `self.arming_config` to Device. 
    """
    def _write_arming_config(self):
        for k in self.arming_config_params.keys():
            self._write_arming_param(k, self.arming_config.__getattribute__(k))

    """
    Ask device for all arming config parameters, updating them in `self.arming_config`.
    """
    def _read_arming_config(self):
        for k in self.arming_config_params.keys():
            self._read_arming_param(k)

    """
    Arm the device
    Ensure handshake period is <= the handshake period programmed on device.
    """
    def arm(self, period: float = 1, handshake_period: float = 0.25):
        self._send_msg(Protocol.Message(Protocol.Headers.arm, b""), expects=Protocol.Headers.success)
        t0 = perf_counter()
        while (perf_counter() - t0 < period):
            sleep(handshake_period)
            self._send_msg(Protocol.Message(Protocol.Headers.arm, b""), expects=Protocol.Headers.success)
        sleep(handshake_period)
        self._send_msg(Protocol.Message(Protocol.Headers.disarm, b""), expects=Protocol.Headers.success)


# Class for testing prototype firmware on STM32 Dev Board with CH340 USB-UART connection
class TestingDevice(Device):
    serial_conn: serial.Serial
    
    @override
    def __init__(self, port: str = "/dev/ttyUSB0", baud_rate: int = 115200, serial_timeout: float = 3) -> None:
        print("Searching for BitCrusher...")
        self.serial_conn = serial.Serial(port, baudrate=baud_rate, timeout=serial_timeout)

        # Check for device activity by getting device state
        # self.state = self.get_state()
        self.arming_config = Device.ArmingConfig()

    # _write_msg and _read_msg must be redefined to use the CH340
    @override
    def _write_msg(self, msg: Protocol.Message):
        self.serial_conn.write(Protocol.to_bytes(msg))
        print(Protocol.to_bytes(msg))
        print(f"Writing msg {msg}: {Protocol.to_bytes(msg)}")
    
    @override
    def _read_msg(self, expects: Protocol.Headers | None = None) -> Protocol.Message:
        print("Receiving msg: ", end="")
        hdr = self.serial_conn.read(1)
        print(f"hdr[{hdr} ({Protocol.Headers(hdr)})], ", end="")
        msg_len = int.from_bytes(self.serial_conn.read(1))
        print(f"len[{msg_len}], ", end="")
        body = self.serial_conn.read(msg_len)
        print(f"bdy[{body}]")
        msg = Protocol.parse_from_bytes(hdr, body)

        self.serial_conn.reset_input_buffer()

        if (expects != None and msg.hdr != expects):
            raise DeviceResponseError(f"Expected response with header \"{expects}\", but got \"{msg.hdr}\"")
        return msg

    @override
    def _enter_bootloader(self):
        # Attempt to enter serial bootloader
        self.serial_conn.write(b'\x7f')
        resp = self.serial_conn.read_all()

        try:
            print(f"Bootloader response: {resp}")
            print(f"({resp.hex()})")
        except:
            pass
        
        if resp != b'\x79':
            raise DeviceError("Failed to enter serial bootloader")
        self._in_bootloader = True

    @override
    def _flash_firmware(self):
        if not self._in_bootloader:
            raise DeviceError("Cannot flash device before entering serial bootloader. This cannot be automated from a testing device")
        
        # Disconnect from serial port
        baud = self.serial_conn.baudrate
        port = self.serial_conn.port
        if port is None:
            raise Exception("Something is wrong with the serial connection")
        self.serial_conn.close()

        # Flash firmware from default build directory to device
        stm32flash_path = Path(__file__).parents[1] / 'stm32flash' / 'stm32flash'
        firmware_path = Path(__file__).parents[3] / 'firmware' / 'build' / 'debug' / 'BitCrusher.bin'
        try:
            print("Attempting firmware flash...")
            flash_proc = subprocess.run(
                [str(stm32flash_path), '-b', str(baud), '-w', str(firmware_path), '-v', '-g', '0x0', port], 
                stdout=sys.stdout, 
                stderr=sys.stderr,
                check=True
            )
        except subprocess.CalledProcessError as e:
            raise DeviceError("Failed to flash device, stm32flash exited with error")

        # If the flash succedeed, the firmware should be running already, exit bootloader state
        self.serial_conn.open()  # open port with previous settings
        self.serial_conn.reset_input_buffer()
        self.serial_conn.reset_output_buffer()
        self._in_bootloader = False

        sleep(0.1)
        
        try: 
            self._read_arming_param("voltage")
        except:
            raise DeviceError("unable to communicate with device after flash, try resetting device")
        

