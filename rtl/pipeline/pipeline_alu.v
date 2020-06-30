module pipeline_alu(
    clk,
    rst,

    inst_in,
    pc_in,

    // Rs/Rt values.
    rs_val_pre_override,
    rt_val_pre_override,

    // Whether to override Rd with Rs/Rt.
    rs_override_rd,
    rt_override_rd,

    // Whether to override Rs/Rt with ALU const.
    alu_const_override_rs,
    alu_const_override_rt,

    // Whether to perform zero-extension instead of sign-extension on ALU const.
    alu_const_zext,

    // Late branch done?
    br_late_done,

    // Multiplication state.
    latealu_mult_hi,
    latealu_mult_lo,

    // CPR[14].
    latealu_cpr14,

    // Output Rd index.
    rd_index,

    // Output Rd value.
    rd_value,

    // Output late (ALU-stage) branch enable.
    br_late_enable,

    // Output branch target.
    br_target,

    // Output whether to disable memwrite.
    memop_disable,

    // Output whether to disable DECODE stage exception.
    early_exception_disable,

    // Output LateALU parameters.
    latealu_enable,
    latealu_op,
    latealu_a0,
    latealu_a1,

    // Output exception.
    exception
);

input wire clk, rst;
input wire [31:0] inst_in, pc_in;
input wire [31:0] rs_val_pre_override, rt_val_pre_override;
input wire rs_override_rd, rt_override_rd;
input wire alu_const_override_rs, alu_const_override_rt;
input wire alu_const_zext;
input wire br_late_done;
input wire [31:0] latealu_mult_hi, latealu_mult_lo;
input wire [31:0] latealu_cpr14;

output reg [4:0] rd_index;
output reg [31:0] rd_value;
output reg br_late_enable;
output reg [31:0] br_target;
output reg memop_disable;
output reg early_exception_disable;
output reg latealu_enable;
output reg [5:0] latealu_op;
output reg [31:0] latealu_a0, latealu_a1;
output reg [2:0] exception;

// Rs/Rt/Rd indices.
wire [4:0] rs_index, rt_index, rd_pre_override;
assign rs_index = inst_in[25:21];
assign rt_index = inst_in[20:16];
assign rd_pre_override = inst_in[15:11];

wire [31:0] link_pc;

`ifdef CONFIG_NO_DELAY_SLOT
assign link_pc = pc_in + 4;
`else
assign link_pc = pc_in + 8;
`endif

wire [31:0] prediction_false_positive_recovery_pc;
assign prediction_false_positive_recovery_pc = link_pc;

wire [31:0] alu_const;
assign alu_const = {{16{inst_in[15] & !alu_const_zext}}, inst_in[15:0]};
wire [4:0] shift_const;
assign shift_const = inst_in[10:6];

reg [6:0] alu_func;
wire [31:0] rs_val, rt_val;
assign rs_val = alu_const_override_rs ? alu_const : rs_val_pre_override;
assign rt_val = alu_const_override_rt ? alu_const : rt_val_pre_override;

// Waiting for br_late_done?
reg waiting_for_br_late_done;

reg branch_taken_no_delay_slot;

`ifdef CONFIG_NO_DELAY_SLOT
// No branch has delay slot if configured not to.
task report_normal_branch_taken;
    branch_taken_no_delay_slot <= 1;
endtask
`else
task report_normal_branch_taken;
;
endtask
`endif

