"""

"""

import serial



class Device:
    # USB information to configure and use the USB->UART bridge. See https://www.silabs.com/documents/public/data-sheets/cp2102n-datasheet.pdf
    # This might require working with the bridge configuration software

    # Serial connection
    serial_conn: serial.Serial  # the port (e.g. "/dev/ttyUSB0") should be passed as param to __init__ so that the port is opened on serial object creation

    def __init__(self, port: str = "/dev/ttyUSB0", 
                 baud_rate: int = 9600) -> None:

        self.serial_conn = serial.Serial(port, baudrate=baud_rate)
        pass