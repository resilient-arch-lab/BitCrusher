using ModelingToolkit, Plots, OrdinaryDiffEq
using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks
using LinearAlgebra
using ControlSystemsBase



function FlybackCCMAveraged( ; name, N=1, R_L=1, C_L=1, L_m=1, D1=0.2)
    D1 = D1
    D2 = 1-D1
    A = [
        0           (N*D2)/L_m;
        -(N*D2)/C_L   -1/(R_L*C_L)
    ]
    B = [D1/L_m; 0]
    C = [D1 0]

    @named statespace = StateSpace(A, B, C)
    @named vin = VoltageSensor()
    @named vout = Voltage()

    eqs = [
        vin.v ~ statespace.input.u
        statespace.x[2] ~ vout.V.u
    ]

    System(eqs, t, [], []; systems = [statespace, vin, vout], name)

end

function FlybackParasiticCCMAveraged( ; name, V_d=1.7, R_L=1.5e6, R_c=0.05, R_sw=2, C_L=5e-6, L_m=10e-6, N=0.1, D1=0.2)
    D1 = D1
    D2 = 1-D1
    A1 = [
        -R_sw/L_m       0; 
        0               -1/((R_L*C_L)+(R_c*C_L))
    ]  # interval 1 state matrix
    A2 = [
        (N^2 * R_c * R_L)/(R_L*L_m - R_c*L_m) (N*R_L)/(R_L*L_m - R_c*L_m);
        -(N*R_L)/(R_L*C_L - R_c*C_L)            -(1)/(R_L*C_L + R_c*C_L)
    ]  # interval 2 state matrix

    B1 = [
        -1/L_m  0;
        0       0
    ]  # interval 1 input matrix
    B2 = [
        0       -N/L_m;
        0       0
    ]  # interval 2 input matrix

    C1 = [1 0; 0 R_L/(R_L+R_c)]  # interval 1 output vector
    C2 = [0 0; (N*R_L*R_c)/(R_L-R_c) R_L/(R_L-R_c)]  # interval 2 output vector
    
    A = (A1.*D1) + (A2.*(1-D1))
    B = (B1.*D1) + (B2.*(1-D1))
    C = (C1.*D1) + (C2.*(1-D1))

    @named statespace = StateSpace(A, B, C)
    @named vin = VoltageSensor()
    @named vout = Voltage()

    eqs = [
        statespace.x[2] ~ vout.V.u

        vin.v ~ statespace.input.u[1]
        statespace.input.u[2] ~ V_d
    ]

    System(eqs, t, [], []; systems = [statespace, vin, vout], name)

end

function FlybackCCMAveragedTestbench(; name)
    @named flyback = FlybackCCMAveraged(N=0.1, R_L=1.5e6, C_L=5e-6, L_m=10e-6, D1=0.4)
    @named vdd = Voltage()
    @named V = Constant(k=22)
    @named gnd = Ground()

    eqs = [
       connect(V.output, vdd.V)
       connect(vdd.p, flyback.vin.p)
       connect(vdd.n, flyback.vin.n, flyback.vout.n, gnd.g)
    ]

    System(eqs, t, [], []; systems=[flyback, vdd, gnd, V], name)
end

function FlybackParasiticCCMAveragedTestbench(; name)
    
    @named flyback = FlybackParasiticCCMAveraged(V_d=1.7, R_L=1.5e6, R_c=0.05, R_sw=2, C_L=5e-6, L_m=10e-6, N=0.1, D1 = 0.4)
    @named vdd = Voltage()
    @named V = Constant(k=22)
    @named gnd = Ground()

    eqs = [
       connect(V.output, vdd.V)
       connect(vdd.p, flyback.vin.p)
       connect(vdd.n, flyback.vin.n, flyback.vout.n, gnd.g)
    ]

    System(eqs, t, [], []; systems=[flyback, vdd, gnd, V], name)
end

function FlybackCCMAveragedTest()
    @named flyback_test = FlybackCCMAveragedTestbench()
    compiled = mtkcompile(flyback_test)
    prob = ODEProblem(compiled, [], (0.0, 0.01))
    sol = solve(prob)
    plot(sol, idxs=[flyback_test.flyback.vout.v, flyback_test.flyback.vin.v, flyback_test.flyback.statespace.x[1]]; dpi=300)
end

function FlybackParasiticCCMAveragedTest()
    @named flyback_test = FlybackParasiticCCMAveragedTestbench()
    compiled = mtkcompile(flyback_test)
    prob = ODEProblem(compiled, [], (0.0, 0.01))
    sol = solve(prob)
    plot(sol, idxs=[flyback_test.flyback.vout.v, flyback_test.flyback.vin.v, flyback_test.flyback.statespace.x[1]]; dpi=300)
end


