
trace_shape = (0.002, 35e-6)
trace_area = prod(trace_shape)  # m^2
trace_area = 1973.52524139*(trace_area*1e6)  # convert to circular mils

# The path must handle the average current continuously, and the peak current without getting too hot

# Peak current
Tmax = 110  # degrees C
Tamb = 25  # degrees C
Time = 0.001  # seconds

fuse_amps = trace_area*sqrt(log10(((Tmax-Tamb)/(234-Tamb))+1)/(Time*33))

# Continuous current
