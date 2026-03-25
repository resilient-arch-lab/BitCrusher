module probe_and_tdc #(
    parameter DELAY_ITEMS = 64, 
    parameter TDC_WIDTH = 32,
	parameter TDC_DLYS_PER_TAP = 1,
)(
    input                   clk,       //Clock used for measurement
    output [TDC_WIDTH-1:0]  tdc_data   //Output (registered)
);
	wire [DELAY_ITEMS:0] dly;
    assign dly[0] = clk;

	genvar i;
	generate
	for (i=0; i < DELAY_ITEMS; i=i+1) begin: generate_delay
                    (*keep*)
		            SB_CARRY carry_inst_inputdly (
                    .CO(dly[i+1]), //Carry out
                    .I0(1'b0),     //I0
                    .I1(1'b1),     //I1
                    .CI(dly[i])
            );
	end
	endgenerate

	wire [TDC_WIDTH:0] samplestate;
	assign samplestate[0] = dly[DELAY_ITEMS];

	generate
	for (i=0; i < TDC_WIDTH; i=i+1) begin: generate_sample           
        if (i == 0)(* BEL="X9/Y1/lc5", keep *) //As good a place as any to start
            SB_CARRY carry_inst_tdc (
                .CO(samplestate[i+1]), //Carry out
                  .I0(1'b0),     //I0
                  .I1(1'b1),     //I1
                .CI(samplestate[i])
            ); //Carry in
        
        if (i > 0) (*  keep *)
            SB_CARRY carry_inst_tdc (
                  .CO(samplestate[i+1]),
                  .I0(1'b0),
                  .I1(1'b1),
                  .CI(samplestate[i])
            );
          
        (*keep*)
        SB_DFFSR FDR_2 (
            .Q(tdc_data[i]),
            .C(clk),
            .D(samplestate[i]),
            .R(1'b0)
        );
	end
	endgenerate

endmodule