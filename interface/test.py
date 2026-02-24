from src.device.device import DeviceResponseError, TestingDevice
from src import device


def test_1():
    dev = TestingDevice()
    res = dev.get_arming_param("voltage")
    print(res)

def test_2():
    # Update arming parameter, then get it and check equivalence
    dev = TestingDevice()
    dev.set_arming_param("voltage", 200)
    res2 = dev.get_arming_param("voltage")
    assert(res2 == 200)
    
    # Try updating arming param to invalid value, check for error
    # response and make sure the parameter wasn't updated
    bad_voltage_error = False
    try:
        dev.set_arming_param("voltage", 600)
    except DeviceResponseError as e:
        bad_voltage_error = True
    res3 = dev.get_arming_param("voltage")
    assert(bad_voltage_error == True)
    assert(res3 == 200)



def main():
    test_2()
    return

if __name__ == "__main__":
    main()
    raise(SystemExit())

