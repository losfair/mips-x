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
reg [63:0] cs_regimm;
reg [63:0] cs_cp0;

wire alufunc_enable = cs_control[1];
wire regimm_enable = cs_control[2];
wire cp0_enable = cs_control[3];

// Blockram
reg [63:0] microcode_control[63:0];
reg [63:0] microcode_alufunc[63:0];
reg [63:0] microcode_regimm[31:0];
reg [63:0] microcode_cp0[31:0];

assign cs =
        cs_control
        | (alufunc_enable ? cs_alufunc : 64'b0)
        | (regimm_enable ? cs_regimm : 64'b0)
        | (cp0_enable ? cs_cp0 : 64'b0);

initial begin
    $readmemh("microcode_control.hex", microcode_control);
    $readmemh("microcode_alufunc.hex", microcode_alufunc);
    $readmemh("microcode_regimm.hex", microcode_regimm);
    $readmemh("microcode_cp0.hex", microcode_cp0);
end

always @ (posedge clk) begin
    cs_control <= microcode_control[inst_in[31:26]];
end

always @ (posedge clk) begin
    cs_alufunc <= microcode_alufunc[inst_in[5:0]];
end

always @ (posedge clk) begin
    cs_regimm <= microcode_regimm[inst_in[20:16]];
end

always @ (posedge clk) begin
    cs_cp0 <= microcode_cp0[inst_in[25:21]];
end

endmodule