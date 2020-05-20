module pipeline_fetch(
    clk,
    rst,

    // Late (ALU-stage) branch enable.
    br_late_enable,

    // Late branch target.
    br_target,

    // Early branch command from DECODE stage.
    early_branch_cmd,

    // Memory read enable feedback from DECODE stage.
    // When high, suspends fetch for 3 cycles.
    memread_enable,

    // Output: PC.
    pc_out,

    // Output: Instruction.
    inst_out,

    // Output: Late branch done signal.
    br_late_done_d1
);

input wire clk, rst;
input wire br_late_enable;
input wire [31:0] br_target;
input wire [3:0] early_branch_cmd;

input wire memread_enable;

output wire [31:0] pc_out;
output wire [31:0] inst_out;
output reg br_late_done_d1;

wire [31:0] im_addr;
wire [31:0] im_data;
wire im_stall;

reg [1:0] memread_stall_counter;
wire im_enable;
wire fetch_stall;
wire br_late_done;

reg first_cycle;

// Whether the fetch stage needs to be stalled now.
// Effects:
// - Override our current instruction output with nop (0).
// - Notify prediction.
// Visible AFTER FF logic.
assign fetch_stall = (!first_cycle & memread_enable) | memread_stall_counter != 0;

// Whether instruction memory read should be enabled.
// Visible AFTER FF logic (next cycle for IM).
// Therefore, on the first cycle after a memread stall has ended, we (correctly) see
// the last instruction fetched before the stall.
assign im_enable = !fetch_stall;

// Apply the override.
assign inst_out = fetch_stall ? 0 : im_data;

im im_0(clk, im_enable, im_addr, pc_out, im_data, im_stall);
prediction prediction_0(
    clk, rst,
    im_data,
    fetch_stall,
    br_late_enable, br_target,
    early_branch_cmd,
    im_addr,
    br_late_done
);

always @ (posedge clk) begin
    if(im_enable) br_late_done_d1 <= br_late_done;
end

// Stall instruction fetch for 3 cycles once memread_stall rises to high.
always @ (posedge clk) begin
    if(rst) begin
        memread_stall_counter <= 0;
        first_cycle <= 1;
    end else begin
        first_cycle <= 0;
        if(memread_enable) memread_stall_counter <= 2'b10;
        else begin
            case(memread_stall_counter)
                2'b10: memread_stall_counter <= 2'b01;
                2'b01: memread_stall_counter <= 2'b00;
                2'b00:;
            endcase
        end
    end
end
endmodule
