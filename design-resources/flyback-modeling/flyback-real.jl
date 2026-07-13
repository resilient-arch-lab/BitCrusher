using ModelingToolkit, Plots, OrdinaryDiffEq
using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks

function square(x, f, amplitude, start_time)
     (x > start_time) * ((0.5*amplitude) + ((0.5*amplitude) *
     (4 * floor(f * (x - start_time)) - 2 * floor(2 * (x - start_time) * f) + 1)))
end

function CoupledInductor(; name, L1=10e-6, Nps=0.1, K=0.97)
    @parameters begin
        K=K
        Nps=Nps  # Np/Ns = 0.1
        L1=L1
        L2=L1/(Nps^2)
        M=K * Nps * L2
    end

    @named p1 = Pin()
    @named p2 = Pin()
    @named n1 = Pin()
    @named n2 = Pin()
    # @named magnetizing_inductor = Inductor()

    @variables begin
        v1(t)
        v2(t)
        i1(t)
        i2(t)
    end

    eqs = [
        v1 ~ p1.v - n1.v
        v2 ~ p2.v - n2.v
        
        i1 ~ p1.i
        0  ~ p1.i + n1.i
        i2 ~ p2.i
        0  ~ p2.i + n2.i
        
        v1 ~ L1*D(i1) + M*D(i2)
        v2 ~ L2*D(i2) + M*D(i1)

        # connect(magnetizing_inductor.p, p1)
        # connect(magnetizing_inductor.n, n1)
    ]
    System(eqs, t, [v1, v2, i1, i2], [L1, L2, K, M, Nps], systems=[p1, p2, n1, n2, magnetizing_inductor]; name=name)
end

function IdealTransformer(; name, Nps)
    @parameters begin
        Nps=Nps  # Np/Ns = 0.1
    end
    
    @named p1 = Pin()
    @named p2 = Pin()
    @named n1 = Pin()
    @named n2 = Pin()

    @variables begin
        v1(t)
        v2(t)
        i1(t)
        i2(t)
    end

    eqs = [
        v1 ~ p1.v - n1.v
        v2 ~ p2.v - n2.v

        i1 ~ p1.i
        0  ~ p1.i + n1.i
        i2 ~ p2.i
        0  ~ p2.i + n2.i
        
        i2 ~ i1*Nps
    ]

    System(eqs, t, [v1, v2, i1, i2], [Nps], systems=[p1, p2, n1, n2], name=name)
end

function ControlledSwitch(; name)
    @named n = Pin()
    @named p = Pin()
    @named u = RealInput()

    @variables begin
        v(t)
        i(t)
    end

    eqs = [ 
        0 ~ ifelse(u.u > 0.5, n.v - p.v, n.i)
        0 ~ ifelse(u.u > 0.5, n.i + p.i, p.i)
        v ~ p.v - n.v
        i ~ p.i
        # p.i + n.i ~ 0
        # 0 ~ ifelse(u.u > 0.5, v, i)
    ]
    ODESystem(eqs, t, [v, i], []; name, systems=[p, n, u])
end


function FlybackTransformer(; name, L_m=10e-6, Nps=0.1)
    @parameters begin
        Nps=Nps  # Np/Ns = 0.1
        L_m=L_m
    end

    @named p1 = Pin()
    @named p2 = Pin()
    @named n1 = Pin()
    @named n2 = Pin()
    @named magnetizing_inductor = Inductor(L=L_m, i=0)
    @named transformer_port = OnePort()
    # @named transformer = IdealTransformer(Nps=Nps)

    @variables begin
        vin(t)
        vout(t)
        iin(t)  # input port current
        iout(t)  # output port current
        ilm(t)  # magnetizing inductance current
        itp(t)  # transformer primary current
        iloop(t)
    end

    eqs = [
        # TwoPort voltage
        vin ~ p1.v - n1.v
        vout ~ p2.v - n2.v

        # TwoPort current
        iin ~ p1.i
        0  ~ p1.i + n1.i
        iout ~ p2.i
        0  ~ p2.i + n2.i

        # Primary side current properties
        itp ~ transformer_port.i
        ilm ~ magnetizing_inductor.i
        iloop ~ magnetizing_inductor.p.i - transformer_port.p.i
        # iin ~ itp + ilm

        # Ideal transformer equations
        iout ~ -itp*Nps
        vout ~ vin/Nps

        connect(p1, magnetizing_inductor.p, transformer_port.p)
        connect(n1, magnetizing_inductor.n, transformer_port.n)
    ]

    System(eqs, t, [vin, vout, iin, iout, ilm, itp, iloop], [Nps, L_m], systems=[p1, p2, n1, n2, magnetizing_inductor, transformer_port], name=name)
