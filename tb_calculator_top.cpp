#include <iostream>
#include <stdlib.h>
#include <assert.h>
#include <verilated.h>
#include "Vcalculator_top.h"
#include "verilated_vcd_c.h"



vluint64_t sim_time = 0;

void dut_reset (Vcalculator_top *dut, vluint64_t &sim_time){
    dut->rst_n = 1;  //高电平常态
    if(sim_time >= 2 && sim_time < 5){
        dut->rst_n = 0;  //低电平复位信号
        dut->key_pressed = 0;
        dut->keypad_out = 0xFF;
    }
}

void dut_input (Vcalculator_top *dut, vluint64_t &sim_time, const int start, const int in){
    if(sim_time == start){
        dut->key_pressed = 0b1;
        dut->keypad_out = in;
    }
    if (sim_time == start + 2){
        dut->key_pressed = 0b0;
    }
}


int main(int argc, char** argv, char** env) {

    VerilatedContext* contextp = new VerilatedContext;
    contextp -> commandArgs(argc, argv); 
    Vcalculator_top* d = new Vcalculator_top{contextp};

    VerilatedVcdC* tfp = new VerilatedVcdC; 
    contextp->traceEverOn(true); 
    d->trace(tfp, 5);  
    tfp->open("waveform.vcd");

    while(sim_time >= 0  && sim_time <= 400) {
        d->clk = !d->clk;
        dut_reset(d, sim_time);

        dut_input(d, sim_time, 10, 8);
        dut_input(d, sim_time, 40, 4);
        dut_input(d, sim_time, 70, 0);  
        dut_input(d, sim_time, 100, 3);
        dut_input(d, sim_time, 130, 2);
        
        
        dut_input(d, sim_time, 160, 5);  
        dut_input(d, sim_time, 190, 0xF);
        dut_input(d, sim_time, 220, 9);

        dut_input(d, sim_time, 250, 0xA); 
         
        
        d->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    tfp->close();
    delete d;
    delete contextp;
    return 0;
}