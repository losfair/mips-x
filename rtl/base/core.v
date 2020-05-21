module core(clk, rst_in, exception_out);

input wire clk;
input wire rst_in;
output wire [6:0] exception_out;

wire regfile_we;
wire [4:0] regfile_windex, regfile_rindex0, regfile_rindex1;
wire [31:0] regfile_win;
wire [31:0] regfile_rout0, regfile_rout1;

regfile regfile_0(clk, regfile_we, regfile_windex, regfile_win, regfile_rindex0, regfile_rout0, regfile_rindex1, regfile_rout1);

// Reset for at least two cycles.
reg [1:0] reset_buffer = 2'b11;
always @ (posedge clk) begin
    reset_buffer[0] <= reset_buffer[1];
    reset_buffer[1] <= rst_in;
end
wire rst;
assign rst = reset_buffer[0] | reset_buffer[1] | rst_in;

// Pipeline begin

// Ports.

// [FETCH] Current PC.
wire [31:0] current_pc;
wire [31:0] current_pc_d1;
wire [31:0] current_pc_d3;
delay #(32, 1, 0) delay_current_pc_d1(clk, rst, current_pc, current_pc_d1);
delay #(32, 2, 0) delay_current_pc_d3(clk, rst, current_pc_d1, current_pc_d3);

// [FETCH] Current instruction.
wire [31:0] current_inst;
wire [31:0] current_inst_d1;
delay #(32, 1, 0) delay_current_inst_d1(clk, rst, current_inst, current_inst_d1);

// [FETCH] Late branch completion signal.
wire br_late_done;
wire br_late_done_d1;
delay #(1, 1, 0) delay_br_late_done_d1(clk, rst, br_late_done, br_late_done_d1);

// [DECODE] Control signal register.
wire [63:0] cs;

// [DECODE] Exception.
wire decode_exception;
wire decode_exception_d2;
delay #(1, 2, 0) delay_decode_exception_d2(clk, rst, decode_exception, decode_exception_d2);

// [DECODE] Memory r/w enable.
wire memread_enable, memwrite_enable;
wire memread_enable_d1, memread_enable_d2, memwrite_enable_d1;
delay #(1, 1, 0) delay_memread_enable_d1(clk, rst, memread_enable, memread_enable_d1);
delay #(1, 1, 0) delay_memread_enable_d2(clk, rst, memread_enable_d1, memread_enable_d2);
delay #(1, 1, 0) delay_memwrite_enable_d1(clk, rst, memwrite_enable, memwrite_enable_d1);

// [DECODE] Register write enable.
wire regwrite_enable;
wire regwrite_enable_d1;
wire regwrite_enable_d2;
delay #(1, 1, 0) delay_regwrite_enable_d1(clk, rst, regwrite_enable, regwrite_enable_d1);
delay #(1, 1, 0) delay_regwrite_enable_d2(clk, rst, regwrite_enable_d1, regwrite_enable_d2);

// [DECODE] ALU const mode.
wire rs_override_rd, rt_override_rd;

// [DECODE] Early branch command.
wire [3:0] early_branch_cmd;

// [DECODE] Override with ALU const.
wire alu_const_override_rs, alu_const_override_rt;

// [REGFETCH] Values of Rs and Rt.
wire [31:0] rs_val, rt_val;

// [BYPASS] Values of Rs and Rt.
wire [31:0] bypassed_rs_val, bypassed_rt_val;
wire [31:0] bypassed_rt_val_d1;
delay #(32, 1, 0) delay_bypassed_rt_val_d1(clk, rst, bypassed_rt_val, bypassed_rt_val_d1);

// [ALU] Output Rd index.
wire [4:0] rd_index;
wire [4:0] rd_index_d1;
delay #(5, 1, 0) delay_rd_index_d1(clk, rst, rd_index, rd_index_d1);

// [ALU] Output Rd value.
wire [31:0] rd_value;
wire [31:0] rd_value_d1;
delay #(32, 1, 0) delay_rd_value_d1(clk, rst, rd_value, rd_value_d1);

