from src.device.device import TestingDevice
from src import device

def test_1():
    dev = TestingDevice()
    dev.get_state()


def main():
    test_1()
    return

if __name__ == "__main__":
    main()
    raise(SystemExit())

