# Ongoing Design and Evaluation Work

## Electronic Design
### Pulse Feedback
Currently, the two pulse feedback lines (`PulseCS` and `PulseVS`) are implemented as naive attenuator circuits for connection to a $1\text{M}\Omega$ oscilloscope input. `PulseVS` functions as a 20:1 attenuator between the `Probe+` and `GNDHV` nets. `PulseCS` functions as a 10:1 attenuator between the `Probe-` and `GNDHV` nets, with a $20\text{m}\Omega$ current sense resistor also separating the nets. The `PulseCS` attenuator signal is proportional to the current through the current sense resistor, and can also be used in conjunction with the `PulseVS` attenuator to determine the voltage drop over `Probe+` to `Probe-` (rather than just `Probe+` to `GNDHV`).  

![pulse measurement schematic graphic](assets/pulse-meas.png)

Open problems with this design:
- The CL05C100JB5NNNC capacitors selected for the attenuator circuits are only rated for 50V, but the voltage drop over the `PulseVS` attenuator is expected to be much greater
- Component selection should be optimized to minimize the impact of temperature variation and high voltage loading on measured signal. In practice
- For high precision measurements, very low tolerance component selection is necessary, increasing cost

Something like the [TI TPS4141](https://www.ti.com/lit/ds/symlink/tps4141-q1.pdf?ts=1792568133817&ref_url=https%253A%252F%252Fwww.ti.com%252Fproduct%252FTPS4141-Q1) would basically solve the issues of high voltage loading, temperature drift, and eliminate the need for careful component matching for high precision measurement. However, this would add a bit of control complexity and, at $5-$6 per IC, significant cost.

**Next Steps**
- [ ] Create simulation environment of `PulseCS` and `PulseVS` attenuators. This should obviously consider the non-ideal properties of the resistors (especially TCR and VCR) and capacitors.
- [ ] Perform component selection for attenuator circuits
- [ ] Simulate impact of temperature variation, bias, loading
- [ ] Simulate or calculate impact of component variation
- [?] If necessary, optimize PCB layout to minimize temperature gradients and parasitic effects
- [ ] Determine some kind of calibration procedure compensate for component / temperature variations on real device

### High Voltage Control Feedback

## Host Interface
There have been several instances of the device spontaneously disconnecting from the host, but the root cause has not yet been diagnosed.