# I need to figure out how to calculate D2 and D3 from D1 and the magnitizing current
function FlybackParasiticDCMAveraged(; name, V_d=1.7, R_L=1.5e6, R_c=0.05, R_sw=2, C_L=5e-6, L_m=10e-6, N=0.1, D1=0.2, D2=0.6)
    D1 = D1
    D2 = D2
    D3 = 1 - (D1 + D2)
   
    A1 = [
        -R_sw/L_m       0; 
        0               -1/((R_L*C_L)+(R_c*C_L))
    ]  # interval 1 state matrix
    A2 = [
        (N^2 * R_c * R_L)/(R_L*L_m - R_c*L_m) (N*R_L)/(R_L*L_m - R_c*L_m);
        -(N*R_L)/(R_L*C_L - R_c*C_L)            -(1)/(R_L*C_L + R_c*C_L)
    ]  # interval 2 state matrix
    A3 = [
        0 0;
        0 -1/(R_L*C_L + R_c*C_L)     
    ]  # interval 3 state matrix

    B1 = [
        -1/L_m  0;
        0       0
    ]  # interval 1 input matrix
    B2 = [
        0       -N/L_m;
        0       0
    ]  # interval 2 input matrix
    B3 = [
        0 0;
        0 0
    ]  # interval 3 input matrix

    C1 = [1 0; 0 R_L/(R_L+R_c)]  # interval 1 output vector
    C2 = [0 0; (N*R_L*R_c)/(R_L-R_c) R_L/(R_L-R_c)]  # interval 2 output vector
    C3 = [0 0; 0 R_L/(R_L+R_c)]  # interval 3 output vector

    A = (A1.*D1) + (A2.*D2) + (A3.*D3)
    B = (B1.*D1) + (B2.*D2) + (B3.*D3)
    C = (C1.*D1) + (C2.*D2) + (C3.*D3)

    @named statespace = StateSpace(A, B, C)
    @named vin = VoltageSensor()
    @named vout = Voltage()

    eqs = [
        statespace.x[2] ~ vout.V.u

        vin.v ~ statespace.input.u[1]
        statespace.input.u[2] ~ V_d
    ]

    System(eqs, t, [], []; systems = [statespace, vin, vout], name)

end

function FlybackParasiticDCMAveragedTestbench(; name)
    
    @named flyback = FlybackParasiticDCMAveraged(V_d=1.7, R_L=1.5e6, R_c=0.05, R_sw=2, C_L=5e-6, L_m=10e-6, N=0.1, D1=0.2, D2=0.6)
    @named vdd = Voltage()
    @named V = Constant(k=22)
    @named gnd = Ground()

    eqs = [
       connect(V.output, vdd.V)
       connect(vdd.p, flyback.vin.p)
       connect(vdd.n, flyback.vin.n, flyback.vout.n, gnd.g)
    ]

    System(eqs, t, [], []; systems=[flyback, vdd, gnd, V], name)
end

function FlybackParasiticDCMAveragedTest()
    @named flyback_test = FlybackParasiticDCMAveragedTestbench()
    compiled = mtkcompile(flyback_test)
    prob = ODEProblem(compiled, [], (0.0, 0.01))
    sol = solve(prob)
    plot(sol, idxs=[flyback_test.flyback.vout.v, flyback_test.flyback.vin.v, flyback_test.flyback.statespace.x[1]]; dpi=300)
end

# inputs: primary curret, capacitor voltage
# outputs: primary curret, output voltage
# state vars: primary current, diode voltage drop
# Fixed duty cycle `D`
function FlybackParasiticCCMAveragedStateSpace(; V_d=1.7, R=1.5e6, R_c=0.05, R_sw=2, C=5e-6, L_m=10e-6, N=0.1, D=0.2)
    A1 = [
        -R_sw/L_m       0; 
        0               -1/((R*C)+R_c)
    ]  # interval 1 state matrix
    A2 = [
        (N^2 * R_c * R)/(R*L_m - R_c*C) (N*R)/(R*L_m - R_c*L_m);
        -(N*R)/(R*C - R_c*C)            -(1)/(R*C + R_c*C)
    ]  # interval 2 state matrix

    B1 = [
        -1/L_m  0;
        0       0
    ]  # interval 1 input matrix
    B2 = [
        0       -N/L_m;
        0       0
    ]  # interval 2 input matrix

    C1 = [1 0; 0 R/(R+R_c)]  # interval 1 output vector
    C2 = [0 0; (N*R*R_c)/(R-R_c) R/(R-R_c)]  # interval 2 output vector
    
    A = (A1.*D) + (A2.*(1-D))
    B = (B1.*D) + (B2.*(1-D))
    C = (C1.*D) + (C2.*(1-D))

    ss(A, B, C, 0)
end


# Plotting CCM time response:
system = FlybackParasiticCCMAveragedStateSpace(D=0.45)
res = step(system, 0.005)  # simulate step response for 0.005 seconds
plot(res; dpi = 300)  # y1 = input current, y2 = output voltage

# MTK StateSpace model
V_d=1.7
R=1.5e6
R_c=0.05
R_sw=2
C=5e-6
L_m=10e-6
N=0.1
D1 = 0.2

A1 = [
    -R_sw/L_m       0; 
    0               -1/((R*C)+R_c)
]  # interval 1 state matrix
A2 = [
    (N^2 * R_c * R)/(R*L_m - R_c*C) (N*R)/(R*L_m - R_c*L_m);
    -(N*R)/(R*C - R_c*C)            -(1)/(R*C + R_c*C)
]  # interval 2 state matrix

B1 = [
    -1/L_m  0;
    0       0
]  # interval 1 input matrix
B2 = [
    0       -N/L_m;
    0       0
]  # interval 2 input matrix

C1 = [1 0; 0 R/(R+R_c)]  # interval 1 output vector
C2 = [0 0; (N*R*R_c)/(R-R_c) R/(R-R_c)]  # interval 2 output vector

A = (A1.*D1) + (A2.*(1-D1))
B = (B1.*D1) + (B2.*(1-D1))
C = (C1.*D1) + (C2.*(1-D1))

@named mtkss = Blocks.StateSpace(A, B, C)
eqs = [
    mtkss.input.u[1] ~ 1  # 1A
    mtkss.input.u[2] ~ mtkss.output.u[2]
]
@named mtkmodel = System(eqs, t, [], []; systems=[mtkss])
compiled = mtkcompile(mtkmodel)
prob = ODEProblem(compiled, [], (0.0, 0.005))
sol = solve(prob)
plot(sol; dpi=300)