always @ (*) begin
    if(inst_in[31:26] != 0) alu_func = {1'b1, inst_in[31:26]};
    else alu_func = {1'b0, inst_in[5:0]};
end

// We need to handle overflow here...
wire [32:0] add_out, sub_out;
assign add_out = {rs_val[31], rs_val} + {rt_val[31], rt_val};
assign sub_out = {rs_val[31], rs_val} - {rt_val[31], rt_val};

wire [31:0] relative_branch_target;

`ifdef CONFIG_NO_DELAY_SLOT
assign relative_branch_target = pc_in + (alu_const << 2);
`else
assign relative_branch_target = pc_in + 4 + (alu_const << 2);
`endif

wire backward_jump;
assign backward_jump = $signed(alu_const) < 0;

// # of bits to shift.
// ONLY VALID for sll/sllv/srl/srlv/sra/srav.
wire [4:0] shift_bits;
assign shift_bits = alu_func[2] ? rs_val[4:0] : shift_const; // alu_func[2] indicates the `v` suffix.

always @ (posedge clk) begin
    exception <= 0;
    rd_value <= 0;
    br_late_enable <= 0;
    br_target <= 0;
    memop_disable <= 0;
    early_exception_disable <= 0;
    latealu_enable <= 0;
    latealu_op <= 0;
    branch_taken_no_delay_slot <= 0;

    if(rs_override_rd) rd_index <= rs_index;
    else if(rt_override_rd) rd_index <= rt_index;
    else rd_index <= rd_pre_override;

    if(rst) begin
        waiting_for_br_late_done <= 0;
    end else if(waiting_for_br_late_done && !br_late_done) begin
        rd_index <= 0;
        memop_disable <= 1;
        early_exception_disable <= 1;
    end
    else if(branch_taken_no_delay_slot) begin
        waiting_for_br_late_done <= br_late_enable;
        rd_index <= 0;
        memop_disable <= 1;
        early_exception_disable <= 1;
    end
    else begin
        waiting_for_br_late_done <= br_late_enable; // Delay slot
        case (alu_func)
            7'b0100000, 7'b1001000: // add, addi
                if(add_out[32] != add_out[31]) exception <= 3'b010; // overflow
                else rd_value <= add_out[31:0];
            7'b0100001, 7'b1001001: // addu, addiu
                rd_value <= add_out[31:0];
            7'b0100010: // sub
                if(sub_out[32] != sub_out[31]) exception <= 3'b010; // overflow
                else rd_value <= sub_out[31:0];
            7'b0100011: // subu
                rd_value <= sub_out[31:0];
            7'b0100100, 7'b1001100: // and, andi
                rd_value <= rs_val & rt_val;
            7'b0100101, 7'b1001101: // or, ori
                rd_value <= rs_val | rt_val;
            7'b0100111: // nor
                rd_value <= ~(rs_val | rt_val);
            7'b0100110, 7'b1001110: // xor, xori
                rd_value <= rs_val ^ rt_val;
            7'b0101010, 7'b1001010: // slt, slti
                rd_value <= $signed(rs_val) < $signed(rt_val);
            7'b0101011, 7'b1001011: // sltu, sltiu
                rd_value <= rs_val < rt_val;
            7'b0000000, 7'b0000100: begin // sll, sllv
                rd_value <= rt_val << shift_bits;
            end
            7'b0000010, 7'b0000110: begin // srl, srlv
                rd_value <= rt_val >> shift_bits;
            end
            7'b0000011, 7'b0000111: begin // sra, srav
                rd_value <= $signed(rt_val) >>> shift_bits;
            end
            7'b0011000: begin // mult
                latealu_enable <= 1;
                latealu_op <= 6'b000100;
                latealu_a0 <= rs_val;
                latealu_a1 <= rt_val;
                rd_index <= 0; // disable regwrite
            end
            7'b0010001: begin // mthi
                latealu_enable <= 1;
                latealu_op <= 6'b000101;
                latealu_a0 <= rs_val;
                rd_index <= 0; // disable regwrite
            end
            7'b0010011: begin // mtlo
                latealu_enable <= 1;
                latealu_op <= 6'b000110;
                latealu_a0 <= rs_val;
                rd_index <= 0; // disable regwrite
            end
            7'b0010000: begin // mfhi
                rd_value <= latealu_mult_hi;
            end
            7'b0010010: begin // mflo
                rd_value <= latealu_mult_lo;
            end
            7'b0001000, 7'b0001001: begin // jr, jalr
                br_late_enable <= 1;
                br_target <= rs_val;
                rd_index <= 31;
                rd_value <= link_pc; // skip delay slot
                report_normal_branch_taken();
            end
            7'b0001100: begin // syscall
                br_late_enable <= 1;
                br_target <= 'b0;
                branch_taken_no_delay_slot <= 1; // syscall has no delay slot
                latealu_enable <= 1;
                latealu_op <= 6'b001000;
                latealu_a0 <= pc_in;
            end
            7'b1000010, 7'b1000011: begin // j, jal
                // PC change already taken care of in fetch stage.
                rd_index <= 31;
                rd_value <= link_pc; // skip delay slot
            end
            7'b1001111: // lui
                rd_value <= alu_const << 16;
            7'b1100011, 7'b1101011, 7'b1100000, 7'b1101000, 7'b1100100: begin // lw, sw, lb, sb, lbu
                rd_value <= rs_val + alu_const;
            end
            7'b1000100: begin // beq
                if(rs_val == rt_val) begin
                    // `beq $0, $0, *` special case: = `b`
                    if(rs_index == 0 && rt_index == 0) br_late_enable <= 0;
                    else br_late_enable <= 1 ^ backward_jump;
                    br_target <= relative_branch_target;
                    report_normal_branch_taken();
                end else begin
                    br_late_enable <= 0 ^ backward_jump;
                    br_target <= prediction_false_positive_recovery_pc;
                end
            end
            7'b1000101: begin // bne
                if(rs_val != rt_val) begin
                    br_late_enable <= 1 ^ backward_jump;
                    br_target <= relative_branch_target;
                    report_normal_branch_taken();
                end else begin
                    br_late_enable <= 0 ^ backward_jump;
                    br_target <= prediction_false_positive_recovery_pc;
                end
            end
            7'b1000111: begin // bgtz
                if($signed(rs_val) > 0) begin
                    br_late_enable <= 1 ^ backward_jump;
                    br_target <= relative_branch_target;
                    report_normal_branch_taken();
                end else begin
                    br_late_enable <= 0 ^ backward_jump;
                    br_target <= prediction_false_positive_recovery_pc;
                end
            end
            7'b1000110: begin // blez
                if($signed(rs_val) <= 0) begin
                    br_late_enable <= 1 ^ backward_jump;
                    br_target <= relative_branch_target;
                    report_normal_branch_taken();
                end else begin
                    br_late_enable <= 0 ^ backward_jump;
                    br_target <= prediction_false_positive_recovery_pc;
                end
            end
            7'b1000001: // regimm
                case (rt_index)
                    5'b00000: begin // bltz
                        if($signed(rs_val) < 0) begin
                            br_late_enable <= 1 ^ backward_jump;
                            br_target <= relative_branch_target;
                            report_normal_branch_taken();
                        end else begin
                            br_late_enable <= 0 ^ backward_jump;
                            br_target <= prediction_false_positive_recovery_pc;
                        end
                    end
                    5'b00001: begin // bgez
                        if($signed(rs_val) >= 0) begin
                            br_late_enable <= 1 ^ backward_jump;
                            br_target <= relative_branch_target;
                            report_normal_branch_taken();
                        end else begin
                            br_late_enable <= 0 ^ backward_jump;
                            br_target <= prediction_false_positive_recovery_pc;
                        end
                    end
                    5'b10000: begin // bltzal
                        if($signed(rs_val) < 0) begin
                            br_late_enable <= 1 ^ backward_jump;
                            br_target <= relative_branch_target;
                            rd_index <= 31;
                            rd_value <= link_pc; // skip delay slot
                            report_normal_branch_taken();
                        end else begin
                            br_late_enable <= 0 ^ backward_jump;
                            br_target <= prediction_false_positive_recovery_pc;
                            rd_index <= 0;
                            report_normal_branch_taken();
                        end
                    end
                    5'b10010: begin // bltzall
                        // Predicted LIKELY.
                        if($signed(rs_val) < 0) begin
                            br_late_enable <= 0;
                            br_target <= relative_branch_target;
                            rd_index <= 31;
                            rd_value <= link_pc; // skip delay slot
                            report_normal_branch_taken();
                        end else begin
                            br_late_enable <= 1;
                            br_target <= prediction_false_positive_recovery_pc;
                            rd_index <= 0;
                        end
                    end
                    5'b10001, 5'b10011: begin // bgezal, bgezall
                        // Predicted LIKELY.
                        if($signed(rs_val) >= 0) begin
                            br_late_enable <= 0;
                            br_target <= relative_branch_target;
                            rd_index <= 31;
                            rd_value <= link_pc; // skip delay slot
                            report_normal_branch_taken();
                        end else begin
                            br_late_enable <= 1;
                            br_target <= prediction_false_positive_recovery_pc;
                            rd_index <= 0;
                        end
                    end
                    default:
                        exception <= 3'b001;
                endcase
            7'b1010000: begin // cp0
                if(inst_in[25]) begin // eret
                    br_late_enable <= 1;
                    br_target <= latealu_cpr14;
                    branch_taken_no_delay_slot <= 1; // eret has no delay slot
                    latealu_enable <= 1;
                    latealu_op <= 6'b001001;
                end else begin
                    case(inst_in[24:21])
                        4'b0000: begin // mfc0
                            latealu_enable <= 1;
                            latealu_op <= 6'b001010;
                            latealu_a0 <= inst_in[15:11];
                        end
                        4'b0100: begin // mtc0
                            latealu_enable <= 1;
                            latealu_op <= 6'b001011;
                            latealu_a0 <= inst_in[15:11];
                            latealu_a1 <= rt_val;
                        end
                        default: exception <= 3'b001;
                    endcase
                end
            end
            default:
                exception <= 3'b001; // bad op
        endcase
    end
end

endmodule