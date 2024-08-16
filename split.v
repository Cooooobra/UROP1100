`timescale 1ns / 1ps

module split(
input clk,
//input rst,
input signed [24:0] bin,

output reg reg_neg,
output reg reg_frac,
output reg [14:0] reg_bin_int,
output reg [9:0] reg_bin_frac
);

reg [24:0] reg_bin;

initial begin
    reg_neg = 1'b0;  //initial to be positive
    reg_frac = 1'b0;  //initial to be integer
    reg_bin = 25'b0;
    reg_bin_int = 15'b0;
    reg_bin_frac = 10'b0;
end


always @ (posedge clk) begin
   
        // stpe1: check input positive or negative
        // if negative then convert to additive inverse
        if(bin[24]) begin
            reg_neg <= 1'b1;
            reg_bin <= ~(bin) + 1;
        end
        else begin
            reg_bin <= bin;
        end

        // stpe2: check input integer or fraction
        if(|reg_bin[9:0]) begin
            reg_frac <= 1'b1;
            reg_bin_frac <= reg_bin[9:0];
        end
        reg_bin_int <= reg_bin[24:10];
    
end

endmodule
