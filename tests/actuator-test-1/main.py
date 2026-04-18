import itertools
from numpy._typing._array_like import NDArray


from numpy import float64


from ctypes import ArgumentError
from curses import baudrate
from datetime import datetime
from pathlib import Path
from itertools import product

import numpy as np
import chipwhisperer as cw
from gscrib import GCodeBuilder

class EnderMover:
    g: GCodeBuilder
    # z axis bounds are adjusted during use, representing offset from z position on machine start
    axes_bounds_min: list[float] = [0, 0, 0]
    axes_bounds_max: list[float] = [220, 220, 0]

    def __init__(self, port:str="/dev/ttyUSB0") -> None:
        self.g = GCodeBuilder(
            direct_write = "serial",
            port = port,
            baudrate = 115200
        )

        self._bounds_config()
        self.g.auto_home(x=0, y=0)
        self.g.set_axis(x=0, y=0, z=0)
        self.g.rapid(x=self.axes_bounds_max[0]/2, y=self.axes_bounds_max[1]/2, z=self.g.state.position[2])
        self.g.sleep(duration=0)  # wait for movements to complete
        self.calibrate_z_min()

    # Configure ender3v3 SE axes bounds and stuff
    def _bounds_config(self) -> None :
        self.g.set_bounds("axes", min=self.axes_bounds_min, max=self.axes_bounds_max)

    # Interactive z axis calibration routine
    def calibrate_z_min(self) -> None :
        # User needs to be able to adjust the current z position
        # When the user submits the z position, its set as the new lower z axes bound
        self.g.set_distance_mode("relative")
        print("Interactive z axis calibration")
        while True:
            cmd_txt = input("Relative z axis movement (in mm) or enter to finish: ")
            # detect exit 
            if cmd_txt == "":
                break
            try:
                rel_move = float(cmd_txt)
            except ArgumentError:
                print("Failed to parse input")
                continue
            
            self.axes_bounds_max[2] = rel_move
            self.axes_bounds_min[2] = rel_move
            self._bounds_config()
            self.g.rapid(z=rel_move)
            self.axes_bounds_max[2] = 0
            self.axes_bounds_min[2] = 0
            self._bounds_config()
            self.g.set_axis(z=0)
            self.g.sleep(duration=0)

        self.g.set_distance_mode("absolute")

        print("Interactive z axis calibration complete")

    def grid_sequence_generator(self, origin: tuple[float, float], shape: tuple[float, float], points_per_dim: int = 10):
        axes = tuple(np.linspace(origin[i], origin[i]+shape[i], points_per_dim) for i in range(2))
        for x, y in product(*axes):
            self.g.move(x=x, y=y)
            self.g.sleep(duration=0)
            yield x, y
            

def main() -> None:
    run_id = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    g = GCodeBuilder(
        output = Path(run_id + ".gcode"),
        direct_write = "serial",
        port = "/dev/ttyUSB0",
        baudrate = 115200
    )

    # The printer starts at an unknown position (since it has no encoder feedback to my knowlege).
    # I can't just run auto homing since removing the print head removes the z axis probe
    # If I could auto home only the x and y axes that would be perfect, since the z axis will
    # need to be manually set every experiment anyway.

