module dm(clk, addr, we, win, wbyte_enable, dout);

input wire clk;
input wire [9:0] addr;
input wire we;
input wire [31:0] win;
input wire [3:0] wbyte_enable;
output reg [31:0] dout;

integer i;

reg [31:0] dm [1023:0]; // 1024 * 4 = 4096

initial begin
    for(i = 0; i < 1024; i = i + 1) dm[i] <= 0;
end

always @ (posedge clk) begin
    dout <= dm[addr];
    if(we) begin
        if(wbyte_enable[0]) dm[addr][7:0] <= win[7:0];
        if(wbyte_enable[1]) dm[addr][15:8] <= win[15:8];
        if(wbyte_enable[2]) dm[addr][23:16] <= win[23:16];
        if(wbyte_enable[3]) dm[addr][31:24] <= win[31:24];
    end
end

endmodule
