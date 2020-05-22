module pipeline_regwrite(
    clk, rst,

    // Exceptions from all stages.
    decode_exception,
    alu_exception,
    mem_exception,

    // Output: Final exception. Aligned with REGWRITE INPUT.
    final_exception,

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

    // LateALU enable?
    latealu_enable,

    // LateALU result
    latealu_result,

    // Regfile ports.
    we, windex, win
);

input wire clk, rst;

input wire decode_exception;
input wire [2:0] alu_exception;
input wire [2:0] mem_exception;
output wire [6:0] final_exception;

input wire [4:0] rd_index;
input wire regwrite_enable, memread_enable;
input wire memop_disable;
input wire latealu_enable;
input wire [31:0] latealu_result;
input wire [31:0] alu_out, mem_out;

output wire we;
output wire [4:0] windex;
output wire [31:0] win;

wire [31:0] selected_source;

wire [6:0] exception_in;
assign exception_in = {decode_exception, alu_exception, mem_exception};

reg [6:0] exception;
reg exception_enable; // Fast path

assign final_exception = exception_enable ? exception : exception_in;

always @ (posedge clk) begin
    if(rst) begin
        exception <= 0;
        exception_enable <= 0;
    end else if(!exception && exception_in) begin
        exception <= exception_in;
        exception_enable <= 1;
    end
end

assign we = regwrite_enable && final_exception == 0 && rd_index != 0;
assign windex = rd_index;
assign win =
    latealu_enable ? latealu_result :
    (memread_enable & ~memop_disable) ? mem_out :
    alu_out;

endmodule