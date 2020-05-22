module testbench();

reg clk;
reg rst;
wire [9:0] exception;

core core_0(clk, rst, exception);

initial begin
    clk = 0;
    rst = 1;
end

always begin
    #5 clk = 1;
    #5 clk = 0;
    rst = 0;
    if(exception) begin
        $display("Exception: %b", exception);
        $finish();
    end
end

endmodule