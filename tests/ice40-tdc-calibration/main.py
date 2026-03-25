from ice40-tdc-calibration.ice40tdc.glitchmeter import GlitchMeter


import time
from ice40tdc.glitchmeter import GlitchMeter
from datetime import datetime
import json
import struct
import numpy as np
import matplotlib.pyplot as plt

def setup() -> GlitchMeter:
    gm = GlitchMeter(None, None, dir="rtl")
    scope = gm.scope
    scope.clock.adc_mul = 1
    scope.clock.clkgen_freq = 25E6

    scope.glitch.enabled = True

    scope.glitch.clk_src = "pll"
    scope.glitch.trigger_src = "ext_single"

    scope.clock.clkgen_freq = 25E6

    scope.io.glitch_trig_mcx = "trigger"
    scope.io.glitch_trig_mcx = "glitch"

    return gm


def run_husky_fault(gm:GlitchMeter):
    NUM_ELEMENTS = 3
    scope = gm.scope

    gm.build_and_load(NUM_ELEMENTS, "triggered", "GPIO4")

    scope.glitch.ext_offset = 1
    scope.glitch.repeat = 1
    scope.glitch.output = "enable_only"

    scope.glitch.width = 1950
    scope.glitch.offset = 3800

    scope.io.glitch_lp = True
    scope.io.glitch_hp = True

    scope.io.tio1 = True
    time.sleep(0.01)
    scope.io.tio1 = False

    scope.arm()

    time.sleep(0.01)
    scope.io.tio4 = True
    time.sleep(0.001)
    scope.io.tio4 = False
    time.sleep(0.1)

    pattern = gm.getpattern(True)

    pltdata = []
    for p in pattern:
        value = bin(int(p.hex(), 16)).count('1')
        pltdata.append(value)

    plt.plot(pltdata)
    plt.show()

def run_EMFI_prototype(gm:GlitchMeter):
    NUM_ELEMENTS = 3
    scope = gm.scope

    gm.build_and_load(NUM_ELEMENTS, "triggered", "GPIO4")

    time.sleep(0.01)
    scope.io.tio4 = True
    time.sleep(0.001)
    scope.io.tio4 = False
    time.sleep(0.1)

    pattern = gm.getpattern(True)

    pltdata = []
    for p in pattern:
        value = bin(int(p.hex(), 16)).count('1')
        pltdata.append(value)

    plt.plot(pltdata)
    plt.show()