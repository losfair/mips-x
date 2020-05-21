module pipeline_decode(
    clk,

    // Instruction input.
    inst_in,

    // Control signal.
    cs
);

input wire clk;
input wire [31:0] inst_in;
output wire [63:0] cs;

reg [63:0] cs_control;
reg [63:0] cs_alufunc;

wire alufunc_enable = cs_control[1];

// Blockram
reg [63:0] microcode_control[63:0];
reg [63:0] microcode_alufunc[63:0];

// Special-case NOP.
reg was_nop;
always @ (posedge clk) was_nop <= inst_in == 32'b0;

assign cs =
    was_nop ? 64'b0 : (
        cs_control
        | (alufunc_enable ? cs_alufunc : 64'b0)
    );

initial begin
    $readmemh("microcode_control.hex", microcode_control);
    $readmemh("microcode_alufunc.hex", microcode_alufunc);
end

always @ (posedge clk) begin
    cs_control <= microcode_control[inst_in[31:26]];
end

always @ (posedge clk) begin
    cs_alufunc <= microcode_alufunc[inst_in[5:0]];
end

endmodule