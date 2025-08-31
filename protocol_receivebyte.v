`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2025 11:01:52 PM
// Design Name: 
// Module Name: protocol_receivebyte
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


module protocol_receivebyte(
    input clk,                  //FPGA reference clk (100MHz)
    input receivebyte_flag,     //start flag toggled only once I2C lines confirmed to be released
    input read_write,           //R/W bit to indicate whether NACK or ACK determines successful data reception
    input reset,                //connected to user reset (asynchronous, active high)
    input sda_read,             //value read off of sda line
    output reg scl_en,          //0 -> enable(drive); 1 -> disable (release)
    output reg[7:0] data_read,  //8-bit data received from peripheral
    output reg complete,        //complete flag indicating receive byte protocol finish
    output reg error           //error flag indicating ACK/NACK not received
    //output reg[3:0] state,       //for debugging purpose
    //output reg[8:0] data         //for debugging purpose
    );
        
    parameter[9:0] CLK_CYCLES    = 500;       //500 ref clk cycles = 1/2 I2C SCL clk cycle
    parameter[3:0] IDLE          = 4'd0;      //State when receivebyte module not in use
    parameter[3:0] COUNTER_RESET = 4'd1;      //intermittent state to reset counters used in SCL CLK creation
    parameter[3:0] SETUP         = 4'd2;      //State to drive SCL low to create posedge later
    parameter[3:0] POSEDGE       = 4'd3;      //State to drive SCL high so that peripheral sends data bit
    parameter[3:0] COLLECT       = 4'd4;      //State to store data bit into data_read (+ACK)
    parameter[3:0] COMPLETE_CLK  = 4'd5;      //State that allows full clk cycle to complete before next bit reception prep
    parameter[3:0] ACK           = 4'd6;      //deciphers ACK received & determines success or error
    parameter[3:0] ACK_FIN       = 4'd7;      //makes sure SCL clk goes low for a little bit to validate correct ACK 
    parameter[3:0] DONE          = 4'd8;      //done with reception, sends data received to main control
    parameter[3:0] ERROR         = 4'd9;      //error, incorrect ACK received
        
    reg[8:0] data;
    reg[9:0] clk_counter;       //counts each FPGA ref clk posedge (for I2C CLK creation)
    reg[3:0] bit_counter;       //counts # of bits received 
    
    reg[3:0] current_state, next_state;

    // Combinational logic for next state only
    always @(*) begin
        //state = current_state;  //debugging line
        
        case (current_state) 
            IDLE: begin 
                if(receivebyte_flag) begin
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
                next_state = COLLECT;
            end
            COLLECT: begin
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
                case ({read_write, data[0]})
                    2'b00: begin
                        next_state = ACK_FIN;        //write active, SDA LOW  = ACK
                    end
                    2'b01: begin
                        next_state = ERROR;      //write active, SDA HIGH = NACK
                    end
                    2'b10: begin
                        next_state = ERROR;      //read active, SDA LOW = NACK
                    end
                    2'b11: begin
                        next_state = ACK_FIN;        //read active, SDA HIGH = ACK
                    end
                    default: begin
                        next_state = ACK;            
                    end
                endcase 
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
    

    
    // Sequential logic to update state, outputs, and counters
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            clk_counter   <= 10'd0;
            bit_counter   <= 4'd0;
            current_state <= IDLE;
            scl_en <= 1'b1;
            data_read <= 8'd0;
            complete <= 1'b0;
            error <= 1'b0;
        end
        else begin
            current_state <= next_state;
            
            case (current_state) 
                IDLE: begin
                    clk_counter <= 10'd0;
                    bit_counter <= 4'd0;
                    complete <= 1'b0;
                    error <= 1'b0;
                    scl_en <= 1'b0;
                    data <= 9'h1FF;
                end
                COUNTER_RESET: begin
                    clk_counter <= 10'd0;
                    // Outputs remain from previous state
                end
                SETUP: begin
                    clk_counter <= clk_counter + 1;
                    scl_en <= 1'b0;
                end
                POSEDGE: begin
                    bit_counter <= bit_counter + 1;
                    clk_counter <= clk_counter + 1;
                    scl_en <= 1'b1;
                end
                COLLECT: begin
                    clk_counter <= clk_counter + 1;
                    data <= {data[7:0], sda_read};
                end
                COMPLETE_CLK: begin
                    clk_counter <= clk_counter + 1;
                    // Outputs remain from previous state
                end
                ACK: begin
                    bit_counter <= 4'd0;
                    clk_counter <= 10'd0;
                    scl_en <= 1'b0;
                    // data_read, complete, error handled in next states
                end
                ACK_FIN: begin
                    clk_counter <= clk_counter + 1;
                    // Outputs remain from previous state
                end
                DONE: begin
                    data_read <= data[8:1];
                    complete <= 1'b1;
                    scl_en <= 1'b1;
                    // error handled in a different state
                end
                ERROR: begin
                    scl_en <= 1'b1;
                    error <= 1'b1;
                    // data_read, complete handled in different states
                end
                default: begin
                    clk_counter <= 10'd0;
                    bit_counter <= 4'd0;
                    scl_en <= 1'b1;
                    data_read <= 8'd0;
                    complete <= 1'b0;
                    error <= 1'b0;
                end
            endcase
        end
    end
 
endmodule
