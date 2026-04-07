from pathlib import Path
from ctypes import ArgumentError
from enum import Enum
from typing import Any
from time import perf_counter, sleep
from dataclasses import dataclass
import sys
import subprocess

import numpy as np
import pylibftdi
import serial.tools.list_ports

from .comms import Protocol


class DeviceError(Exception):
    pass

class DeviceResponseError(DeviceError):
    pass


class Device:
    class States(Enum):
        null = 0x00
        init = 0x01
        idle = 0x02
        armed = 0x03
        fault = 0xF0

    class ResetState(Enum):
        reset = 0b00
        set = 0b01

    class BootSelState(Enum):
        normal = 0b00
        bootloader = 0b01

    @dataclass
    class ArmingConfig:
        voltage: np.uint16 = np.uint16(0)
        trigger_polarity: np.uint8 = np.uint8(0)
        trigger_mode: np.uint8 = np.uint8(0)
        trigger_src: np.uint8 = np.uint8(0)

    serial_timeout: float = 1  # serial read timeout
    _ft230x_driver: pylibftdi.Driver
    _ft230x_handle: pylibftdi.Device
    _ft230x_serial_num: str
    _ft230x_gpio_reset_pin: int = 0b00
    _ft230x_gpio_bootsel_pin: int = 0b01
    _ftd230x_vid: int = 0x0403  # default FT230X VID
    _ftd230x_pid: int = 0x6015  # default FT230X PID

    arming_config: Device.ArmingConfig = ArmingConfig()
    arming_config_params: dict[str, int] = {
        p: i for i, p in enumerate(Device.ArmingConfig.__annotations__.keys())
    }

    def __init__(self, baudrate: int = 115200, timeout: float = 1.0):
        self.serial_timeout = timeout

        self._ft230x_driver = pylibftdi.Driver()

        try:
            devs = self._ft230x_driver.list_devices()
            dev_str = devs[0]
            dev_id = dev_str[2]
            print(f"Found FTDI device with serial number '{dev_id}'")
            self._ft230x_handle = pylibftdi.Device(dev_id, mode='b')  # binary mode
        except Exception as e:
            raise DeviceError("No FTDI device found") from e

        # configure serial settings
        self._ft230x_handle.baudrate = baudrate
        if self._ft230x_handle.baudrate != baudrate:
            raise DeviceError("Failed to configure FT230X baudrate")

        self._ft230x_serial_num = dev_id

        self._gpio_state: int = 0x00
        self._ft230x_normal_state_gpio()

        # test communication
        try:
            self._read_arming_param("voltage")
            print("Device acknowledged")
        except DeviceError as e:
            print("Device did not respond (may need firmware flash)")
            print(e)
            print("Initialization incomplete, at a later time this would raise an exception")

    def _ft230x_port(self):
        ports = serial.tools.list_ports.comports()
        for p in ports:
            if p.serial_number == self._ft230x_serial_num:
                _ft230x_port = p.device
                print(f"Found device port: {_ft230x_port}")
                return _ft230x_port
        raise DeviceError("Could not find FT230X serial port")

    def _ft230x_gpio_set(self, pin: int, state: int):
        if (pin not in range(4)) or (state not in (0, 1)):
            raise ArgumentError()
        
        self._gpio_state &= ~(1 << pin)
        self._gpio_state |= state << pin
        mask = 0b0011 << 4

        bits = mask | self._gpio_state
        try: 
            bits.to_bytes(1)
        except OverflowError as e:
            raise e
        
        print(f"setting ftd230x bitmode: {bits:08b}")
        # self.ftdi_conn.setBitMode(bits, 0x20)
        self._ft230x_handle.ftdi_fn.ftdi_set_bitmode(bits, 0x20)

    def _ft230x_normal_state_gpio(self):
        self._ft230x_gpio_set(self._ft230x_gpio_reset_pin, 1)
        self._ft230x_gpio_set(self._ft230x_gpio_bootsel_pin, 0)

    def _enter_bootloader(self):
        self._ft230x_gpio_set(self._ft230x_gpio_bootsel_pin, 1)
        sleep(0.1)
        self.reset()
        sleep(0.1)

        self._ft230x_handle.flush()
        sleep(0.1)

        self._ft230x_handle.write(b'\x7f')
        sleep(0.1)

        resp = self._ft230x_handle.read(1)

        if b'y' != resp:
            raise DeviceError(f"Failed to enter bootloader, expected {b'y'}, got {resp}")

    def _exit_bootloader(self):
        self._ft230x_gpio_set(self._ft230x_gpio_bootsel_pin, 0)
        sleep(0.1)
        self.reset()

    def _flash_firmware(self):
        self._enter_bootloader()

        baud = self._ft230x_handle.baudrate  # TODO: make sure baudrate and timeout are restored when connection is re-opened
        self._ft230x_handle.close()
        port = self._ft230x_port()
        

        stm32flash_path = Path(__file__).parents[1] / 'stm32flash' / 'stm32flash'
        firmware_path = Path(__file__).parents[3] / 'firmware' / 'build' / 'debug' / 'BitCrusher.bin'

        sleep(0.1)

        try:
            subprocess.run(
                [str(stm32flash_path), '-b', str(baud), '-w', str(firmware_path), '-v', '-g', '0x0', port],
                check=True
            )
        except subprocess.CalledProcessError:
            raise DeviceError("Firmware flash failed")

        self._ft230x_handle.open()
        self._ft230x_handle.baudrate = baud

        self._exit_bootloader()

    def _write_msg(self, msg: Protocol.Message):
        _ = self._ft230x_handle.write(Protocol.to_bytes(msg))

    def _read_msg(self, expects: Protocol.Headers | None = None) -> Protocol.Message:
        t0 = perf_counter()
        while perf_counter() - t0 < self.serial_timeout:
            hdr = self._ft230x_handle.read(1)
            if hdr:
                break
        
        if not hdr:
            raise DeviceResponseError("Timeout waiting for header")

        msg_len = int.from_bytes(self._ft230x_handle.read(1), 'little')
        body = self._ft230x_handle.read(msg_len)

        msg = Protocol.parse_from_bytes(hdr, body)

        if expects is not None and msg.hdr != expects:
            raise DeviceResponseError(f"Expected response with header \"{expects}\", got \"{msg.hdr}\"")
        return msg

    def _send_msg(self, msg: Protocol.Message, expects: Protocol.Headers | None = None) -> Protocol.Message:
        self._write_msg(msg)
        return self._read_msg(expects)

    """
    Reset the device MCU by cycling the RST pin.
    """
    def reset(self):
        self._ft230x_gpio_set(self._ft230x_gpio_reset_pin, 0)
        sleep(0.5)
        self._ft230x_gpio_set(self._ft230x_gpio_reset_pin, 1)
    
    def get_state(self) -> States:
        msg = Protocol.Message(Protocol.Headers.get_state, b"")
        resp = self._send_msg(msg, expects=Protocol.Headers.success)
        return self.States(resp.body)

    """
    Ask device for its current value of arming config parameter `p`. If the device responds, the 
    corresponding value for `p` in `self.arming_config` is updated.
    """
    def _read_arming_param(self, p: str) -> Any:
        if p not in self.arming_config_params:
            raise ArgumentError()

        msg = Protocol.Message(
            Protocol.Headers.get_arm_param,
            body=self.arming_config_params[p].to_bytes(1)
        )

        resp = self._send_msg(msg, expects=Protocol.Headers.success)

        ptype = Device.ArmingConfig.__annotations__[p]
        val = np.frombuffer(resp.body, dtype=ptype)[0]
        setattr(self.arming_config, p, val)

        return val

    """
    Write value `v` to parameter `p` in the device's arming config, and update in `self.arming_config`
    if the device responds with a success. 
    """
    def _write_arming_param(self, p: str, v):
        if p not in self.arming_config_params:
            raise ArgumentError()

        ptype = Device.ArmingConfig.__annotations__[p]
        val = ptype(v)

        msg = Protocol.Message(
            Protocol.Headers.set_arm_param,
            body=self.arming_config_params[p].to_bytes(1) + val.tobytes()
        )

        self._send_msg(msg, expects=Protocol.Headers.success)
        setattr(self.arming_config, p, val)

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
        _ = self._send_msg(
            Protocol.Message(Protocol.Headers.arm, b""),
            expects=Protocol.Headers.success
        )

        t0 = perf_counter()
        while perf_counter() - t0 < period:
            sleep(handshake_period)
            res = self._send_msg(
                Protocol.Message(Protocol.Headers.arm, b""),
                expects=Protocol.Headers.success
            )

            tmp = np.frombuffer(res.body, dtype=np.float32)
            print(
                f"HVVS: {tmp[0]:.4f}  HV: {tmp[1]:.4f}  PID: {tmp[2]:.4f}"
            )

        sleep(handshake_period)

        self._send_msg(
            Protocol.Message(Protocol.Headers.disarm, b""),
            expects=Protocol.Headers.success
        )
