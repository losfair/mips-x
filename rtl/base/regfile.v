module regfile(clk, we, windex, win, rindex0, rout0, rindex1, rout1);

input wire clk, we;
input wire [4:0] windex, rindex0, rindex1;
input wire [31:0] win;
output reg [31:0] rout0, rout1;

reg [31:0] store[31:0];
integer i;

initial begin
    for(i = 0; i <= 31; i = i + 1) store[i] <= 0;
end

always @ (posedge clk) begin
    if(we) store[windex] <= win;
    rout0 <= store[rindex0];
    rout1 <= store[rindex1];
end
/*
always @ (negedge clk) begin
    for(i = 0; i <= 31; i = i + 1) begin
        $write("[%0d] ", $time);
        for(i = 0; i < 32; i = i + 1) $write("<%0d>: %0d, ", i, store[i]);
        $write("\n");
    end
end
*/
endmodule
