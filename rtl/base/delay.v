module delay(clk, rst, din, dout);

parameter WIDTH = 1;
parameter DELAY = 1;
parameter DEFAULT = 0;

input wire clk;
input wire rst;
input wire [WIDTH-1:0] din;
output wire [WIDTH-1:0] dout;

reg [WIDTH-1:0] delay_buf [DELAY-1:0];
assign dout = delay_buf[0];

integer i;

always @ (posedge clk) begin
    if(rst) for(i = 0; i <= DELAY-1; i = i + 1) delay_buf[i] <= DEFAULT;
    else begin
        for(i = 0; i <= DELAY-1; i = i + 1) begin
            if(i == DELAY-1) delay_buf[i] <= din;
            else delay_buf[i] <= delay_buf[i + 1];
        end
    end
end

endmodule
