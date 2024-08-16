`timescale 1ns / 1ps

/*
IO set for test: 
task1. input all required value
task2. detect illegal input
task3. perform addition/ subtraction/ multiplication/ division
task4. detect overflow
task5. reg_display split to sign/integer/fraction part
task6. integer part convert bin 2 bcd
TODO1. fraction part convert bin 2 bcd
TODO2. assign sseg_abcd
*/

module calculator(input clk,
              input reset,
			  input key_pressed,
              input [24:0] keypad_out,
              //output reg signed [24:0] reg_arg_display,
              //output reg reg_sign_display,
              //output reg reg_decimal_display,
              //output reg reg_error_display

              output reg [18:0] bcd_int,
              output reg [2:0] num_digits_int
);


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
    state_divide_pressed = 4'd7,
	state_calculate = 4'd8,
	state_display_arg = 4'd9,
	state_display_result = 4'd10,
	state_display_error = 4'd11;


//calculator registers
reg [2:0] reg_digits_counter;  
reg [2:0] reg_decimal_place_counter;  

reg [1:0] reg_sign;  //OP_PLUS or OP_MINUS
reg reg_decimal;
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

/* verilator lint_off UNUSEDSIGNAL */
wire neg;
wire frac;
wire [14:0] bin_int;
wire [9:0] bin_frac;
/* verilator lint_on UNUSEDSIGNAL */

// component
split inst_split(
    .clk(clk),
    .bin(reg_display),
    .reg_neg(neg),
    .reg_frac(frac),
    .reg_bin_int(bin_int),
    .reg_bin_frac(bin_frac)
);

bin2bcd_int inst_bin2bcd_int(
    .bin(bin_int),
    .bcd(bcd_int),
    .int_digits(num_digits_int)
);


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
                    reg_display <= 0;
                    key_pressed_prev <=0;  

                    //reg_arg_display <= 0;
                    //reg_sign_display <= 1; // 1 for plus
                    //reg_decimal_display <= 0;
                    //reg_error_display <= 0;

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
                        else if(keypad_out == 25'hD) begin
						    state <= state_divide_pressed;
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
                        reg_error <= 1;
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
                        reg_result <= (reg_result * reg_arg) >>> FRACTION_BITS; 
                        /* verilator lint_on WIDTHEXPAND */
						state <= state_display_result;
					end 

                    // division
                    else if(reg_operator == OP_DIVIDE) begin
                        /* verilator lint_off WIDTHEXPAND */
                        reg_result <= (reg_result << FRACTION_BITS) / reg_arg;
                        /* verilator lint_on WIDTHEXPAND */
						state <= state_display_result;
					end 
					reg_operator <= reg_operator_next;
				end

            state_display_arg: 
				begin
                    reg_display <= reg_arg;
                    //  test whether reg_arg and reg_display get correct value
                    $display("reg_arg:");
                    $display(reg_arg / (1.0 * (1 << FRACTION_BITS)));
                    $display("reg_display:");
                    $display(reg_display / (1.0 * (1 << FRACTION_BITS)));
					state <= state_read;
				end

            state_display_result: 
				begin
                    // check overflow
                    if((reg_result - (9999 << FRACTION_BITS)) > 0 || (reg_result + (999 << FRACTION_BITS) < 0)) begin
                        reg_error <= 1;
                        state <= state_display_error;
                    end 
                    else begin
                        reg_display <= reg_result[24:0];
                        // check whether reg_arg and reg_display get correct result
                        $display("reg_result:");
                        $display(reg_result / (1.0 * (1 << FRACTION_BITS)));
                        $display("reg_display:");
                        $display(reg_display / (1.0 * (1 << FRACTION_BITS)));
					    state <= state_read;
                    end
                    // reset some registers
                    reg_digits_counter <= 0; 
                    reg_decimal_place_counter <= 3'd1;  //! 1
                    reg_arg <= 0;
                    reg_sign <= OP_PLUS;
                    reg_decimal <= 0;
				end

            state_display_error:
                begin
                    $display("error:");
                    $display(reg_error);
                    state <= state_clear;
                end

            default begin
            end
		endcase
	end
end
endmodule
