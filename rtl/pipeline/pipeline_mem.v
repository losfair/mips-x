module pipeline_mem(
    clk,
    rst,

    // Rt value from Regfetch.
    rt_value,

    // Rd value output from ALU.
    rd_value,

    // Memory access width signal from decode stage.
    maccess_width,

    // Memory access zero-extension signal from decode stage.
    maccess_zext,

    // Memory {read,write} enable.
    memread_enable,
    memwrite_enable,

    // ALU override.
    alu_memop_disable,

    // Final exception.
    // Memory write IS side effect, so we should not continue once exception is high.
    has_final_exception,

    // Memory output.
    out_value,

    // Memory exception. Stall is an exception, since
    // stalling is not allowed after DECODE stage.
    exception
);

input wire clk, rst;
input wire [31:0] rt_value, rd_value;
input wire [1:0] maccess_width;
input wire maccess_zext;
input wire memread_enable, memwrite_enable;
input wire alu_memop_disable;
input wire has_final_exception;
output wire [31:0] out_value;
output wire [2:0] exception;

wire [3:0] wbyte_enable;
wire [31:0] dm_din, dm_dout;

assign exception = 0;

wire real_memwrite_enable;
assign real_memwrite_enable = memwrite_enable & ~alu_memop_disable & ~has_final_exception;

wire [1:0] addrtail_d1;
wire [1:0] maccess_width_d1;
wire maccess_zext_d1;

delay #(2, 1, 0) delay_addrtail_d1(clk, rst, rd_value[1:0], addrtail_d1);
delay #(2, 1, 0) delay_maccess_width_d1(clk, rst, maccess_width, maccess_width_d1);
delay #(1, 1, 0) delay_maccess_zext_d1(clk, rst, maccess_zext, maccess_zext_d1);

// `mread` is attached to AFTER the data memory's clock gate.
// So its inputs must be delayed (and aligned with DM output).
mread mread_0(addrtail_d1, maccess_width_d1, maccess_zext_d1, dm_dout, out_value);

mwrite mwrite_0(rd_value[1:0], maccess_width, rt_value, wbyte_enable, dm_din);

dm dm_0(clk, rd_value[11:2], real_memwrite_enable, dm_din, wbyte_enable, dm_dout);

endmodule
