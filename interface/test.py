from src.device.device import DeviceResponseError, TestingDevice, Device
from src import device
import unittest
import numpy as np

class TestArmingParameter(unittest.TestCase):
    # dev is set up in init rather than setUp because it only needs to be
    # set up once before the test methods are run
    def __init__(self, methodName: str = "runTest") -> None:
        try:
            self.dev = Device()
        except:
            self.dev = TestingDevice()
        super().__init__(methodName)
    
    def test_modify_arming_param(self):
        self.dev._write_arming_param("voltage", 200)
        res2 = self.dev._read_arming_param("voltage")
        self.assertEqual(res2, 200)
        
        # Try updating arming param to invalid value, check for error
        # response and make sure the parameter wasn't updated
        bad_voltage_error = False
        try:
            self.dev._write_arming_param("voltage", 600)
        except DeviceResponseError as e:
            bad_voltage_error = True
        res3 = self.dev._read_arming_param("voltage")
        self.assertTrue(bad_voltage_error)
        self.assertEqual(res3, 200)
    
    # def test_arm_disarm(self):
    #     self.dev.arming_config.voltage = np.uint16(200)
    #     self.dev._write_arming_config()
    #     self.dev.arm()


def InterfaceListing():
    device = Device()  # connect to and initialize device

    device._flash_firmware("path/to/firmware.bin")  # update device firmware

    device.arming_config.voltage = np.uint16(200)  # configure high voltage generation to 200 volts

    device.arm(5)  # arm device for at most 5 seconds

    device.reset()

if __name__ == "__main__":
    unittest.main()
    raise(SystemExit())

