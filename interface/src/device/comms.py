"""

"""

import serial
from enum import Enum

# Convert header and body to formatted UART message
def to_msg(hdr: bytes, body: bytes) -> bytes:
    body_len = len(body)
    msg: bytes = hdr + bytes(body_len) + body
    return msg

# The BitCrusher UART protocol
class Protocol:
    # headers: dict[str, bytes] = {
    #     # error checking responses (returned from device)
    #     "success": b"\x01",
    #     "error": b"\x02",

    #     # set global device parameters (sent from host)
    #     "get_param": b"\x11",
    #     "set_param": b"\x12",

    #     # get device state (sent from host)
    #     "get_state": b"\x21",

    #     # arming / disarming commands 
    #     "arm": b"\xa0",
    #     "set_arm_param": b"\xa1",
    #     "get_arm_param": b"\xa2",
    #     "disarm": b"\xaf"
    # }

    class Headers(Enum):
        success = b"\x01"
        error = b"\x02"

        # set global device parameters (sent from host)
        get_param = b"\x11"
        set_param = b"\x12"

        # get device state (sent from host)
        get_state = b"\x21"

        # arming / disarming commands 
        arm = b"\xa0"
        set_arm_param = b"\xa1"
        get_arm_param = b"\xa2"
        disarm = b"\xaf"
    
    # error checking responses (returned from device)
    # body of responses used to return any necessary values to commands sent from host
    success: bytes = b"\x01"
    error: bytes = b"\x02"

    # set global device parameters (sent from host)
    get_param: bytes = b"\x11"
    set_param: bytes = b"\x12"

    # get device state (sent from host)
    get_state: bytes = b"\x21"

    # arming / disarming commands 
    arm: bytes = b"\xa0"
    set_arm_param: bytes = b"\xa1"
    get_arm_param: bytes = b"\xa2"
    disarm: bytes = b"\xaf"

    @classmethod
    def parse_from_bytes(cls, hdr: bytes, body: bytes):
        try:
            hdr_val = cls.Headers(hdr)
        except KeyError as e:
            e.add_note(f"Failed to parse message: \"{hex(int(hdr))}\" is invalid header")
            raise e

        return hdr_val, body
        