end

function PerfectDiode(; name)
    @named oneport = OnePort()
    @unpack v, i = oneport
    
    event = [v <= 0] => [i ~ 0]

    extend(System([], t, [v, i], []; name=name), oneport)
end

# this simulation is stable until inductor.v2 falls below resistor_load.v,
# probably due to the diode. Or maybe some interaction between the diode 
# and the coupled inductance
function CoupledInductorTest1(; name)
    @parameters begin
        f = 100000
        Imax = 1
        Tstop = 0.0001
        start_time=0
    end

    @named inductor = CoupledInductor(Nps=0.1, K=0.97)
    @named gnd = Ground()
    @named source = Current()
    # @named source = Voltage()
    # @named source_val = Square(frequency = 100000, amplitude = 0.5, offset=0.5, start_time=0, smooth=false)
    @named source_val = RealOutput()
    @named capacitor_load = Capacitor(C=5e-6, v=0.0)
    @named resistor_p = Resistor(R=0.1)
    @named resistor_load = Resistor(R=1.5e6)
    @named diode = Diode(Is=1e-3, n=0.95)

    test_system_eqs = [
        source_val.u ~ ifelse(
            ((4 * floor(f * (t - start_time)) - 2 * floor(2 * (t - start_time) * f) + 2) >= 1), 
            (Imax * 2) * ((-(t)*1e5) - (-floor(f * (t - start_time)))) * (t<=Tstop),
            0
        )
        connect(source_val, source.I)
        connect(source.p, inductor.p1)

        connect(inductor.p2, diode.p)
        connect(diode.n, capacitor_load.p, resistor_load.p)
        # connect(inductor.p2, capacitor_load.p, resistor_load.p)
        
        connect(inductor.n1, resistor_p.p)
        connect(source.n, resistor_p.n, inductor.n2, capacitor_load.n, resistor_load.n, gnd.g)
    ]

    System(test_system_eqs, t, [], [f, Imax, Tstop, start_time], systems=[inductor, gnd, source, source_val, capacitor_load, resistor_p, resistor_load, diode], initial_conditions=[inductor.v2 => 0]; name=name)
end

# Works, but not with the diode. Still not quite accurate though, the secondary
# side current is induced during the primary side current ramp (should be after)
function CoupledInductorTest2(; name)
    @parameters begin
        f = 100000
        Imax = 1
        Tstop = 0.00006
        start_time=0
    end

    @named transformer = FlybackTransformer(L_m=10e-6, Nps=0.1)
    @named gnd = Ground()
    @named source = Current()
    @named source_val = RealOutput()
    @named capacitor_load = Capacitor(C=5e-6, v=0.0)
    # @named resistor_p = Resistor(R=0.1)
    @named resistor_load = Resistor(R=1.5e6)

    # @named diode = Diode(Is=1e-6, n=0.95)
    # @named diode = VariableResistor(R_ref = 1e7)
    @named diode = ControlledSwitch()

    test_system_eqs = [
        source_val.u ~ ifelse(
            ((4 * floor(f * (t - start_time)) - 2 * floor(2 * (t - start_time) * f) + 2) >= 1), 
            (Imax * 2) * ((-(t)*1e5) - (-floor(f * (t - start_time)))) * (t<=Tstop),
            0
        )
        connect(source_val, source.I)
        connect(source.p, transformer.p1)

        # diode.u.u ~ ifelse(transformer.p2.v - capacitor_load.p.v < 0, 0, 1)
        diode.u.u ~ ifelse(diode.v < 0, 1, 1)
        # connect(transformer.p2, capacitor_load.p, resistor_load.p)
        connect(transformer.p2, diode.p)
        connect(diode.n, capacitor_load.p, resistor_load.p)
        
        # connect(transformer.n1, resistor_p.p)
        # connect(source.n, resistor_p.n, transformer.n2, capacitor_load.n, resistor_load.n, gnd.g)
        connect(source.n, transformer.n1, transformer.n2, capacitor_load.n, resistor_load.n, gnd.g)
    ]

    System(test_system_eqs, t, [], [f, Imax, Tstop, start_time], systems=[transformer, gnd, source, source_val, capacitor_load, resistor_load, diode], initial_conditions=[transformer.vout => 0]; name=name)
