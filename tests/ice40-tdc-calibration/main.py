from typing import Any

import time
from ice40tdc.glitchmeter import GlitchMeter
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt

from device import Device

def husky_setup() -> GlitchMeter:
    gm = GlitchMeter(None, None, dir="ice40tdc/rtl")
    scope = gm.scope
    scope.clock.adc_mul = 1
    scope.clock.clkgen_freq = 25E6

    scope.glitch.enabled = True

    scope.glitch.clk_src = "pll"
    scope.glitch.trigger_src = "ext_single"

    scope.clock.clkgen_freq = 25E6

    scope.io.glitch_trig_mcx = "trigger"
    # scope.io.glitch_trig_mcx = "glitch"

    return gm

# Configure husky to relay trigger signal to SMB output
def husky_setup_relay() -> GlitchMeter:
    gm = GlitchMeter(None, None, dir="ice40tdc/rtl")
    scope = gm.scope
    scope.clock.adc_mul = 1
    scope.clock.clkgen_freq = 25E6

    scope.glitch.enabled = True

    scope.glitch.clk_src = "pll"
    scope.glitch.trigger_src = "ext_single"

    scope.clock.clkgen_freq = 25E6

    scope.io.tio4 = 'high_z'  # set trigger pin as input
    scope.trigger.module = 'basic'  # use basic (edge) triggering
    scope.trigger.triggers = 'tio4'  # set trigger module input to tio4
    scope.io.glitch_trig_mcx = 'trigger'  # output tirgger signal on glitch / trig SMB connector

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

    scope.io.glitch_trig_mcx = 'trigger'

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
    
    npdata = np.array(pltdata)
    np.save(f"results/25mhz_tdc_husky_{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}.npy", npdata)

    plt.plot(pltdata)
    # plt.show()
    plt.savefig(f"results/25mhz_tdc_husky_{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}.png", dpi=600)

def run_EMFI_prototype(gm:GlitchMeter):
    NUM_ELEMENTS = 3
    scope = gm.scope
    scope.io.tio4 = 'high_z'  # set trigger pin as input
    scope.trigger.module = 'basic'  # use basic (edge) triggering
    scope.trigger.triggers = 'tio4'  # set trigger module input to tio4
    scope.io.glitch_trig_mcx = 'trigger'  # output tirgger signal on glitch / trig SMB connector

    gm.build_and_load(NUM_ELEMENTS, "triggered", "GPIO4")

    scope.arm()

    _ = input("Press enter to retrieve result")

    pattern = gm.getpattern(True)

    pltdata: list[int] = []
    for p in pattern:
        value = bin(int(p.hex(), 16)).count('1')
        pltdata.append(value)

    npdata = np.array(pltdata)
    np.save(f"results/25mhz_tdc_bitcrusher_{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}.npy", npdata)

    plt.plot(pltdata)
    # plt.show()
    plt.savefig(f"results/25mhz_tdc_bitcrusher_{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}.png", dpi=600)

def run_EMFI_bitcrusher(gm: GlitchMeter, count: int = 1):
    NUM_ELEMENTS = 3
    scope = gm.scope
    
    # configure husky to relay trigger to SMB output
    scope.io.tio4 = 'high_z'  # set trigger pin as input
    scope.trigger.module = 'basic'  # use basic (edge) triggering
    scope.trigger.triggers = 'tio4'  # set trigger module input to tio4
    scope.io.glitch_trig_mcx = 'trigger'  # output tirgger signal on glitch / trig SMB connector

    gm.build_and_load(NUM_ELEMENTS, "triggered", "GPIO4")
    
    # connect to BitCrusher
    _ = input("Press enter to begin")
    bc = Device()
    bc.arming_config.voltage = np.uint16(300)
    bc._write_arming_config()
    time.sleep(0.1)
    bc.arm()

    for i in range(count):
        # bc.arm(3)

        # TODO: Need to generate a precise trigger signal from the husky, or route a rough trigger signal from the 
        # husky to an AD3.
        # This triggers the AD3 to generate the pulse signal
        time.sleep(0.01)
        scope.io.tio3 = True
        time.sleep(0.001)
        scope.io.tio3 = False
        time.sleep(0.1)

        pattern = gm.getpattern(True)

        pltdata: list[int] = []
        for p in pattern:
            value = bin(int(p.hex(), 16)).count('1')
            pltdata.append(value)

        npdata = np.array(pltdata)
        np.save(f"results/rev-2/25mhz_tdc_bitcrusher_{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}.npy", npdata)

        plt.plot(pltdata)
        # plt.show()
        plt.savefig(f"results/rev-2/25mhz_tdc_bitcrusher_{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}.png", dpi=600)

    bc.disarm()

def main():
    gm = husky_setup()
    run_husky_fault(gm)
    # run_EMFI_prototype(gm)
    return


if __name__ == "__main__":
    main()
    raise SystemExit()