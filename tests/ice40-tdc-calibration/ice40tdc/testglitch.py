import time
from glitchmeter import GlitchMeter
from datetime import datetime
import json
import struct
import numpy as np
import matplotlib.pyplot as plt

gm = GlitchMeter('COM8')

NUM_ELEMENTS = 1

scope = gm.scope

gm.build_and_load(NUM_ELEMENTS, "triggered", "GPIO4")

scope.glitch.clk_src = "clkgen"
scope.glitch.trigger_src = "ext_single"
scope.glitch.ext_offset = 5
scope.glitch.repeat = 1
scope.glitch.output = "glitch_only"

scope.glitch.width = 30

scope.io.glitch_lp = True

scope.io.tio1 = True
time.sleep(0.01)
scope.io.tio1 = False

scope.arm()

time.sleep(0.01)
scope.io.tio4 = True
time.sleep(0.001)
scope.io.tio4 = False
time.sleep(0.01)

pattern = gm.getpattern(True)

known = json.load( open("TDC_data_fresh.json", "r"))
ref = known[str(NUM_ELEMENTS)]

pltdata = []

for p in pattern:

    res = int(p.hex(), 16)

    mv_list = []
    close_list = []

    for k in ref.keys():
        diff = int(ref[k], 16) ^ res
        closeness = bin(diff).count('1')

        close_list += [closeness]
        mv_list += [int(k)]
    
    minarg = np.argmin(close_list)
    mv = mv_list[minarg]

    print("%04d mv (closeness = %d)"%(mv, close_list[minarg]))

    pltdata.append(mv)

plt.plot(pltdata)
plt.show()