from src.device.device import TestingDevice
from src import device

def test_1():
    dev = TestingDevice()
    res = dev.get_arming_param(1)
    print(res)

def main():
    test_1()
    return

if __name__ == "__main__":
    main()
    raise(SystemExit())

