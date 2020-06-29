module pipeline_latealu(
    clk,
    rst,

    op,
    a0,
    a1,

    result_out,
    hi, lo,

    cpr14_out
);

input wire clk, rst;
input wire [5:0] op;
input wire [31:0] a0, a1;
output reg [31:0] result_out;
output reg [31:0] hi, lo;
output wire [31:0] cpr14_out;

reg [31:0] cpr12, cpr13, cpr14;
assign cpr14_out = cpr14;

initial begin
    hi <= 'b0;
    lo <= 'b0;
    cpr12 <= 'b0;
    cpr13 <= 'b0;
    cpr14 <= 'b0;
end

always @ (posedge clk) begin
    if(rst) begin
        result_out <= 'b0;
    end else begin
        case (op)
            6'b000100: // mult
                {hi, lo} <= {{32{a0[31]}}, a0} * {{32{a1[31]}}, a1};
            6'b000101: // mthi
                hi <= a0;
            6'b000110: // mtlo
                lo <= a0;
            6'b001000: begin // syscall
                cpr14 <= a0; // pc
                cpr13[6:2] <= 5'b01000;
                cpr12[1] <= 1'b1;
            end
            6'b001001: begin // eret
                cpr12[1] <= 1'b0;
            end
            6'b001010: begin // mfc0
                case(a0[4:0])
                    'd12: result_out <= cpr12;
                    'd13: result_out <= cpr13;
                    'd14: result_out <= cpr14;
                    default: result_out <= 'd0;
                endcase
            end
            6'b001011: begin // mtc0
                case(a0[4:0])
                    'd12: cpr12 <= a1;
                    'd13: cpr13 <= a1;
                    'd14: cpr14 <= a1;
                    default: ;
                endcase
            end
        endcase
    end
end


endmodule