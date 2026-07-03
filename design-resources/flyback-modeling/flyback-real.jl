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
    ]
    System(eqs, t, [v1, v2, i1, i2], [L1, L2, K, M, Nps], systems=[p1, p2, n1, n2]; name=name)
end

# this simulation is stable until inductor.v2 falls below resistor_load.v,
# probably due to the diode.
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
    # @named source_val = Square(frequency = 100000, amplitude = 0.5, offset=0.5, start_time=0, smooth=false)
    @named source_val = RealOutput()
    @named capacitor_load = Capacitor(C=5e-6, v=0.0)
    @named resistor_p = Resistor(R=0.1)
    @named resistor_load = Resistor(R=1.5e6)
    @named diode = Diode()

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
        connect(inductor.n1, resistor_p.p)
        connect(source.n, resistor_p.n, inductor.n2, capacitor_load.n, resistor_load.n, gnd.g)
    ]

    System(test_system_eqs, t, [], [f, Imax, Tstop, start_time], systems=[inductor, gnd, source, source_val, capacitor_load, resistor_p, resistor_load, diode], initial_conditions=[inductor.v2 => 0]; name=name)
end

@named test_system = CoupledInductorTest1()
test_system_compiled = mtkcompile(test_system)
prob = ODEProblem(test_system_compiled, [], (0.0, 1e-3))
sol = solve(prob)
plot(
    sol, 
    idxs=[test_system_compiled.inductor.i1, test_system_compiled.inductor.i2, test_system_compiled.inductor.v1, test_system_compiled.inductor.v2],
    # idxs=[test_system_compiled.L1.p1.i, test_system_compiled.L1.p2.i, test_system_compiled.L1.p2.v, test_system_compiled.C1.v],
    dpi=300
)

plot(
    sol, 
    idxs=[test_system_compiled.source.p.v, test_system_compiled.inductor.i1, test_system_compiled.resistor_load.p.v],
    # idxs=[test_system_compiled.L1.p1.i, test_system_compiled.L1.p2.i, test_system_compiled.L1.p2.v, test_system_compiled.C1.v],
    dpi=300
)