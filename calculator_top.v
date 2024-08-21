`timescale 1ns / 1ps

/*
IO set for test: 
task1. input all required value (change from shift to multiply 10^)
task2. detect illegal input
task3. perform addition/ subtraction/ multiplication/ division
task4. detect overflow
task5. display reg_display and error in bcd form
TODO1. input component add
TODO2. display drive component
TODO3. rst_n signal
*/

module calculator_top(
    input clk,
    input rst_n,
	input key_pressed,
    input [24:0] keypad_out,
              
    output reg neg_display,
    output reg dp_display,
    output reg [3:0] dp_position,
    output reg [15:0] num_bcd_display
);




//calculator state
reg [3:0] state; 
localparam [3:0] 
	state_clear = 4'd0,
	state_read = 4'd1,
	state_digit_pressed = 4'd2,
    state_minus_pressed = 4'd3,
    state_dp_pressed = 4'd4,
    state_plus_pressed = 4'd5,
    state_multiply_pressed = 4'd6,
    state_divide_pressed = 4'd7,
	state_calculate = 4'd8,
	state_display_arg = 4'd9,
	state_display_result = 4'd10;
	//state_display_error = 4'd11;


//calculator registers
reg [2:0] reg_digits_counter;  
reg [2:0] reg_decimal_place_counter;  

reg [1:0] reg_sign;  //OP_PLUS or OP_MINUS
reg reg_dp;
reg reg_error;

reg [1:0] reg_operator;
reg [1:0] reg_operator_next;

reg signed [24:0] reg_arg;
reg signed [34:0] reg_result;  // mul div
reg signed [24:0] reg_display;

reg key_pressed_prev;  // check new key come in


//operator
localparam [1:0]
	OP_PLUS = 2'd0,
	OP_MINUS = 2'd1,
	OP_MULTIPLY = 2'd2,
	OP_DIVIDE = 2'd3;




wire [24:0] data_display;
wire neg_sign;

// component
sign_display inst_sign_display(
    .clk(clk),
    .rst_n(rst_n),
    .num(reg_display),
    .sign(reg_sign),
    .abs_num(data_display),
    .neg(neg_sign)
);

pre_display inst_pre_display(
    .clk(clk),
    .rst_n(rst_n),
    .data(data_display),
    .neg(neg_sign),
    .frac(reg_dp),
    .error(reg_error),
    .reg_neg(neg_display),
    .reg_frac(dp_display),
    .dp_position(dp_position),
    .reg_num(num_bcd_display)
);




always @(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		state <= state_clear;
        reg_error <= 1'b0;
	end 
	else begin
		case(state)

			state_clear:
				begin
                    reg_digits_counter <= 0; 
                    reg_decimal_place_counter <= 3'd1;  //initial to be 1
                    reg_sign <= OP_PLUS;
                    reg_dp <= 0;
                    //reg_error <= 0;
                    reg_operator <= OP_PLUS;
                    reg_operator_next <= OP_PLUS;
					reg_arg <= 0;
                    reg_result <= 0;
                    reg_display <= 0;
                    key_pressed_prev <=0;  
					// clear -> read
					state <= state_read;
				end

			state_read:
				begin
                    // check if new key come in
                    if(key_pressed && !key_pressed_prev) begin
                        reg_error <= 1'b0;  //!
						if(keypad_out < 25'hA) begin
                            state <= state_digit_pressed;
                        end
                        else if(keypad_out == 25'hA) begin
						    state <= state_plus_pressed;
                        end
                        else if(keypad_out == 25'hB) begin
						     state <= state_minus_pressed;
                        end
                        else if(keypad_out == 25'hC) begin
						    state <= state_multiply_pressed;
                        end
                        else if(keypad_out == 25'hD) begin
						    state <= state_divide_pressed;
                        end
                        else if(keypad_out == 25'hF) begin
                            state <= state_dp_pressed;
                        end
                        else if(keypad_out == 25'hE) begin
                            state <= state_clear;
                        end
                    end
                    key_pressed_prev <= key_pressed;
				end

			state_digit_pressed:
				begin
                    if(reg_sign == OP_PLUS) begin  // positive input
                        if(reg_digits_counter < 4) begin  //legal input at most 4 digits
                            if(!reg_dp) begin  // integer part
                                reg_arg <= reg_arg * 10 + (keypad_out * (10 ** 3));  
                            end
                            else begin  // decimal part
                                reg_arg <= reg_arg + (keypad_out * (10 ** (3 - reg_decimal_place_counter)));
                                reg_decimal_place_counter <= reg_decimal_place_counter + 1;
                            end
                            reg_digits_counter <= reg_digits_counter + 1;
                            state <= state_display_arg;
                        end
                        else begin  //illegal input
                            reg_error <= 1;
                            //state <= state_display_error;
                            state <= state_clear;
                        end
                    end
                    else begin  // negative input
                        if(reg_digits_counter < 3) begin  //legal input at most 3 digits                        
                            if(!reg_dp) begin
                                reg_arg <= reg_arg * 10 + (~(keypad_out * (10 ** 3)) + 1);  
                            end
                            else begin
                                reg_decimal_place_counter <= reg_decimal_place_counter + 1;
                                reg_arg <= reg_arg + (~(keypad_out * (10 ** (3 - reg_decimal_place_counter))) + 1);
                            end
                            reg_digits_counter <= reg_digits_counter + 1;     
                            state <= state_display_arg;
                        end  
                        else begin
                            reg_error <= 1;
                            //state <= state_display_error;
                            state <= state_clear;
                        end
                    end
				end
            
            state_minus_pressed:
				begin
                    reg_sign <= OP_MINUS; 
					state <= state_display_arg;  //display minus sign
				end

            state_dp_pressed:
                begin
                    if(!reg_dp) begin
                        reg_dp <= 1;
                        state <= state_display_arg;
                    end
                    else begin  //illegal input - no more than 1 decimal point
                        reg_error <= 1;
                        //state <= state_display_error;
                        state <= state_clear;
                    end
                end

            state_plus_pressed:
                begin
                    reg_operator_next <= OP_PLUS;
			 		state <= state_calculate; 
                end

            state_multiply_pressed:
				begin
					reg_operator_next <= OP_MULTIPLY;
					state <= state_calculate;
				end

            state_divide_pressed:
				begin
					reg_operator_next <= OP_DIVIDE;
					state <= state_calculate;
				end
            
            state_calculate:
				begin
                    // addition
					if(reg_operator == OP_PLUS) begin
                        /* verilator lint_off WIDTHEXPAND */
                        reg_result <= reg_result + reg_arg;
                        /* verilator lint_on WIDTHEXPAND */
						state <= state_display_result;
                    end 
                    // multiplication
                    else if(reg_operator == OP_MULTIPLY) begin
                        /* verilator lint_off WIDTHEXPAND */
                        reg_result <= (reg_result * reg_arg) / (10 ** 3); 
                        /* verilator lint_on WIDTHEXPAND */
						state <= state_display_result;
					end 
                    // division
                    else if(reg_operator == OP_DIVIDE) begin
                        /* verilator lint_off WIDTHEXPAND */
                        reg_result <= (reg_result * (10 ** 3)) / reg_arg;
                        /* verilator lint_on WIDTHEXPAND */
						state <= state_display_result;
					end 
					reg_operator <= reg_operator_next;
				end

            state_display_arg: 
				begin
                    reg_display <= reg_arg;
					state <= state_read;
				end

            state_display_result: 
				begin
                    // check overflow
                    if((reg_result - (9999 * (10 ** 3))) > 0 || (reg_result + (999 * (10 ** 3)) < 0)) begin
                        reg_error <= 1;
                        //state <= state_display_error;
                        state <= state_clear;
                    end 
                    else begin
                        reg_display <= reg_result[24:0];
					    state <= state_read;
                    end
                    //reset some registers
                    reg_digits_counter <= 0; 
                    reg_decimal_place_counter <= 3'd1; 
                    reg_sign <= OP_PLUS;
                    reg_dp <= 0;
                    reg_arg <= 0;
				end

            // state_display_error:
            //     begin
            //         $display("error:");
            //         $display(reg_error);
            //         state <= state_clear;
            //     end

            default: begin
            end

		endcase
	end
end

endmodule
