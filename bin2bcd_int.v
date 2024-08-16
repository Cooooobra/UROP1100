`timescale 1ns / 1ps

module bin2bcd_int #( 
    parameter Width = 15
)( 
    input [Width - 1 : 0] bin,   
    output reg [Width + (Width - 4) / 3: 0] bcd,
    output reg [2:0] int_digits
); 

integer i, j;

always @(*) begin
    // cout the number of integer part digits
    if(bin < 10) begin int_digits = 1; end
    else if(bin >= 10 && bin < 100) begin int_digits = 2; end
    else if(bin >= 100 && bin < 1000) begin int_digits = 3; end
    else begin int_digits = 4; end

    // initialize Widthith zeros
    for (i = 0; i <= Width + (Width - 4) / 3; i = i + 1)
        bcd[i] = 0;     
    bcd[Width - 1: 0] = bin;                                   // initialize Widthith input vector
    for (i = 0; i <= Width - 4; i = i + 1)                       // iterate on structure depth
        for (j = 0; j <= i / 3; j = j + 1)                     // iterate on structure Widthidth
            if (bcd[Width - i + 4 * j -: 4] > 4)                      // if > 4
                bcd[Width - i + 4 * j -: 4] = bcd[Width - i + 4 * j -: 4] + 4'd3; // add 3
end

endmodule
