module ResistorNetwork

using ModelingToolkit
using Plots
using OrdinaryDiffEq

using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant, Step, Sine
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
        P ~ v * i,
    ]

    sys = System(eqs, t, vars, pars; name, systems)
    return extend(sys, resistor)
end

function PowerResistorTB()
    systems = @named begin
        magnitude = Sine(offset = 1, amplitude = 10, frequency = 5)
        source = Voltage()
        resistor = PowerResistor()
        capacitor = Capacitor(C = 1, v = 0.0)
        ground = Ground()
    end

    eqs = [
        connect(magnitude.output, source.V),
        connect(resistor.n, source.n, capacitor.n, ground.g),
        connect(resistor.p, source.p, capacitor.p),
    ]

    @named sys = System(eqs, t; systems=systems)
    return sys
end

# Works now!
function test_power_resistor()
    sys = PowerResistorTB()
    model = mtkcompile(sys)
    prob = ODEProblem(model, Pair[], (0, 10))
    sol = solve(prob)

    plot(sol, idxs = [model.resistor.v, model.resistor.P],
        title = "Power Resistor",
        labels = ["Resistor voltage" "Resistor power dissipation"])
end

function find_resistor_network(resistor::System, R_V_max::Real, R_P_max::Real)
    ESR = resistor.R
    P = resistor.P_max

    # Calculate network parallel size
    n_parallel = cld(P, R_P_max)
    # Calculate ESR for each branch
    parallel_ESR = ESR^(1/n_parallel)

    # Now each branch must be:
    #   - Identical
    #   - Each resistor dissipating less than R_P_max
    #   - Each resistor voltage drop less than R_V_max
    #   - Made of only E24 values

    

end

end # module ResistorNetwork
