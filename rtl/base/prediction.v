module prediction(
    clk,
    rst,

    // Instruction feedback from instruction cache/memory.
    inst_feedback,

    // Stall feedback from fetch stage.
    fetch_stall,

    // Branch request from ALU.
    br_late,
    br_late_target,

    // Early branch command.
    early_branch_cmd,

    // Initial PC.
    initial_pc,

    // PC output for Fetch stage.
    npc,

    // High when the previous br_late is applied.
    br_late_done
);

input wire clk, rst;
input wire [31:0] inst_feedback;
input wire fetch_stall;
input wire br_late;
input wire [31:0] br_late_target;

// Visible AFTER FF logic.
input wire [3:0] early_branch_cmd;
wire early_branch, early_branch_rel, early_branch_if_backward, early_branch_beq;
assign early_branch = early_branch_cmd[0];
assign early_branch_rel = early_branch_cmd[1];
assign early_branch_if_backward = early_branch_cmd[2];
assign early_branch_beq = early_branch_cmd[3];

input wire [31:0] initial_pc;

output wire [31:0] npc;
output reg br_late_done;

reg [31:0] pc;

// Address of the branch delay slot of `npc`. Aligned with DECODE stage.
reg [31:0] npc_delay_slot;
always @ (posedge clk) npc_delay_slot <= npc + 4;

// Relative offset. Visible BEFORE FF logic.
wire [31:0] rel_offset;
assign rel_offset = {{14{inst_feedback[15]}}, inst_feedback[15:0], 2'b0};

// Rs & Rt indices. Visible BEFORE FF logic.
wire [4:0] rs_index, rt_index;
assign rs_index = inst_feedback[25:21];
assign rt_index = inst_feedback[20:16];

// Possible early branch targets. Calculated by FF logic.
reg [31:0] early_branch_target_abs;
reg [31:0] early_branch_target_rel;

// Whether relative offset is less than zero. Calculated by FF logic.
reg rel_offset_is_backward;

// Whether `rs_index == rt_index == 0`. Calculated by FF logic.
reg rs_rt_both_zero;

// Selected early branch target. Visible AFTER FF logic.
wire [31:0] early_branch_target;
assign early_branch_target = early_branch_rel ? early_branch_target_rel : early_branch_target_abs;

// Caculated early branch decision. AFTER FF logic.
wire apply_early_branch;
assign apply_early_branch =
    early_branch &
        (
            !early_branch_if_backward || // unconditional or predicted likely
            (early_branch_beq & rs_rt_both_zero) || // `beq` special case: `b`
            rel_offset_is_backward // backward branches are predicted taken.
        );

// Whether this is the first cycle after reset;
reg first_cycle;

// Combinational forward from DECODE stage.
// Visible AFTER FF logic.
assign npc =
    // Break dependency cycle.
    first_cycle ? pc :
    // ALU branch applied by FF logic. Highest priority.
    br_late_done ? pc :
    // Early branch applied.
    apply_early_branch ? early_branch_target :
    // Direct FF logic output
    pc;

always @ (posedge clk) begin
    // Pre-calculate data for comb logic.
    early_branch_target_abs <= {npc_delay_slot[31:28], inst_feedback[25:0], 2'b0};
    early_branch_target_rel <= npc_delay_slot + rel_offset;
    rel_offset_is_backward <= $signed(rel_offset) < $signed(0);
    rs_rt_both_zero <= rs_index == 0 && rt_index == 0;
end

always @ (posedge clk) begin
    if(rst) begin
        pc <= initial_pc;
        br_late_done <= 0;
        first_cycle <= 1;
    end else begin
        br_late_done <= 0;
        first_cycle <= 0;

        if(br_late) begin
            pc <= br_late_target;
            br_late_done <= 1;
        end else if(!fetch_stall)
            // Only move PC forward if we are not in a fetch stall.
            pc <= npc + 4;
    end
end

endmodule