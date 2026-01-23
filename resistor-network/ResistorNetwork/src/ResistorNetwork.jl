module ResistorNetwork

using ModelingToolkit
import ModelingToolkit: parameter_values, parameter_index, parameters
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

# Works for getting accurate networks, but I need to add logic so it handles
# max voltage and power constraints
function find_series_network(ESR::Real, V_max::Real, R_V_max::Real, R_P_max::Real, n_resistors::Integer=3)
    E24_bases = [1.0, 1.1, 1.2, 1.3, 1.5, 1.6, 1.8, 2.0, 2.2, 2.4, 2.7, 3.0, 3.3, 3.6, 3.9, 4.3, 4.7, 5.1, 5.6, 6.2, 6.8, 7.5, 8.2, 9.1]
    # E24_decades = [1e-2, 1e-1, 1, 1e1, 1e2, 1e3, 1e4, 1e5, 1e6]
    ESR_decade = floor(Int, log10(ESR))
    close_decades = [1*10.0^(ESR_decade-2) 1*10.0^(ESR_decade-1) 1*10.0^(ESR_decade)]
    options = E24_bases * close_decades  # [base, decade]

    # Exhaustive parameter search
    best_cmb = -1; best_error = Inf64
    best_R_Vs = Vector{Float64}(undef, n_resistors); best_R_Ps = Vector{Float64}(undef, n_resistors); 
    best_idx = -1
    n_candidates = 0
    R_Vs = Vector{Float64}(undef, n_resistors)
    none_found = true

    for (i, cmb) in enumerate(with_replacement_combinations(options, n_resistors))
        # Calculate ESR and error
        # cmb = [cmb...]
        esr_i = sum(cmb)
        esr_error = ((esr_i - ESR)/ESR)*100  # percent error

        # Check that network satisfies R_V_max constraints
        R_Vs .= V_max.*(cmb./esr_i)
        
        # Check R_P_max constraints
        R_Ps = (R_Vs.^2)./cmb

        # If everything passes, assign new best
        if !(all(R_Vs .< R_V_max) && all(R_Ps .< R_P_max)) continue end  # skip if voltage constraints not satisfied
        n_candidates += 1
        if (none_found)  # assign if there is no current best
            best_cmb = vec(cmb)
            best_error = esr_error
            best_R_Vs .= R_Vs
            best_R_Ps .= R_Ps
            best_idx = i
            none_found = false
        elseif (abs(esr_error) < abs(best_error))  # assign if new error is lower
            best_cmb .= cmb
            best_error = esr_error
            best_R_Vs .= R_Vs
            best_R_Ps .= R_Ps
            best_idx = i
        end
    end
    # println("Best option for $n_resistors resistors from $n_candidates candidates: [$best_idx] $(best_cmb) ($best_error% error)")
    # println("Voltage Drops: $(best_R_Vs)\tPower Dissipation: $(best_R_Ps)")

    if none_found
        return nothing, nothing, nothing, nothing
    else
        return [best_cmb...], best_error, best_R_Vs, best_R_Ps
    end
end

find_series_network(9999, 100, 50, 10, 3)  # works :)

function find_resistor_network(ESR::Real, P_max::Real, V_max::Real, R_V_max::Real, R_P_max::Real, max_series::Real=4, max_parallel::Real=3)
    P = P_max
    V_max = V_max

    # Calculate network parallel size
    n_parallel = min(cld(P, R_P_max), max_parallel)
    # Calculate ESR for each branch
    branch_ESR = ESR^(1/n_parallel)
    # Calculate P_max for each branch
    branch_P_max = P / n_parallel

    # Now each branch must be:
    #   - Identical
    #   - Each resistor dissipating less than R_P_max
    #   - Each resistor voltage drop less than R_V_max
    #   - Made of only E24 values

    for n_series in 1:max_series
        cmb, esr_error, R_Vs, R_Ps = find_series_network(branch_ESR, V_max, R_V_max, R_P_max, n_series)
        if !isnothing(cmb)
            network = repeat(reshape(cmb, 1, size(cmb, 1)), outer=n_parallel)
            println("Best network with $n_series series resistors:")
            display(network)
        else
            println("Cound not find a satisfying network of $n_series series resistors")
        end
        
    end
end

function test_find_network()
    @named resistor = PowerResistor(9999, 50, 100)
    find_resistor_network(9999, 50, 100, 50, 10)
end


test_find_network()

end # module ResistorNetwork
