module pipeline_bypass(
    clk, rst,

    // Aligned with DECODE stage output
    decode_rs_index, decode_rt_index,
    regfetch_rs_val, regfetch_rt_val,

    // Aligned with ALU stage output
    alu_rd_index, alu_rd_val, alu_regwrite_enable,

    // Aligned with DECODE stage output
    out_rs_val, out_rt_val
);

integer i;

input wire clk, rst;
input wire [4:0] decode_rs_index, decode_rt_index;
input wire [31:0] regfetch_rs_val, regfetch_rt_val;
input wire [4:0] alu_rd_index;
input wire [31:0] alu_rd_val;
input wire alu_regwrite_enable;

output reg [31:0] out_rs_val, out_rt_val;

reg [4:0] mem_rd_index;
reg [31:0] mem_value;

always @ (*) begin
    if(decode_rs_index == 0) out_rs_val = 0;
    else if(decode_rs_index == alu_rd_index && alu_regwrite_enable) out_rs_val = alu_rd_val;
    else if(decode_rs_index == mem_rd_index) out_rs_val = mem_value;
    else out_rs_val = regfetch_rs_val;
end

always @ (*) begin
    if(decode_rt_index == 0) out_rt_val = 0;
    else if(decode_rt_index == alu_rd_index && alu_regwrite_enable) out_rt_val = alu_rd_val;
    else if(decode_rt_index == mem_rd_index) out_rt_val = mem_value;
    else out_rt_val = regfetch_rt_val;
end

always @ (posedge clk) begin
    if(rst) begin
        mem_rd_index <= 0;
    end else begin
        mem_rd_index <= alu_regwrite_enable ? alu_rd_index : 0;
        mem_value <= alu_rd_val;
    end
end

endmodule