end

function CoupledInductorTest3(; name)
    @parameters begin
        f = 100000
        Imax = 1
        Tstop = 0.00006
        start_time=0
    end

    @named transformer = FlybackTransformer(L_m=10e-6, Nps=0.1)
    @named gnd = Ground()
    @named source = Voltage()
    @named source_val = RealOutput()
    @named capacitor_load = Capacitor(C=5e-6, v=0.0)
    # @named resistor_p = Resistor(R=0.1)
    @named resistor_load = Resistor(R=1.5e6)

    # @named diode = Diode(Is=1e-6, n=0.95)
    # @named diode = VariableResistor(R_ref = 1e7)
    @named diode = ControlledSwitch()
    @named switch = ControlledSwitch()

    test_system_eqs = [
        # source_val.u ~ ifelse(
            # ((4 * floor(f * (t - start_time)) - 2 * floor(2 * (t - start_time) * f) + 2) >= 1), 
            # (Imax * 2) * ((-(t)*1e5) - (-floor(f * (t - start_time)))) * (t<=Tstop),
            # 0
        # )
        source_val.u ~ 5
        connect(source_val, source.V)
        connect(source.p, transformer.p1)

        connect(switch.p, transformer.n1)
        switch.u.u ~ sin((8e4)*2*pi*t)

        # diode.u.u ~ ifelse(transformer.p2.v - capacitor_load.p.v < 0, 0, 1)
        diode.u.u ~ ifelse(diode.v < 0, 1, 1)
        # connect(transformer.p2, capacitor_load.p, resistor_load.p)
        connect(transformer.p2, diode.p)
        connect(diode.n, capacitor_load.p, resistor_load.p)
        
        # connect(transformer.n1, resistor_p.p)
        # connect(source.n, resistor_p.n, transformer.n2, capacitor_load.n, resistor_load.n, gnd.g)
        # connect(source.n, transformer.n1, transformer.n2, capacitor_load.n, resistor_load.n, gnd.g)
        connect(source.n, switch.n, transformer.n2, capacitor_load.n, resistor_load.n, gnd.g)
    ]

    System(test_system_eqs, t, [], [f, Imax, Tstop, start_time], systems=[transformer, gnd, source, source_val, capacitor_load, resistor_load, diode, switch], initial_conditions=[transformer.vout => 0]; name=name)
end


@named test_system = CoupledInductorTest3()
test_system_compiled = mtkcompile(test_system)
prob = ODEProblem(test_system_compiled, [], (0.0, 2e-4))
sol = solve(prob, Rodas5P(), abstol=1e-9, reltol=1e-12)
plot(
    sol, 
    idxs=[test_system_compiled.transformer.iin, test_system_compiled.transformer.itp, test_system_compiled.transformer.ilm, test_system_compiled.transformer.iout, test_system_compiled.diode.v, test_system_compiled.transformer.vin, test_system_compiled.transformer.iloop],
    # idxs=[test_system_compiled.L1.p1.i, test_system_compiled.L1.p2.i, test_system_compiled.L1.p2.v, test_system_compiled.C1.v],
    dpi=300
)

plot(
    sol, 
    idxs=[test_system_compiled.transformer.vin, test_system_compiled.transformer.vout, test_system_compiled.capacitor_load.v],
    # idxs=[test_system_compiled.L1.p1.i, test_system_compiled.L1.p2.i, test_system_compiled.L1.p2.v, test_system_compiled.C1.v],
    dpi=300
)