module pipeline_latealu(
    clk,
    rst,

    op,
    a0,
    a1,

    result_out
);

input wire clk, rst;
input wire [5:0] op;
input wire [31:0] a0, a1;
output reg [31:0] result_out;

always @ (posedge clk) begin
    if(rst);
    else begin
        case (op)
            6'b000010: // srl
                result_out <= a0 >> a1[4:0];
            6'b000011: // sra
                result_out <= $signed(a0) >> a1[4:0];
        endcase
    end
end


endmodule