module testbench();

reg clk;
reg rst;
wire [6:0] exception;

core core_0(clk, rst, exception);

initial begin
    clk <= 0;
    rst <= 1;
end

always begin
    #5 clk = 1;
    #5 clk = 0;
    rst <= 0;
    if(exception) $finish();
end

endmodule