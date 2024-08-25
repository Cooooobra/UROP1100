`timescale 1ns / 1ps

module drive(
    input clk,      
    input rst_n,   
    input en,
    input [15:0] bcd,  
    input frac, 
    input [3:0] dp,  //decimal point position     
         
    output   reg  [3:0]     seg_sel,  //select which segment to display
    output   reg  [7:0]     seg_led   //the current display segment
);


// /******对50Mhz时钟进行：计数-译码，得到5Mhz的分频时钟dri_clk******/
// reg    [3:0]             clk_cnt  ; 
// reg                       dri_clk  ;        
// always @(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//        clk_cnt <= 4'd0;
//    end
//    else if(clk_cnt == 3'd4) begin
//        clk_cnt <= 4'd0;
//    end
//    else begin
//        clk_cnt <= clk_cnt + 1'b1;
//    end
// end

// always @(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//        dri_clk <= 1'b1;
//    end
//    else if(clk_cnt == 3'd4) begin
//        dri_clk <= ~dri_clk;
//    end
//    else begin
//        dri_clk <= dri_clk;
//    end
// end


/******计数5 clk cycle，输出一个flag******/
reg    [12:0]  cnt0;
reg            flag; 
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt0 <= 13'b0;
        flag <= 1'b0;
    end
    else if (cnt0 < 13'd5 - 1'b1) begin
        cnt0 <= cnt0 + 1'b1;
        flag <= 1'b0;
    end
    else begin
        cnt0 <= 13'b0;
        flag <= 1'b1;
    end
end


/******动态数码管显示核心部分******/
/*根据计数器，快速动态轮流切换数码管，那么总有一个数码管可以被称为"当前数码管"*/
reg    [1:0] cnt_sel  ; // 0 1 2 3
reg    [3:0] num_disp ; // 当前数码管显示的数据是什么
reg          dtdpe;     // dtdpe = Does the decimal point exist，当前数码管存在小数点吗       
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_sel <= 2'b0;
    else if(flag) begin
        if(cnt_sel < 2'd3)
            cnt_sel <= cnt_sel + 1'b1;
        else
            cnt_sel <= 2'b0;
    end
    else
        cnt_sel <= cnt_sel;
end


always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        seg_sel  <= 4'b1111;              //位选信号低电平有效
        num_disp <= 4'b0;           
        dtdpe <= 1'b1;                   //共阳极数码管，低电平导通
    end
    else begin
        if(en) begin
            case (cnt_sel)
                2'd0 :begin
                    seg_sel  <= 4'b1110;      //当前数码管是哪个数码管
                    num_disp <= bcd[3:0];      //当前数码管显示什么值
                    dtdpe <= ~(dp[0] && frac);           //当前数码管是否有小数点
                end
                2'd1 :begin
                    seg_sel  <= 4'b1101;  
                    num_disp <= bcd[7:4];
                    dtdpe <= ~(dp[1] && frac);
                end
                2'd2 :begin
                    seg_sel  <= 4'b1011;  
                    num_disp <= bcd[11:8];
                    dtdpe <= ~(dp[2] && frac);
                end
                2'd3 :begin
                    seg_sel  <= 4'b0111;  
                    num_disp <= bcd[15:12];
                    dtdpe <= ~(dp[3] && frac);
                end
                default :begin
                    seg_sel  <= 4'b1111;
                    num_disp <= 4'b0;
                    dtdpe <= 1'b1;
                end
            endcase
        end
        else begin
            seg_sel  <= 4'b1111; //使能信号为0时，所有数码管disable
            num_disp <= 4'b0;
            dtdpe <= 1'b1;
        end
    end
end


/******译码：将数字、符号、小数点，翻译成数码管专用段选信号******/
always @ (posedge clk or negedge rst_n) begin
    if (!rst_n)
        seg_led <= 8'b1100_0000; //0
    else begin
        case (num_disp)
            4'd0 : seg_led <= {dtdpe,7'b1000000}; //0
            4'd1 : seg_led <= {dtdpe,7'b1111001}; //1
            4'd2 : seg_led <= {dtdpe,7'b0100100}; //2
            4'd3 : seg_led <= {dtdpe,7'b0110000}; //3
            4'd4 : seg_led <= {dtdpe,7'b0011001}; //4
            4'd5 : seg_led <= {dtdpe,7'b0010010}; //5
            4'd6 : seg_led <= {dtdpe,7'b0000010}; //6
            4'd7 : seg_led <= {dtdpe,7'b1111000}; //7
            4'd8 : seg_led <= {dtdpe,7'b0000000}; //8
            4'd9 : seg_led <= {dtdpe,7'b0010000}; //9
            4'd10: seg_led <= 8'b11111111;        //disable
            4'd11: seg_led <= 8'b10111111;        //minus sign
            default: 
                   seg_led <= {dtdpe,7'b1000000};
        endcase
    end
end


endmodule
