`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2025 05:25:10 PM
// Design Name: 
// Module Name: input_extractor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//from 8-bit input signal reg, extracts start, reset and readwrite signals
module input_extractor(
    input[7:0] input_signals,   // 8-bit input signal reg
    
    output reset_bit,           //extracted reset bit
    output readwrite_bit,       //extracted readwrite bit
    output start_bit            //extracted start bit
    );
    
    //combinational assignment of signals
    assign reset_bit     = input_signals[2];
    assign readwrite_bit = input_signals[1];
    assign start_bit     = input_signals[0];    
    
endmodule
