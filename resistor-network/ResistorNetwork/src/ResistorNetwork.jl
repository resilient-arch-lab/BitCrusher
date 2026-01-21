module ResistorNetwork

using ModelingToolkit
using Plots
using OrdinaryDiffEq

using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant
using ModelingToolkit: t_nounits as t

@component function SeriesNetwork(ESR = 1.0; name)
    @named oneport = OnePort()
    @unpack v, i = oneport

    pars = @parameters begin
        ESR = ESR
    end

    systems = @named begin
        r1 = Resistor(R=ESR/2)
        r2 = Resistor(R=ESR/2)
    end

    vars = @variables begin
        
    end

    eqs = Equation[
        v ~ r1.v + r2.v
    ]

    sys = System(eqs, t, vars, pars; name, systems)
    return extend(sys, oneport)
end

@component function PowerResistor(R=1.0, P_max=0.5; name)
    @named resistor = Resistor()
    @unpack v, i = resistor

    pars = @parameters begin
        R = R
        P_max = P_max
    end

    systems = @named begin
        
    end

    vars = @variables begin
        P(t), [description = "Power disipation"]
    end

    eqs = Equation[
        P ~ v * i
    ]

    sys = System(eqs, t, vars, pars; name, systems)
    return extend(sys, resistor)
end

function PowerResistorTB() 
    systems = @named begin
        resistor = PowerResistor()
        ground = Ground()
        source = Voltage()
        magnitude = Constant(k = 1.0)
    end

    eqs = Equation[
        source.V ~ magnitude.output,
        source.n ~ ground.g ~ resistor.n,
        source.p ~ resistor.p
    ]

    @named sys = System(eqs, t, [], []; systems=systems)
    model = mtkcompile(sys)
    prob = ODEProblem(model, Pair[], (0, 10))
    sol = solve(prob)

    plot(sol, idxs = [model.resistor.v, model.resistor.P],
    title = "RC Circuit Demonstration",
    labels = ["Resistor voltage" "Resistor power dissipation"])
end

@named test_network = SeriesNetwork(10)
model = mtkcompile(test_network)
prob = ODEProblem(model, Pair[], (0, 10))
sol = solve(prob)
plot(sol, idxs = [model.v, model.r1.v, model.r2.v],
    title = "RC Circuit Demonstration",
    labels = ["Network Voltage" "R1 Voltage" "R2 Voltage"])


end # module ResistorNetwork
