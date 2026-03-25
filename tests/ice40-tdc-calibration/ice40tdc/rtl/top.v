`include "settings.v"

module blink_test (
	input CLK_IN,      //-- 12 Mhz
	input GPIO1,
	input GPIO2,
	output GPIO3_LED,  //-- Led to blink
	input  GPIO4,

	input FLASH_SCK,
	input FLASH_SSB,
	output FLASH_IO0,
	input FLASH_IO1
);

    wire CLK;
    //assign CLK = CLK_IN;
	pll pll_inst(.clock_in(CLK_IN), .clock_out(CLK));

	reg [20:0] bitcnt;
	reg [7:0] data = 8'h89;

	always @(posedge FLASH_SCK or posedge FLASH_SSB) begin
		if(FLASH_SSB == 1'b1)
			bitcnt <= 0;
		else
			bitcnt <= bitcnt + 1; // non-reset condition
	end

	wire ARM;
	assign ARM = GPIO1;
	assign FLASH_IO0 = rdata[32 - bitcnt[4:0]];

	wire [31:0] rdata;
	wire [7:0] raddr;
	reg [7:0] waddr = 0;
	wire [31:0] wdata;
	reg rclke = 1;
	reg re = 1;
	reg wclke = 1;
	wire we;

	ram ram_inst(
		.wrclk(CLK),
		.wen(we),
		.waddr(waddr),
		.wdata(wdata),
		.rdclk(FLASH_SCK),
		.ren(~FLASH_SSB),
		.raddr(raddr),
		.rdata(rdata)
	);
	defparam ram_inst.MEM_INIT_FILE = "RAM_TEST.txt";

	reg done = 0;
	reg wet = 0; //Write Enable Trigger

`ifdef WE_TRIGGERED
	assign we = wet;
`endif
`ifdef WE_NEVER
	assign we = 1'b0;
`endif
`ifdef WE_ALWAYS
	assign we = 1'b1;
`endif

	//Write address just loops once it's enabled
   	always @(posedge CLK)
		if (we == 1'b1)
			waddr <= waddr + 1;

	wire trigger;
	assign trigger = `TRIGGER_CONDITION;
	
	//Write when we see trigger, clear once we reach end
	always @(posedge CLK)
		if (trigger && !done)
			wet <= 1'b1;
		else if (done)
			wet <= 1'b0;
	
	always @(posedge CLK)
	    if (ARM == 1'b1)
			done <= 1'b0;
		else if (waddr[7:0] == 8'hFF)
			done <= 1'b1;

	assign raddr = bitcnt[20:5]; //32-bit read location

	probe_and_tdc probe_and_tdc_inst(
		.clk(CLK),
		.tdc_data(wdata)
	);
	defparam probe_and_tdc_inst.DELAY_ITEMS=`NUM_DELAY_ELEMENTS;
	defparam probe_and_tdc_inst.TDC_DLYS_PER_TAP=`TDC_DLYS_PER_TAP;
	

	reg [23:0] counter = 0; 

	always @(posedge CLK) 
		counter <= counter + 1;

	//-- Toggle the LED
	assign GPIO3_LED =  counter[22];

endmodule
