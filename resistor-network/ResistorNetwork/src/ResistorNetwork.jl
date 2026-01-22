module ResistorNetwork

using ModelingToolkit
using Plots
using OrdinaryDiffEq
using Combinatorics

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

@component function PowerResistor(R=1.0, P_max=0.5, V_max=500; name)
    @named resistor = Resistor()
    @unpack v, i = resistor

    pars = @parameters begin
        R = R
        P_max = P_max
        V_max = V_max
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
    V_max = resistor.V_max

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

# Works for getting accurate networks, but I need to add logic so it handles
# max voltage and power constraints
function find_series_network(ESR::Real, V_max::Real, R_V_max::Real, R_P_max::Real)
    E24_bases = [1.0 1.1 1.2 1.3 1.5 1.6 1.8 2.0 2.2 2.4 2.7 3.0 3.3 3.6 3.9 4.3 4.7 5.1 5.6 6.2 6.8 7.5 8.2 9.1]
    E24_decades = [1e-2 1e-1 1 1e1 1e2 1e3 1e4 1e5 1e6]
    ESR_decade = floor(Int, log10(ESR))
    close_decades = [1*10^(ESR_decade-2) 1*10^(ESR_decade-1) 1*10^(ESR_decade)]
    options = E24_bases' * close_decades  # [base, decade]

    out = []

    for n in 1:4
        cmbs = collect(with_replacement_combinations(options, n))
        esrs = vec(sum(stack(cmbs), dims=1))
        error = abs.(esrs.-ESR)
        best_idx = argmin(error)
        best_error = ((esrs[best_idx] - ESR)/ESR) * 100
        println("Best option for $n resistors: $(cmbs[best_idx]) ($best_error% error)")
    end

    # Exhaustive parameter search
    # for n in 1:4
    #     cmbs = collect(with_replacement_combinations(options, n))
    #     esrs = vec(sum(stack(cmbs), dims=1))
    #     error = abs.(esrs.-ESR)
    #     best_idx = argmin(error)
    #     best_error = ((esrs[best_idx] - ESR)/ESR) * 100
    #     println("Best option for $n resistors: $(cmbs[best_idx]) ($best_error% error)")
    # end
end

end # module ResistorNetwork
