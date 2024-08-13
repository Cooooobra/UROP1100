`timescale 1ns / 1ps

/*
task1. input positive/negative integer/decimal number
task2. detect illegal input
task3. perform addition/multiplication
TODO1. perform division
TODO2. check overflow and give reminder
*/

module calculator_top(input clk,
              input reset,
			  input key_pressed,
              input [24:0] keypad_out,
              output reg signed [49:0] reg_arg_display,
              output reg reg_sign_display,
              output reg reg_decimal_display,
              output reg reg_error_display);


parameter FRACTION_BITS = 10;

//calculator state
reg [3:0] state; 
localparam [3:0] 
	state_clear = 4'd0,
	state_read = 4'd1,
	state_digit_pressed = 4'd2,
    state_minus_pressed = 4'd3,
    state_decimal_pressed = 4'd4,
    state_plus_pressed = 4'd5,
    state_multiply_pressed = 4'd6,
    state_calculate = 4'd7,
	state_display_arg = 4'd8,
    state_display_result = 4'd9,
    state_display_error = 4'd10;


//calculator registers
reg [2:0] reg_digits_counter;  
reg [2:0] reg_decimal_place_counter;  //![2:0]

reg [1:0] reg_sign;  //OP_PLUS or OP_MINUS
reg reg_decimal;
reg reg_error;

reg [1:0] reg_operator;
reg [1:0] reg_operator_next;

reg signed [24:0] reg_arg;
reg signed [49:0] reg_result;  //? TODO

reg key_pressed_prev;  // check new key come in


//operator
localparam [1:0]
	OP_PLUS = 2'd0,
	OP_MINUS = 2'd1,
    OP_MULTIPLY = 2'd2;


always @(posedge clk or negedge reset)
begin
	if(reset) begin
		state <= state_clear;
	end 
	else begin
		case(state)

			state_clear:
				begin
                    reg_digits_counter <= 0; 
                    reg_decimal_place_counter <= 3'd1;  //! 1
                    reg_sign <= OP_PLUS;
                    reg_decimal <= 0;
                    reg_error <= 0;
                    reg_operator <= OP_PLUS;
                    reg_operator_next <= OP_PLUS;
					reg_arg <= 0;
                    reg_result <= 0;
                    key_pressed_prev <=0;  
                    reg_arg_display <= 0;
                    reg_sign_display <= 1; // 1 for plus
                    reg_decimal_display <= 0;
                    reg_error_display <= 0;
					// clear -> read
					state <= state_read;
				end

			state_read:
				begin
                    // check new key
                    if(key_pressed && !key_pressed_prev) begin
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
                        else if(keypad_out == 25'hF) begin
                            state <= state_decimal_pressed;
                        end
                        else if(keypad_out == 25'hE) begin
                            state <= state_clear;
                        end
                    end
                    key_pressed_prev <= key_pressed;
				end

			state_digit_pressed:
				begin
                    // positive input
                    if(reg_sign == OP_PLUS) begin
                        if(reg_digits_counter < 4) begin
                            // integer part
                            if(!reg_decimal) begin
                                reg_arg <= reg_arg * 10 + (keypad_out << FRACTION_BITS);  
                            end
                            // decimal part
                            else begin
                                reg_arg <= reg_arg + ((keypad_out << FRACTION_BITS) / 10**reg_decimal_place_counter);
                                reg_decimal_place_counter <= reg_decimal_place_counter + 1;
                            end
                            reg_digits_counter <= reg_digits_counter + 1;
                            state <= state_display_arg;
                        end
                        else begin
                            reg_error <= 1;
                            state <= state_display_error;
                        end
                    end
                    // negative input
                    else begin
                        if(reg_digits_counter < 3) begin
                            // integer part
                            if(!reg_decimal) begin
                                reg_arg <= reg_arg * 10 + (~(keypad_out << FRACTION_BITS) + 1);  
                            end
                            // decimal part
                            else begin
                                reg_decimal_place_counter <= reg_decimal_place_counter + 1;
                                reg_arg <= reg_arg + (~((keypad_out << FRACTION_BITS) / 10**reg_decimal_place_counter) + 1);
                            end
                            reg_digits_counter <= reg_digits_counter + 1;     
                            state <= state_display_arg;
                        end  
                        else begin
                            reg_error <= 1;
                            state <= state_display_error;
                        end
                    end
				end
            
            state_minus_pressed:
				begin
                    reg_sign <= OP_MINUS; //negative number
					state <= state_display_arg; 
				end

            state_decimal_pressed:
                begin
                    if(!reg_decimal) begin
                        reg_decimal <= 1;
                        state <= state_display_arg;
                    end
                    else begin
                        //illegal input - no more than 1 decimal point
                        state <= state_display_error;
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
            
            state_calculate:
				begin
					if(reg_operator == OP_PLUS) begin
						/* verilator lint_off WIDTHEXPAND */
                        reg_result <= reg_result + reg_arg;
                        /* verilator lint_on WIDTHEXPAND */
						state <= state_display_result;
                    end 
                    else if(reg_operator == OP_MULTIPLY) begin
                        /* verilator lint_off WIDTHEXPAND */
                        reg_result <= (reg_result * reg_arg) >>> FRACTION_BITS; //???
                        /* verilator lint_on WIDTHEXPAND */
						state <= state_display_result;
					end 
					reg_operator <= reg_operator_next;
				end

            state_display_arg: 
				begin
                    /* verilator lint_off WIDTHEXPAND */
                    reg_arg_display <= reg_arg;
                    /* verilator lint_on WIDTHEXPAND */
                    $display("reg_arg:");
                    $display(reg_arg / (1.0 * (1 << FRACTION_BITS)));
                    reg_sign_display <= (reg_sign == OP_PLUS) ? 1 : 0;
                    reg_decimal_display <= reg_decimal;
                    // input -> display
					state <= state_read;
				end

            state_display_result: 
				begin
					reg_arg_display <= reg_result;
                    $display("reg_result:");
                    $display(reg_result / (1.0 * (1 << FRACTION_BITS)));
                    //reg_sign_display <= (reg_sign == OP_PLUS) ? 1 : 0;
                    //reg_decimal_display <= reg_decimal;
                    // input -> display
					state <= state_read;
                    // ??
                    reg_arg <= 0;
                    reg_digits_counter <= 0; 
                    reg_decimal_place_counter <= 3'd1;  //! 1
                    reg_sign <= OP_PLUS;
                    reg_decimal <= 0;
                    reg_error <= 0;
				end

            state_display_error:
                begin
                    reg_error_display <= reg_error;
                    //$display(reg_error_display);
                    state <= state_clear;
                end

            default begin
            end
		endcase
	end
end
endmodule
