module im(clk, en, addr, addrout, dout, stall);

input wire clk, en;
input wire [31:0] addr;
output reg [31:0] addrout;
output reg [31:0] dout;
output reg stall;

reg [31:0] store[1023:0];

initial begin
    $readmemh("code.txt", store);
end

always @ (posedge clk) begin
    stall <= 0;
end

always @ (posedge clk) begin
    if(en) addrout <= addr;
end

always @ (posedge clk) begin
    if(en) dout <= store[addr[11:2]];
end

endmodule
