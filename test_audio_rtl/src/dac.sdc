//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.11 Education
//Created Time: 2023-05-11 14:51:04
create_clock -name mclk -period 20.345 -waveform {0 10.172} [get_ports {iclk}]
create_clock -name pclk -period 37.037 -waveform {0 18.52} [get_ports {clk_27}]
