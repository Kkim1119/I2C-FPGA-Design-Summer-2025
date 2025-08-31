`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/29/2025 11:10:02 PM
// Design Name: 
// Module Name: protocol_sendbyte
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


module protocol_sendbyte(
    input clk,              //FPGA reference clk (100MHz)             
    input sendbyte_flag,    //start flag toggled only once I2C lines confirmed to be released
    input[7:0] data,        //byte data to send to target peripheral
    input reset,            //connected to user reset (asynchronous, active high)
    input sda_read,         //value read off of sda line (for ACK confirmation)
    output reg scl_en,      //0 -> enable(drive); 1 -> disable (release)
    output reg sda_en,      //0 -> enable(drive); 1 -> disable (release)
    output reg complete,    //complete flag inidicating send byte protocol finished
    output reg error       //error flag indicating ACK/NACK not received
    //output reg[3:0] state   //for debugging purpose
    );
    
    parameter[9:0] CLK_CYCLES    = 500;     //500 ref cycles = 1/2 I2C SCL clk cycle
    parameter[3:0] IDLE          = 4'd0;    //State when sendbyte module not in use
    parameter[3:0] COUNTER_RESET = 4'd1;    //intermittent state to reset counters used in SCL CLK creation
    parameter[3:0] SETUP         = 4'd2;    //State to drive SCL low & load SDA with bit for posedge later
    parameter[3:0] POSEDGE       = 4'd3;    //State to drive SCL high to send SDA data on posedge
    parameter[3:0] COMPLETE_CLK  = 4'd4;    //state that allows full clk cycle to complete before next bit
    parameter[3:0] ACK           = 4'd5;    //deciphers ACK received & determines success or error
    parameter[3:0] ACK_FIN       = 4'd6;    //makes sure SCL clk goes low for a little bit to validate correct ACK 
    parameter[3:0] DONE          = 4'd7;    //done with transmission
    parameter[3:0] ERROR         = 4'd8;    //error, NACK received
    
    reg[9:0] clk_counter;   //counts each FPGA ref clk posedge (for I2C CLK creation)
    reg[3:0] bit_counter;   //counts # of bits transmitted
    
    reg[3:0] current_state, next_state;
    
    // Combinational logic to determine next_state
    always @(*) begin
        //state = current_state;  //debugging line
        case (current_state)
            IDLE: begin
                if(sendbyte_flag) begin 
                    next_state = SETUP;
                end
                else next_state = IDLE;
            end
            COUNTER_RESET: begin
                next_state = SETUP;
            end
            SETUP: begin
                if(clk_counter == CLK_CYCLES) next_state = POSEDGE;
                else next_state = SETUP;
            end
            POSEDGE: begin
                next_state = COMPLETE_CLK;
            end
            COMPLETE_CLK: begin
                if(clk_counter == CLK_CYCLES*2) begin
                    if(bit_counter == 9) next_state = ACK;
                    else next_state = COUNTER_RESET;
                end
                else next_state = COMPLETE_CLK;
            end
            ACK: begin
                if(!sda_read) begin
                    next_state = ACK_FIN;
                end
                else next_state = ERROR;
            end
            ACK_FIN: begin
                if(clk_counter == (CLK_CYCLES/2)) begin
                    next_state = DONE;
                end
                else next_state = ACK_FIN;
            end
            DONE: begin
                next_state = IDLE;
            end
            ERROR: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    
    // Sequential logic to update state, counters, and outputs
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            clk_counter   <= 10'd0;
            bit_counter   <= 4'd0;
            current_state <= IDLE;
            scl_en <= 1'b1;
            sda_en <= 1'b1;
            complete <= 1'b0;
            error <= 1'b0;
        end
        else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    clk_counter <= 10'd0;
                    bit_counter <= 4'd0;
                    scl_en <= 1'b0;
                    sda_en <= 1'b1;
                    complete <= 1'b0;
                    error <= 1'b0;
                end
                COUNTER_RESET: begin
                    clk_counter <= 10'd0;
                    // Outputs remain the same as the previous state (SDA low, SCL low)
                end
                SETUP: begin
                    clk_counter <= clk_counter + 1;
                    scl_en <= 1'b0;
                    if(bit_counter == 8) sda_en <= 1'b1;
                    else sda_en <= data[7-bit_counter];
                    complete <= 1'b0;
                    error <= 1'b0;
                end
                POSEDGE: begin
                    bit_counter <= bit_counter + 1;
                    clk_counter <= clk_counter + 1;
                    scl_en <= 1'b1;
                    // sda_en value remains
                end
                COMPLETE_CLK: begin
                    clk_counter <= clk_counter + 1;
                    // scl_en and sda_en values remain
                end
                ACK: begin
                    bit_counter <= 4'd0;
                    clk_counter <= 10'd0;
                    scl_en <= (!sda_read) ? 1'b0 : 1'b1;
                    // sda_en value remains
                end
                ACK_FIN: begin
                    clk_counter <= clk_counter + 1;
                    // Outputs remain the same
                end
                DONE: begin
                    clk_counter <= 10'd0;
                    bit_counter <= 4'd0;
                    complete <= 1'b1;
                    error <= 1'b0;
                    scl_en <= 1'b0;
                    sda_en <= 1'b0;
                end
                ERROR: begin
                    clk_counter <= 10'd0;
                    bit_counter <= 4'd0;
                    complete <= 1'b0;
                    error <= 1'b1;
                    scl_en <= 1'b1;
                    sda_en <= 1'b1;
                end
                default: begin
                    clk_counter <= 10'd0;
                    bit_counter <= 4'd0;
                    scl_en <= 1'b1;
                    sda_en <= 1'b1;
                    complete <= 1'b0;
                    error <= 1'b0;
                end
            endcase
        end
    end
    
endmodule
