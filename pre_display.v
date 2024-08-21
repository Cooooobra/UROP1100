`timescale 1ns / 1ps

module pre_display(
    input clk,        
    input rst_n,
    input [24:0] data,   
    input neg,   
    input frac,
    input error,  //!

    output reg reg_neg,
    output reg reg_frac,
    output reg [3:0] dp_position,
    output reg [15:0] reg_num
);



/******split the input data into 7 digits******/
wire [3:0] data_thousands;  
wire [3:0] data_hundreds; 
wire [3:0] data_tens;  
wire [3:0] data_units;  
wire [3:0] data_tenths;
wire [3:0] data_hundredths;
wire [3:0] data_thousandths;
/* verilator lint_off WIDTHEXPAND */
/* verilator lint_off WIDTHTRUNC */
assign data_thousands = data / 20'd1000000;
assign data_hundreds = (data / 17'd100000) % 4'd10;
assign data_tens = (data / 14'd10000) % 4'd10;
assign data_units = (data / 10'd1000) % 4'd10;
assign data_tenths = (data / 7'd100) % 4'd10;
assign data_hundredths = (data / 4'd10) % 4'd10;
assign data_thousandths = data % 4'd10;
/* verilator lint_on WIDTHTRUNC */
/* verilator lint_on WIDTHEXPAND */


/******count the num of digits in integer portion (1 to 4)******/
wire  int_four;
wire  int_three;
wire  int_two;
wire  int_one;
assign int_four = data_thousands != 4'b0000;
assign int_three = (data_hundreds != 4'b0000) || int_four;
assign int_two = (data_tens != 4'b0000) || int_three;
assign int_one = 1'b1;  //at least 1 digit (0.x)


/******count the num of digits in fraction portion (0 to 3)******/
wire  frac_three;
wire  frac_two;
wire  frac_one;
assign frac_three = data_thousandths != 4'b0000;
assign frac_two = (data_hundredths != 4'b0000) || frac_three;
assign frac_one = (data_tenths != 4'b0000) || frac_two;




/******decide how many segment needed to display******/
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        reg_neg <= 1'b0;
        reg_frac <= 1'b0;
        dp_position <= 4'b0;
        reg_num <= 16'b0;
    end

    else if(error) begin  //display error
        reg_num <= 16'hBBBB;  //---- to represent error occured
    end

    else if(frac && !frac_one) begin  //decimal point during input stage
        reg_frac <= 1'b1;
        dp_position <= 4'b0001;
    end

    else if(neg) begin
        reg_neg <= 1'b1;
        reg_num[15:12] <= 4'd11; //11 for minus sign display
        if(frac_one == 1'b0) begin  //no fraction part, no decimal point
            reg_frac <= 1'b0;
            if(int_three) begin
                reg_num[11:0] <= {data_hundreds, data_tens, data_units};
            end
            else if(!int_three && int_two) begin  
                reg_num[7:0] <= {data_tens, data_units};   
                reg_num[11:8] <= 4'd10; //10 for close the segment                  
            end
            else if(!int_two && int_one) begin
                reg_num[3:0] <= data_units;  
                reg_num[11:4] <= {2{4'd10}};    
            end    
        end
        else if(frac_one == 1'b1) begin  //exist fraction part
            reg_frac <= 1'b1;
            if(int_three) begin
                reg_num[11:0] <= {data_hundreds, data_tens, data_units};
                dp_position <= 4'b0001;
            end
            else if(!int_three && int_two) begin  
                reg_num[11:4] <= {data_tens, data_units};
                reg_num[3:0] <= data_tenths;      
                dp_position <= 4'b0010;       
            end
            else if(!int_two && int_one) begin
                if(!frac_two && !frac_three) begin
                    reg_num[11:8] <= 4'd10;  
                    reg_num[7:4] <= data_units;     
                    reg_num[3:0] <= data_tenths; 
                    dp_position <= 4'b0010;
                end
                else begin
                    reg_num[11:8] <= data_units;       
                    reg_num[7:0] <= {data_tenths, data_hundredths}; 
                    dp_position <= 4'b0100;
                end
            end   
        end
    end

    else if(!neg) begin
        reg_neg <= 1'b0;
        if(frac_one == 1'b0) begin  //no fraction part, no decimal point
            reg_frac <= 1'b0;
            if(int_four) begin
                reg_num[15:0] <= {data_thousands, data_hundreds, data_tens, data_units};
            end
            else if(!int_four && int_three) begin  
                reg_num[11:0] <= {data_hundreds, data_tens, data_units};
                reg_num[15:12] <= 4'd10; 
            end
            else if(!int_three && int_two) begin  
                reg_num[7:0] <= {data_tens, data_units};   
                reg_num[15:8] <= {2{4'd10}};                   
            end
            else if(!int_two && int_one) begin
                reg_num[3:0] <= data_units;  
                reg_num[15:4] <= {3{4'd10}};                
            end    
        end
        else if(frac_one == 1'b1) begin  //exist fraction part
            reg_frac <= 1'b1;
            if(int_four) begin
                reg_num[15:0] <= {data_thousands, data_hundreds, data_tens, data_units};
                dp_position <= 4'b0001;
            end
            else if(!int_four && int_three) begin  
                reg_num[15:4] <= {data_hundreds, data_tens, data_units};
                reg_num[3:0] <= data_tenths;
                dp_position <= 4'b0010;
            end
            else if(!int_three && int_two) begin  
                if(!frac_two && !frac_three) begin
                    reg_num[15:12] <= 4'd10;
                    reg_num[11:4] <= {data_tens, data_units};      
                    reg_num[3:0] <= data_tenths; 
                    dp_position <= 4'b0010;
                end
                else begin
                    reg_num[15:8] <= {data_tens, data_units};       
                    reg_num[7:0] <= {data_tenths, data_hundredths}; 
                    dp_position <= 4'b0100;
                end               
            end
            else if(!int_two && int_one) begin
                if(!frac_two && !frac_three) begin
                    reg_num[15:8] <= {2{4'd10}};
                    reg_num[7:4] <= data_units;      
                    reg_num[3:0] <= data_tenths; 
                    dp_position <= 4'b0010;
                end
                else if(frac_two && !frac_three) begin
                    reg_num[15:12] <= 4'd10;
                    reg_num[11:8] <= data_units;       
                    reg_num[7:0] <= {data_tenths, data_hundredths}; 
                    dp_position <= 4'b0100;
                end    
                else if(frac_three) begin
                    reg_num[15:12] <= data_units;
                    reg_num[11:0] <= {data_tenths, data_hundredths, data_thousandths};
                    dp_position <= 4'b1000;
                end
            end   
        end
    end
end    

endmodule
