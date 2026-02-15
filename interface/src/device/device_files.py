"""
Generate files for BitCrusher firmware based on communication 
protocol definition in comms.py and device.py
"""

from .comms import Protocol
from .device import Device

from pathlib import Path


out_dir = Path(__file__).parent.parent.parent/"device_files"  # outer-dir of src/

def generate_header_defs() -> str:
    header_defs = ""
    for header in Protocol.Headers:
        header_defs += f"#define HDR_{header.name.upper()} (uint8_t )0x{header.value.hex()}\n"
    return header_defs

def write_device_files():
    out_str = f"""
#ifndef __PROTOCOL_H__
#define __PROTOCOL_H__

#define BODY_MAX_LEN {Protocol.body_max_len}

{generate_header_defs()}

#endif  // #define __PROTOCOL_H__
    """

    out_file = open(out_dir/"protocol.h", 'w')
    out_file.write(out_str)
    out_file.close()
