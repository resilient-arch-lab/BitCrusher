import time
from glitchmeter import GlitchMeter
from datetime import datetime
import json
import struct

gm = GlitchMeter('COM8')

NUM_ELEMENTS = 1

scope = gm.scope

scope.io.glitch_lp = False
scope.io.glitch_hp = False

known_patterns = {}

for elements in [1, 3, 12]:

    gm.build_and_load(elements, "triggered", "GPIO4")
    
    mv = 900

    tests = {}

    while mv < 1800:

        gm.set_coremv(mv)
        time.sleep(0.1)

        scope.io.tio1 = True
        time.sleep(0.01)
        scope.io.tio1 = False

        time.sleep(0.01)
        scope.io.tio4 = True
        time.sleep(0.001)
        scope.io.tio4 = False
        time.sleep(0.01)

        data = gm.getpattern()
        h = data[50].hex()
        b = format(int(h, 16), "032b")
        s = "%4d: %s"%(mv, b)
        print(s)

        tests[mv] = h

        mv += 10
        
    known_patterns[elements] = tests

    gm.set_coremv(1200)

json.dump( known_patterns, open( "TDC_data_fresh.json", 'w' ) )