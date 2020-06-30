module pipeline_regfetch(
    clk,

    // Instruction.
    inst_in,

    // Output values.
    rs_val,
    rt_val,

    // Regfile ports.
    rindex0, rout0,
    rindex1, rout1
);

input wire clk;
input wire [31:0] inst_in;
input wire [31:0] rout0, rout1;

output wire [31:0] rs_val, rt_val;
output wire [4:0] rindex0, rindex1;

assign rindex0 = inst_in[25:21]; // rs
assign rindex1 = inst_in[20:16]; // rt
assign rs_val = rout0;
assign rt_val = rout1;

endmodule