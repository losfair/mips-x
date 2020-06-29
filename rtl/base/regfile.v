module regfile(clk, we, windex, win, rindex0, rout0, rindex1, rout1);

input wire clk, we;
input wire [4:0] windex, rindex0, rindex1;
input wire [31:0] win;
output wire [31:0] rout0, rout1;

reg [31:0] store[31:0];
reg rindex0_was_written, rindex1_was_written;
reg [31:0] win_d1;
reg [31:0] rout0_before_write, rout1_before_write;

assign rout0 = rindex0_was_written ? win_d1 : rout0_before_write;
assign rout1 = rindex1_was_written ? win_d1 : rout1_before_write;

integer i;

initial begin
    for(i = 0; i <= 31; i = i + 1) store[i] <= 0;
end

always @ (posedge clk) begin
    if(we) store[windex] <= win;
    rout0_before_write <= store[rindex0];
    rout1_before_write <= store[rindex1];
end

always @ (posedge clk) rindex0_was_written <= we && rindex0 == windex;
always @ (posedge clk) rindex1_was_written <= we && rindex1 == windex;
always @ (posedge clk) win_d1 <= win;

always @ (posedge clk) begin
    if(we) begin
        $write("[%0d] ", $time);
        $write("Regwrite: %0d = %0d ", windex, win);
        if(rindex0 == windex) $write("Rs write: %0d = %0d ", rindex0, win);
        if(rindex1 == windex) $write("Rt write: %0d = %0d ", rindex1, win);
        $write("\n");
    end
end

always @ (negedge clk) begin
    $write("[%0d] ", $time);
    for(i = 0; i < 32; i = i + 1) $write("<%0d>: %0d, ", i, store[i]);
    $write("\n");
end

endmodule
