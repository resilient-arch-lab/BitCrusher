import time
from glitchmeter import GlitchMeter
from datetime import datetime
import json

gm = GlitchMeter('COM8')

logfile = open("log.txt", "a")
logfile.write("***********************************************************\n")
logfile.write("LOG STARTED: " + datetime.now().strftime("%d/%m/%Y %H:%M:%S") + "\n\n")

for elements in range(1, 32):

    logfile.write("\nTesting %d delay_elements"%elements)
    gm.build_and_load(elements, "always")
    
    mv = 900

    while mv < 1800:
        data = gm.getpattern()
        h = data[50].hex()
        b = format(int(h, 16), "032b")
        s = "%4d: %s"%(mv, b)
        print(s)
        logfile.write(s + "\n")

        mv += 10
        gm.set_coremv(mv)
        time.sleep(0.1)

    gm.set_coremv(1200)