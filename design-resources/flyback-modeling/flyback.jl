using ModelingToolkit, Plots, OrdinaryDiffEq
using ModelingToolkit: t_nounits as t, D_nounits as D
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks
using LinearAlgebra

function FlybackCCMAveraged( ; name, V_d=1.7, R=1.5e6, R_c=0.05, R_sw=2, C=5e-6, L_m=10e-6, N=0.1) 
    @named vp_primary = Pin()
    @named vm_primary = Pin()
    @named vp_secondary = Pin()
    @named vm_secondary = Pin()
    @named din = RealInput()

    @parameters R_c = R_c R = R R_sw = R_sw C = C L_m = L_m V_d = V_d N = N

    @variables begin
        # state vars 
        i_Lm(t) 
        v_c(t)  
        
        # input vars  ( can the V_d parameter be assigned as a variable)
        v_s(t) 
        # Vd(t) = V_d  
        
        v(t)  # output vars 
        
        # d(t)  # interval 1 duty cycle
    end

    @unpack u = din
    d = u

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

    C1 = [0 R/(R+R_c)]  # interval 1 output vector
    C2 = [(N*R*R_c)/(R-R_c) R/(R-R_c)]  # interval 2 output vector
    
    x = [i_Lm; v_c]
    y = [v]

    eqs = [
        D.(x) ~ ((A1.*d + A2.*(1-d)) * x) + ((B1.*d + B2.*(1-d)) * [v_s; V_d])
        y ~ ((C1.*d + C2.*(1-d)) * x)
        y ~ [vp_secondary.v - vm_secondary.v]
        v_s ~ vp_primary.v - vm_primary.v
    ]

    System(eqs, t, [i_Lm, v_c, v_s, Vd, v, d], [R_c, R, R_sw, C, L_m, V_d, N]; systems = [vp_primary, vm_primary, vp_secondary, vm_secondary], name)
end