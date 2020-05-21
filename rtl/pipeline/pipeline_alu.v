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

    // Late branch done?
    br_late_done,

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
input wire br_late_done;

output reg [4:0] rd_index;
output reg [31:0] rd_value;
output reg br_late_enable;
output reg [31:0] br_target;
output reg memop_disable;
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
assign link_pc = pc_in + 8;

wire [31:0] alu_const;
assign alu_const = {{16{inst_in[15]}}, inst_in[15:0]};
wire [4:0] shift_const;
assign shift_const = inst_in[10:6];

reg [6:0] alu_func;
wire [31:0] rs_val, rt_val;
assign rs_val = alu_const_override_rs ? alu_const : rs_val_pre_override;
assign rt_val = alu_const_override_rt ? alu_const : rt_val_pre_override;

// Waiting for br_late_done?
reg waiting_for_br_late_done;

always @ (*) begin
    if(inst_in[31:26] != 0) alu_func = {1'b1, inst_in[31:26]};
    else alu_func = {1'b0, inst_in[5:0]};
end

// We need to handle overflow here...
wire [32:0] add_out, sub_out;
assign add_out = {rs_val[31], rs_val} + {rt_val[31], rt_val};
assign sub_out = {rs_val[31], rs_val} - {rt_val[31], rt_val};

wire [31:0] relative_branch_target;
assign relative_branch_target = pc_in + 4 + (alu_const << 2);

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
    latealu_enable <= 0;
    latealu_op <= 0;

    if(rs_override_rd) rd_index <= rs_index;
    else if(rt_override_rd) rd_index <= rt_index;
    else rd_index <= rd_pre_override;

    if(rst) begin
        waiting_for_br_late_done <= 0;
    end else if(waiting_for_br_late_done && !br_late_done) begin
        rd_index <= 0;
        memop_disable <= 1;
    end else begin
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
                latealu_enable <= 1;
                latealu_op <= 6'b000001;
                latealu_a0 <= rt_val;
                latealu_a1[4:0] <= shift_bits;
            end
            7'b0000010, 7'b0000110: begin // srl, srlv
                latealu_enable <= 1;
                latealu_op <= 6'b000010;
                latealu_a0 <= rt_val;
                latealu_a1[4:0] <= shift_bits;
            end
            7'b0000011, 7'b0000111: begin // sra, srav
                latealu_enable <= 1;
                latealu_op <= 6'b000011;
                latealu_a0 <= rt_val;
                latealu_a1[4:0] <= shift_bits;
            end
            7'b0001000, 7'b0001001: begin // jr, jalr
                br_late_enable <= 1;
                br_target <= rs_val;
                rd_index <= 31;
                rd_value <= link_pc; // skip delay slot
            end
            7'b0001100: // syscall
                exception <= 3'b011;

            7'b1000010, 7'b1000011: begin // j, jal
                // PC change already taken care of in fetch stage.
                rd_index <= 31;
                rd_value <= link_pc; // skip delay slot
            end
            7'b1001111: // lui
                rd_value <= alu_const << 16;
            7'b1100011, 7'b1101011: begin // lw, sw
                rd_value <= rs_val + alu_const;
            end
            7'b1000100: begin // beq
                br_target <= relative_branch_target;
                if(rs_val == rt_val) br_late_enable <= 1 ^ backward_jump;
                else br_late_enable <= 0 ^ backward_jump;
            end
            7'b1000101: begin // bne
                br_target <= relative_branch_target;
                if(rs_val != rt_val) br_late_enable <= 1 ^ backward_jump;
                else br_late_enable <= 0 ^ backward_jump;
            end
            7'b1000001: // regimm
                // regwrite enabled by default here. We need to override that by assigning 0 to rd_index.
                // Also, branch prediction NOT APPLIED!
                case (rt_index)
                    5'b00000: begin // bltz
                        rd_index <= 0;
                        br_target <= relative_branch_target;
                        if($signed(rs_val) < 0) br_late_enable <= 1;
                    end
                    5'b00001: begin // bgez
                        rd_index <= 0;
                        br_target <= relative_branch_target;
                        if($signed(rs_val) >= 0) br_late_enable <= 1;
                    end
                    default:
                        exception <= 3'b001;
                endcase
            default:
                exception <= 3'b001; // bad op
        endcase
    end
end

endmodule