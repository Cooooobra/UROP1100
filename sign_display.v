`timescale 1ns / 1ps

module sign_display(
    input clk,
    input rst_n,
    input signed [24:0] num,
    input [1:0] sign,  //OP_PLUS or OP_MINUS

    output reg [24:0] abs_num,
    output reg neg
);

 
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        abs_num <= 25'b0;
        neg <= 1'b0;
    end
    else if(sign == 2'd1 && num == 25'b0) begin  //only input the OP_MINUS
        abs_num <= num;
        neg <= 1'b1;
    end
    else if (num[24] == 1) begin  //MSB is 1, indicating a negative number
        abs_num <= ~num + 1;  //Convert to additive inverse
        neg <= 1'b1;
    end
    else if (num[24] == 0) begin
        abs_num <= num; 
        neg <= 1'b0;
    end
end

endmodule
