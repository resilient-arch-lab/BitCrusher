


module ram #(
    parameter MEM_INIT_FILE = ""
    )(
    input           wrclk, 
    input           wen, 
    input [7:0]     waddr,
    input [31:0]    wdata,

    input           rdclk,
    input           ren,
    input [7:0]     raddr,
    output reg [31:0] rdata);
  
    reg [31:0] mem [0:128];
    
    initial begin
      if (MEM_INIT_FILE != "") begin
        $readmemh(MEM_INIT_FILE, mem);
      end
    end
   

    always @(posedge wrclk) begin
          if (wen)
              mem[waddr] <= wdata;
    end

    always @(posedge rdclk) begin
          if (ren)
              rdata <= mem[raddr];
    end
  endmodule