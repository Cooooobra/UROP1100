#include <iostream>
#include <stdlib.h>
#include <assert.h>
#include <verilated.h>
#include "Vcalculator_top.h"
#include "verilated_vcd_c.h"



vluint64_t sim_time = 0;

void dut_reset (Vcalculator_top *dut, vluint64_t &sim_time){
    dut->reset = 0;
    if(sim_time >= 2 && sim_time < 5){
        dut->reset = 1;
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

        dut_input(d, sim_time, 6, 0xb);
        dut_input(d, sim_time, 46, 4);

        dut_input(d, sim_time, 86, 0xd);  

        dut_input(d, sim_time, 126, 3);

        dut_input(d, sim_time, 166, 0xA);
        
        dut_input(d, sim_time, 206, 5);  
        dut_input(d, sim_time, 246, 0xF);
        dut_input(d, sim_time, 286, 9);

        dut_input(d, sim_time, 326, 0xA); 
        
        // dut_input(d, sim_time, 186, 0xA);
        // dut_input(d, sim_time, 206, 0);

        // dut_input(d, sim_time, 226, 0xc);
        // dut_input(d, sim_time, 246, 1);
        // dut_input(d, sim_time, 266, 0);

        //dut_input(d, sim_time, 286, 0xA);  
        
        d->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    tfp->close();
    delete d;
    delete contextp;
    return 0;
}