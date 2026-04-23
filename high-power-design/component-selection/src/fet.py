from dataclasses import dataclass
from math import sqrt

def peak_current(T_Jmax: float, R_thJC: float, Z_thJC: float, R_DSon: float) -> float:
    return sqrt(((T_Jmax - 25) / (R_thJC*Z_thJC)) / (R_DSon))

def max_current(T_Jmax: float, R_thJC: float, R_DSon: float) -> float:
    return peak_current(T_Jmax, R_thJC, 1, R_DSon)

@dataclass(frozen=True)
class FETOperatingCondition:
    name: str
    pulse_width: float  # pulse width in seconds
    duty_cycle: float  # duty cycle (duty cycle < 1 => single pulse)
    T_Jmax: float

class FET:
    R_DSon: float
    R_thJC: float
    Z_thJC: dict[FETOperatingCondition, float]
    C_iss: float  # input capacitance
    Q_G: float  # gate charge
    R_G: float  # gate resistance
    V_GSon: float  # gate drive voltage

    def __init__(self, R_DSon: float, R_thJC: float):
        self.R_DSon = R_DSon
        self.R_thJC = R_thJC
        self.Z_thJC = {}

    def get_peak_currents(self) -> dict[FETOperatingCondition, float]:
        peak_currents: dict[FETOperatingCondition, float] = {}
        for i, (cond, Z_trans) in enumerate(self.Z_thJC.items()):
            peak_currents[cond] = peak_current(cond.T_Jmax, self.R_thJC, Z_trans, self.R_DSon)
        
        return peak_currents

    def get_rise_fall_time(self, ron: float = 0, roff: float = 0) -> tuple[float, float]:
        I_on = self.V_GSon / (self.R_G + ron)
        I_off = -self.V_GSon / (self.R_G + roff)
        
        t_on = self.Q_G / I_on
        t_off = self.Q_G / (-I_off)
        
        return t_on, t_off

    def get_rise_fall_time_rc(self, ron: float = 0, roff: float = 0):
        time_const_on = (self.R_G + ron) * self.C_iss
        time_const_off = (self.R_G + roff) * self.C_iss

        t_on = 2.2*time_const_on
        t_off = 2.2*time_const_off

        return t_on, t_off