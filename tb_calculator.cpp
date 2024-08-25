#include <iostream>
#include <stdlib.h>
#include <assert.h>
#include <verilated.h>
#include "Vcalculator.h"
#include "verilated_vcd_c.h"



vluint64_t sim_time = 0;

void dut_reset (Vcalculator *dut, vluint64_t &sim_time){
    if(sim_time >= 2 && sim_time < 5){
        dut->rst_n = 0;  //低电平复位信号
    }
}

void dut_input (Vcalculator *dut, vluint64_t &sim_time, const int start, const int hold, const int pos){
    if((sim_time >= start) && (sim_time <= (start+hold))){
        if(pos == 0){
            dut->IO_P4_ROW = 0b0001; //0001
        }
        else if(pos == 1){
            dut->IO_P4_ROW = 0b0010; //0010
        }
        else if(pos == 2){
            dut->IO_P4_ROW = 0b0100; //0100
        }
        else if(pos == 3){
            dut->IO_P4_ROW = 0b1000; //1000
        }
    }
}


int main(int argc, char** argv, char** env) {

    VerilatedContext* contextp = new VerilatedContext;
    contextp -> commandArgs(argc, argv); 
    Vcalculator* d = new Vcalculator{contextp};

    VerilatedVcdC* tfp = new VerilatedVcdC; 
    contextp->traceEverOn(true); 
    d->trace(tfp, 5);  
    tfp->open("waveform.vcd");

    while(sim_time >= 0  && sim_time <= 2000) {
        d->clk = !d->clk;
        d->rst_n = 1;  //高电平常态
        d->IO_P4_ROW = 0;  //no press
        dut_reset(d, sim_time);

        dut_input(d, sim_time, 90, 25, 0);
        dut_input(d, sim_time, 545, 125, 2); 
        dut_input(d, sim_time, 845, 125, 3); 
         
        
        d->eval();
        tfp->dump(sim_time);
        sim_time++;
    }

    tfp->close();
    delete d;
    delete contextp;
    return 0;
}