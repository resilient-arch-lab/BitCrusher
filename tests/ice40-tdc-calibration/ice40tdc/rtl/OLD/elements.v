// This file contains device-specific mapping.

// Single delay element using a LUT4 configured as a buffer
module delay_element(
    input din,
    output dout
);

   //SB_LUT4 SB_LUT4_inst ( .O (dout), // output 
   //                      .I0 (1'b0), // data input 0
   //                      .I1 (1'b0), // data input 1
   //                      .I2 (1'b0), // data input 2
   //                      .I3 (din) // data input 3
   //                     );
   //defparam SB_LUT4_inst.LUT_INIT=16'b1111111100000000;
    
    SB_CARRY SB_CARRY_inst ( .CO(dout),
                            .I0(1'b0),
                            .I1(1'b1),
                            .CI(din));

endmodule

// Single inverter using a LUT4 configured as an inverter
module invert_element(
    input din,
    output dout
);

   SB_LUT4 SB_LUT4_inst ( .O (dout), // output 
                         .I0 (1'b0), // data input 0
                         .I1 (1'b0), // data input 1
                         .I2 (1'b0), // data input 2
                         .I3 (din) // data input 3
                        );
   defparam SB_LUT4_inst.LUT_INIT=16'b0000000011111111;

endmodule

// Sample element consisting of a FF, along with a
// LUT4 based delay element for chaining together
// and building a TDC.

module sample_element#(
    parameter TDC_DLYS_PER_TAP = 1, 
)
(
   input din,
   input clk,
   output dout,
   output sampleout
);
    wire [TDC_DLYS_PER_TAP:0] dly;

	genvar i;
	generate
	for (i=0; i < TDC_DLYS_PER_TAP; i=i+1) begin: generate_delay
		delay_element delay_element_inst (
		.din(dly[i]),
		.dout(dly[i+1])
		);
	end
	endgenerate
    
    assign dly[0] = din;
    assign dout = dly[TDC_DLYS_PER_TAP];

SB_DFF SB_DFF_inst ( .Q(sampleout), // Registered Output
                     .C(clk), // Clock
                     .D(din) // din 
);
endmodule
