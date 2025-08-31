`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/30/2025 03:20:31 AM
// Design Name: 
// Module Name: main_control_testbench
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


module main_control_testbench();

    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg[7:0] device_address;
    reg[7:0] word_address;
    reg[7:0] data_write;
    reg[7:0] in_signals;    //(xxxxx[reset][R/W][start])
    
    wire[7:0] out_signals;  //(xxxxxx[error][done])
    wire[7:0] data_read;
    
    wire[2:0] main_state;
    wire[3:0] read_state;
    wire[2:0] write_state;
    
    reg periph_scl_en;
    reg periph_sda_en;
    
    wire sda_wire;
    wire scl_wire;
    
    pullup (sda_wire);
    pullup (scl_wire);
    
    always #(CLK_PERIOD/2) clk = ~clk;
    
    //complete i2c module
    main_control i2c_mod(
        .clk(clk),
        .device_address(device_address),
        .word_address(word_address),
        .data_write(data_write),
        .in_signals(in_signals),
        .out_signals(out_signals),
        .data_read(data_read),
        .sda_wire(sda_wire),
        .scl_wire(scl_wire),
        
        .main_state(main_state),
        .read_state(read_state),
        .write_state(write_state)
    );
    
    IOBUF periph_scl_buf(      //tri-state, open-drain buffer for SCL wire
        .I(1'b0),
        .O(scl_read),
        .T(periph_scl_en),
        .IO(scl_wire)
    );
    
    IOBUF periph_sda_buf(      //tri-state, open-drain buffer for SDA wire
        .I(1'b0),
        .O(sda_read),
        .T(periph_sda_en),
        .IO(sda_wire)
    );  
    
    initial begin
        //initialize input values
        clk <= 0;
        device_address <= 8'h00;
        word_address <= 8'h00;
        data_write <= 8'h00;
        periph_scl_en <= 1'b1;
        periph_sda_en <= 1'b1;
        
        //reset module
        in_signals <= 8'h00;
        #(CLK_PERIOD * 2);
        in_signals <= 8'h04;
        #(CLK_PERIOD);
        in_signals <= 8'h00;
         
        //------------testing byte write------------------//
        
        device_address <= 8'hA0;
        word_address <= 8'h55;
        data_write <= 8'h22;
        #(CLK_PERIOD);
        in_signals <= 8'h01;
        #(CLK_PERIOD);
        //in_signals <= 8'h00;
        
        #(CLK_PERIOD * 9500);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 1250);
        periph_sda_en <= 1'b1;
        
        #(CLK_PERIOD * 7900);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 1250);
        periph_sda_en <= 1'b1;
        
         #(CLK_PERIOD * 8000);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 1250);
        periph_sda_en <= 1'b1;
 
        //catching protocol complete sign
        @(posedge out_signals[0]);
        #(CLK_PERIOD * 20000);
        
        in_signals <= 8'h00;
        #(CLK_PERIOD);
        in_signals <= 8'h01;
        #(CLK_PERIOD);
        //in_signals <= 8'h00;
        
        #(CLK_PERIOD * 9500);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 1250);
        periph_sda_en <= 1'b1;
        
        #(CLK_PERIOD * 7900);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 1250);
        periph_sda_en <= 1'b1;
        
         #(CLK_PERIOD * 8000);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 1250);
        periph_sda_en <= 1'b1;
        
        //------------testing byte write------------------//
        
        //------------testing random read-----------------//
        /*
        device_address <= 8'hA0;
        word_address <= 8'h55;
        #(CLK_PERIOD);
        in_signals <= 8'h03;
        #(CLK_PERIOD);
        in_signals <= 8'h02;
        
        #(CLK_PERIOD * 9500);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 1250);
        periph_sda_en <= 1'b1;        
        
        #(CLK_PERIOD * 7900);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 1250);
        periph_sda_en <= 1'b1;
        
        #(CLK_PERIOD * 9500);
        periph_sda_en <= 1'b0;
        #(CLK_PERIOD * 9500);
        periph_sda_en <= 1'b1;  
        
        //catching protocol complete sign
        @(posedge out_signals[0]);
        #(CLK_PERIOD * 1000);
        */
        //------------testing random read-----------------//
        
        $finish;
    end    
    
    


endmodule
