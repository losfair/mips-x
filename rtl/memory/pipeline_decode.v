module pipeline_decode(
    clk,

    // Instruction input.
    inst_in,

    // Control signal.
    cs
);

input wire clk;
input wire [31:0] inst_in;

output reg [63:0] cs;

// Blockram
reg [63:0] microcode[63:0];

initial begin
    $readmemh("microcode.hex", microcode);
end

always @ (posedge clk) begin
    cs <= microcode[inst_in[31:26]];
end

endmodule