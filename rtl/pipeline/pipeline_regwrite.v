module pipeline_regwrite(
    // Exceptions from all stages.
    decode_exception,
    alu_exception,
    mem_exception,

    // Output: Final exception
    exception,

    // Rd index
    rd_index,

    // Enable register write?
    regwrite_enable,

    // Source selector: ALU or MEM?
    memread_enable,

    // ALU override.
    memop_disable,

    // ALU output
    alu_out,

    // MEM output
    mem_out,

    // Regfile ports.
    we, windex, win
);

input wire decode_exception;
input wire [2:0] alu_exception;
input wire [2:0] mem_exception;
output wire [6:0] exception;

input wire [4:0] rd_index;
input wire regwrite_enable, memread_enable;
input wire memop_disable;
input wire [31:0] alu_out, mem_out;

output wire we;
output wire [4:0] windex;
output wire [31:0] win;

wire [31:0] selected_source;

assign exception = {decode_exception, alu_exception, mem_exception};

assign we = regwrite_enable && exception == 0 && rd_index != 0;
assign windex = rd_index;
assign win = (memread_enable & ~memop_disable) ? mem_out : alu_out;

endmodule