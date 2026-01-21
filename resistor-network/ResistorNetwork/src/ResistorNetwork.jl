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

@named test_network = SeriesNetwork(10)
model = mtkcompile(test_network)
prob = ODEProblem(model, Pair[], (0, 10))
sol = solve(prob)
plot(sol, idxs = [model.v, model.r1.v, model.r2.v],
    title = "RC Circuit Demonstration",
    labels = ["Network Voltage" "R1 Voltage" "R2 Voltage"])


end # module ResistorNetwork
