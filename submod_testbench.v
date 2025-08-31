`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2025 08:29:53 PM
// Design Name: 
// Module Name: submod_testbench
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


module submod_testbench();

/*   //protocol_sendbyte: testbench code
    parameter CLK_PERIOD = 10;

    reg clk;
    reg bytesend_flag;
    reg[7:0] data;
    reg reset;
    reg sda_read;
    //wire sda_read;
    // wire scl_read;

    wire scl_en;
    wire sda_en;
    wire complete;
    wire error;
    
    wire sda_wire;
    wire scl_wire;
    
    pullup (sda_wire);
    pullup (scl_wire);
    
    always #(CLK_PERIOD/2) clk = ~clk;
    
    protocol_sendbyte send_inst(
        .clk(clk),
        .sendbyte_flag(bytesend_flag),
        .data(data),
        .reset(reset),
        .sda_read(sda_read),
        .scl_en(scl_en),
        .sda_en(sda_en),
        .complete(complete),
        .error(error)
    );
    

    //IOBUF scl_buf(      //tri-state, open-drain buffer for SCL wire
        //.I(1'b0),
        //.O(scl_read),
        //.T(scl_en),
        //.IO(scl_wire)
    //);
    
    //IOBUF sda_buf(      //tri-state, open-drain buffer for SDA wire
        //.I(1'b0),
        //.O(sda_read),
        //.T(sda_en),
        //.IO(sda_wire)
    //);  

    
     initial begin
        bytesend_flag <= 1'b0;
        clk <= 0;
        reset <= 1'b0;
        #(CLK_PERIOD * 2);
        reset <= 1'b1;
        #(CLK_PERIOD);
        reset <= 1'b0;
         
        //testing regular behavior after reset
        data <= 8'b10100000;
        #(CLK_PERIOD);
        bytesend_flag <= 1'b1;
        #(CLK_PERIOD);
        bytesend_flag <= 1'b0;
        
        #(CLK_PERIOD * 7500);
        @(negedge scl_en);
        
        sda_read <= 1'b0;
        
        
        //testing user reset behavior
        @(posedge complete);
        #(CLK_PERIOD * 250);
        
        $finish;
    end 
*/



/* //protocol_receivebyte: testbench code    
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg bytereceive_flag;
    reg read_write;
    reg reset;
    wire[3:0] state;
    wire[8:0] data;
    
    wire scl_en;
    wire[7:0] data_read;
    wire complete;
    wire error;
    
    always #(CLK_PERIOD/2) clk = ~clk;
    
    protocol_receivebyte receive_inst(
        .clk(clk),
        .receivebyte_flag(bytereceive_flag),
        .read_write(read_write),
        .reset(reset),
        .sda_read(1'b0),
        .scl_en(scl_en),
        .data_read(data_read),
        .complete(complete),
        .error(error)
    );

    initial begin
        bytereceive_flag <= 1'b0;
        clk <= 0;
        reset <= 1'b0;
        #(CLK_PERIOD * 2);
        reset <= 1'b1;
        #(CLK_PERIOD);
        reset <= 1'b0;
         
        //testing regular behavior after reset
        #(CLK_PERIOD);
        bytereceive_flag <= 1'b1;
        read_write <= 1'b0;
        #(CLK_PERIOD);
        bytereceive_flag <= 1'b0;
        
        //testing user reset behavior
        @(posedge complete);
        #(CLK_PERIOD * 250);
        
        $finish;
    end 
*/

/*//protocol_stop: testbench code
    parameter CLK_PERIOD = 10;  //for 100MHz FPGA reference clock (10ns period)
    
    reg clk;
    reg stop_flag;
    reg reset;
    
    wire scl_en;
    wire sda_en;
    wire complete;
    
    always #(CLK_PERIOD/2) clk = ~clk;
    
    protocol_stop stop_inst(
        .clk(clk),
        .stop_flag(stop_flag),
        .reset(reset),
        .scl_en(scl_en),
        .sda_en(sda_en),
        .complete(complete)
    );
    
    initial begin
        stop_flag <= 1'b0;
        reset <= 1'b0;
        clk <= 0;
        
        #(CLK_PERIOD);
        reset <= 1'b1;
        #(CLK_PERIOD * 2);
        reset <= 1'b0;

        //testing regular behavior after system reset
        #(CLK_PERIOD);
        stop_flag <= 1'b1;
        #(CLK_PERIOD);
        stop_flag <= 1'b0;
        
        //testing user reset behavior
        @(posedge complete);
        #(CLK_PERIOD * 250);
        reset <= 1'b1;
        #(CLK_PERIOD);
        reset <= 1'b0;
        #(CLK_PERIOD);
        stop_flag <= 1'b1;
        #(CLK_PERIOD);
        stop_flag <= 1'b0;
        
        //testing abrupt user reset behavior
        @(posedge scl_en);
        #(CLK_PERIOD * 250);
        reset <= 1'b1;
        #(CLK_PERIOD);
        reset <= 1'b0;
        #(CLK_PERIOD * 500);
        
        $finish;
    end
*/

 /*//protocol_start: testbench code
    parameter CLK_PERIOD = 10;  //for 100MHz FPGA reference clock (10ns period)
    
    reg clk;
    reg start_flag;
    reg reset;
    
    wire scl_en;
    wire sda_en;
    wire complete;
    
    always #(CLK_PERIOD/2) clk = ~clk;
    
    protocol_start start_inst(
        .clk(clk),
        .start_flag(start_flag),
        .reset(reset),
        .scl_en(scl_en),
        .sda_en(sda_en),
        .complete(complete)
    );

    initial begin
        start_flag <= 1'b0;
        reset <= 1'b0;
        clk <= 0;
        
        #(CLK_PERIOD);
        reset <= 1'b1;
        #(CLK_PERIOD * 2);
        reset <= 1'b0;
        
        //testing regular behavior after system reset
        #(CLK_PERIOD);
        start_flag <= 1'b1;
        #(CLK_PERIOD);
        start_flag <= 1'b0;
        
        //testing user reset behavior
        @(posedge complete);
        #(CLK_PERIOD * 250);
        reset <= 1'b1;
        #(CLK_PERIOD);
        reset <= 1'b0;
        #(CLK_PERIOD);
        start_flag <= 1'b1;
        #(CLK_PERIOD);
        start_flag <= 1'b0;
        
        //testing abrupt user reset behavior
        @(negedge sda_en);
        #(CLK_PERIOD * 250);
        reset <= 1'b1;
        #(CLK_PERIOD);
        reset <= 1'b0;
        #(CLK_PERIOD * 500);
        
        $finish;
    end
*/

/* address_creator: testbench code
    parameter CLK_PERIOD = 10;
    
    reg[7:0] device_addr;
    reg[6:0] device_addr7;
    
    always @(*) begin
        device_addr7 = {device_addr[7:4], device_addr[2:0]};
    end
    
    initial begin
        device_addr <= 8'd0;
        #(CLK_PERIOD * 5);
        device_addr <= 8'hA0;
        #(CLK_PERIOD * 5);
        device_addr <= 8'hA1;
        #(CLK_PERIOD * 5);
        device_addr <= 8'hA2;
        #(CLK_PERIOD * 5);
        device_addr <= 8'hA3;
        #(CLK_PERIOD * 5);
        $finish;
    end
*/

/* input_extractor: testbench code
    parameter CLK_PERIOD = 10;
    
    reg system_reset;
    reg[7:0] in_signal;
    wire reset_bit;
    wire readwrite_bit;
    wire start_bit;
    
    input_extractor extract_inst(
        .system_reset(system_reset),
        .input_signals(in_signal),
        .reset_bit(reset_bit),
        .readwrite_bit(readwrite_bit),
        .start_bit(start_bit)
    );
    
    initial begin
        system_reset <= 1'b0;
        #(CLK_PERIOD);
        system_reset <= 1'b1;
        #(CLK_PERIOD);
        system_reset <= 1'b0;
    end
    
    initial begin
        in_signal <= 8'd0;
       
        @(posedge system_reset);
        in_signal <= 8'h01;
        #(CLK_PERIOD * 10);
        in_signal <= 8'h04;
        #(CLK_PERIOD * 5);
        in_signal <= 8'h03;
        #(CLK_PERIOD * 3);
        in_signal <= 8'h04;
        #(CLK_PERIOD);
        in_signal <= 8'h00;
        #(CLK_PERIOD);
        in_signal <= 8'h01;
        #(CLK_PERIOD);
        $finish;
    end
*/
endmodule
