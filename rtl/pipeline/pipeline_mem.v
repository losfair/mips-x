module pipeline_mem(
    clk,
    rst,

    // Rt value from Regfetch.
    rt_value,

    // Rd value output from ALU.
    rd_value,

    // Byte-enable signal from ALU.
    wbyte_enable,

    // Memory {read,write} enable.
    memread_enable,
    memwrite_enable,

    // ALU override.
    alu_memop_disable,

    // Memory output.
    out_value,

    // Memory exception. Stall is an exception, since
    // stalling is not allowed after DECODE stage.
    exception
);

input wire clk, rst;
input wire [31:0] rt_value, rd_value;
input wire [3:0] wbyte_enable;
input wire memread_enable, memwrite_enable;
input wire alu_memop_disable;
output wire [31:0] out_value;
output wire [2:0] exception;

assign exception = 0;

wire real_memwrite_enable = memwrite_enable & ~alu_memop_disable;

dm dm_0(clk, rd_value, real_memwrite_enable, rt_value, wbyte_enable, out_value);

endmodule