// [ALU] Output late (ALU-stage) branch enable.
wire br_late_enable;

// [ALU] Output branch target.
wire [31:0] br_late_target;

// [ALU] Disable memread/memwrite.
wire memop_disable;
wire memop_disable_d1;
delay #(1, 1, 0) delay_memop_disable_d1(clk, rst, memop_disable, memop_disable_d1);

// [ALU] Output exception.
wire [2:0] alu_exception;
wire [2:0] alu_exception_d1;
delay #(3, 1, 0) delay_alu_exception_d1(clk, rst, alu_exception, alu_exception_d1);

// [MEM] Memory output.
wire [31:0] mem_out_value;

// [MEM] Memory exception.
wire [2:0] mem_exception;

// [REGWRITE] Final exception.
wire [6:0] final_exception;
assign exception_out = final_exception;

// Pipeline stages.

// Stage 1: Fetch.
pipeline_fetch pipeline_fetch_0(
    clk, rst,
    br_late_enable, br_late_target,
    early_branch_cmd,
    memread_enable,
    current_pc, current_inst,
    br_late_done
);

// Stage 2a: Decode.
pipeline_decode pipeline_decode_0(clk, current_inst, cs);

assign decode_exception = cs[63];

assign memread_enable = cs[17];
assign memwrite_enable = cs[18];
assign regwrite_enable = cs[19];

assign rs_override_rd = cs[24];
assign rt_override_rd = cs[25];

assign early_branch_cmd = cs[33:30];

assign alu_const_override_rs = cs[40];
assign alu_const_override_rt = cs[41];

// Stage 2b: Regfetch.
pipeline_regfetch pipeline_regfetch_0(
    clk,
    current_inst,
    rs_val, rt_val,
    regfile_rindex0, regfile_rout0,
    regfile_rindex1, regfile_rout1
);

// Stage pre-3: Bypass.
pipeline_bypass pipeline_bypass_0(
    clk, rst,
    current_inst_d1[25:21], current_inst_d1[20:16],
    rs_val, rt_val,
    rd_index, rd_value,
    regwrite_enable_d1,
    bypassed_rs_val, bypassed_rt_val
);

// Stage 3: ALU.
pipeline_alu pipeline_alu_0(
    clk, rst,
    current_inst_d1, current_pc_d1,
    bypassed_rs_val, bypassed_rt_val,
    rs_override_rd, rt_override_rd,
    alu_const_override_rs, alu_const_override_rt,
    br_late_done_d1,
    rd_index,
    rd_value,
    br_late_enable,
    br_late_target,
    memop_disable,
    alu_exception
);

// Stage 4: MEM.
wire [3:0] wbyte_enable;
assign wbyte_enable = 4'b1111;
pipeline_mem pipeline_mem_0(
    clk, rst,
    bypassed_rt_val_d1,
    rd_value,
    wbyte_enable,
    memread_enable_d1,
    memwrite_enable_d1,
    memop_disable,
    mem_out_value,
    mem_exception
);

// Stage 5: Regwrite.
pipeline_regwrite pipeline_regwrite_0(
    decode_exception_d2,
    alu_exception_d1,
    mem_exception,
    final_exception,
    rd_index_d1,
    regwrite_enable_d2,
    memread_enable_d2,
    memop_disable_d1,
    rd_value_d1,
    mem_out_value,
    regfile_we,
    regfile_windex,
    regfile_win
);

always @ (posedge clk) begin
    if(rst) begin
        $display("[%0d] RESET", $time);
    end else begin
        $display(
            "[%0d] DECODE_PC=0x%0x DECODE_I=0x%0x ALU_PC=0x%0x ALU_I=0x%0x RETIRE_PC=0x%0x exception=%b memop_disable=%b ALU_br_late_done=%b",
            $time,
            current_pc, current_inst, current_pc_d1, current_inst_d1, current_pc_d3,
            final_exception,
            memop_disable,
            br_late_done_d1
        );
    end
end

endmodule