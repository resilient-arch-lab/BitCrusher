using ModelingToolkit, Plots, OrdinaryDiffEq
using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks

function CoupledInductor(; name, i1, i2, L1=10e-6, Nps=0.1, K=0.97)
    @parameters begin
        K=K
        Nps=Nps  # Np/Ns = 0.1
        L1=L1
        L2=L1/(Nps^2)
        M=K * Nps * L2
    end

    @named p1 = Pin(i=i1)
    @named p2 = Pin(i=-i1)
    @named n1 = Pin(i=i2)
    @named n2 = Pin(i=-i2)

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

function CoupledInductorTest1(; name)
    @named L1 = CoupledInductor(i1=0, i2=0, K=0.97)
    @named gnd = Ground()
    @named source = Voltage()
    @named source_val = RealOutput()
    @named C1 = Capacitor(C=5e-6, v=0.0)
    @named R1 = Resistor(R=0.1)
    @named RLoad = Resistor(R=50000)

    test_system_eqs = [
        connect(source_val, source.V)
        connect(source.p, L1.p1)
        connect(L1.p2, C1.p, RLoad.p)
        connect(L1.n1, R1.p)
        connect(source.n, R1.n, L1.n2, C1.n, RLoad.n, gnd.g)
        # source_val.u ~ 1 - (1*(t>0.05))
        source_val.u ~ 0 + ((0.1)*((t>0.01) & (t<0.05))) - ((20*(t-0.055))*((t>=0.05) & (t<0.055)))
    ]

    System(test_system_eqs, t, [], [], systems=[L1, gnd, source, source_val, C1, R1, RLoad], initial_conditions=[L1.v1 => 0]; name=name)
end

@named test_system = CoupledInductorTest1()
test_system_compiled = mtkcompile(test_system)
prob = ODEProblem(test_system_compiled, [], (0.0, 0.1))
sol = solve(prob)
plot(
    sol, 
    idxs=[test_system_compiled.L1.i1, test_system_compiled.L1.i2, test_system_compiled.L1.v1, test_system_compiled.L1.v2],
    # idxs=[test_system_compiled.L1.p1.i, test_system_compiled.L1.p2.i, test_system_compiled.L1.p2.v, test_system_compiled.C1.v],
    dpi=300
)