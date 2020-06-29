module pipeline_latealu(
    clk,
    rst,

    op,
    a0,
    a1,

    result_out,
    hi, lo
);

input wire clk, rst;
input wire [5:0] op;
input wire [31:0] a0, a1;
output reg [31:0] result_out;
output reg [31:0] hi, lo;

always @ (posedge clk) begin
    if(rst);
    else begin
        case (op)
            6'b000100: // mult
                {hi, lo} <= {{32{a0[31]}}, a0} * {{32{a1[31]}}, a1};
            6'b000101: // mthi
                hi <= a0;
            6'b000110: // mtlo
                lo <= a0;
        endcase
    end
end


endmodule