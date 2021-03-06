module pipeline_fetch(
    clk,
    rst,

    // Late (ALU-stage) branch enable.
    br_late_enable,

    // Late branch target.
    br_target,

    // Early branch command from DECODE stage.
    early_branch_cmd,

    // Stall request from DECODE stage.
    stall_request,

    // Initial PC on reset.
    initial_pc,

    // Output: PC.
    pc_out,

    // Output: Instruction.
    inst_out,

    // Output: Late branch done signal.
    br_late_done_d1,

    // Output: FETCH stage exception.
    fetch_exception
);

input wire clk, rst;
input wire br_late_enable;
input wire [31:0] br_target;
input wire [3:0] early_branch_cmd;

input wire [1:0] stall_request;
input wire [31:0] initial_pc;

output wire [31:0] pc_out;
output wire [31:0] inst_out;
output reg br_late_done_d1;
output wire [2:0] fetch_exception;

wire [31:0] im_addr;
wire [31:0] im_data;
wire im_stall;

reg [1:0] stall_counter;
wire im_enable;
wire fetch_stall;
wire br_late_done;

reg first_cycle;
reg br_late_done_hold;

// Whether the fetch stage needs to be stalled now.
// Effects:
// - Override our current instruction output with nop (0).
// - Notify prediction.
// Visible AFTER FF logic.
assign fetch_stall = (!first_cycle && stall_request != 0) | stall_counter != 0 | im_stall;

// Whether instruction memory read should be enabled.
// Visible AFTER FF logic (next cycle for IM).
// Therefore, on the first cycle after a stall has ended, we (correctly) see
// the last instruction fetched before the stall.
assign im_enable = !fetch_stall;

// Apply the override.
assign inst_out = (first_cycle || fetch_stall) ? 0 : im_data;

im im_0(clk, im_enable, im_addr, pc_out, im_data, im_stall, fetch_exception);
prediction prediction_0(
    clk, rst,
    im_data,
    fetch_stall,
    br_late_enable, br_target,
    early_branch_cmd,
    initial_pc,
    im_addr,
    br_late_done
);

// Aligned with IM output.
always @ (posedge clk) begin
    if(rst) begin
        br_late_done_hold <= 0;
        br_late_done_d1 <= 0;
    end else if(fetch_stall) begin
        if(br_late_done) br_late_done_hold <= 1;
        br_late_done_d1 <= 0;
    end else begin
        br_late_done_hold <= 0;
        br_late_done_d1 <= br_late_done_hold | br_late_done;
    end
end

always @ (posedge clk) begin
    if(rst) begin
        stall_counter <= 0;
        first_cycle <= 1;
    end else begin
        first_cycle <= 0;
        if(stall_request) begin
            stall_counter <= stall_request - 1;
        end
        else begin
            case(stall_counter)
                2'b11: stall_counter <= 2'b10;
                2'b10: stall_counter <= 2'b01;
                2'b01: stall_counter <= 2'b00;
                2'b00:;
            endcase
        end
    end
end
endmodule
