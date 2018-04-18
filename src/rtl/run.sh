#!/bin/bash
set -e

iverilog\
    nexys3.v seq_add.v seq_alu.v seq_rf.v seq.v uart_fifo.v uart_top.v uart.v\
    ../tb/*.v

vvp a.out
rm -v a.out
