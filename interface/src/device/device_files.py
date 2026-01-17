"""
Generate files for BitCrusher firmware based on communication 
protocol definition in comms.py and device.py
"""

from .comms import Protocol
from .device import Device

from pathlib import Path


out_dir = Path(__file__).parent.parent.parent  # outer-dir of src/
out_file = open(out_dir/"protocol.h", 'w')

out_file.close()