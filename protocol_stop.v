`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2025 09:34:42 PM
// Design Name: 
// Module Name: protocol_stop
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

//100MHz -> 100kHz => divide reference clk by 1000 cycles (switch SCL every 500 cycles for symmetric SCL clk periods)
//setup time requirement -> at least 5us => half period of SCL clk cycle => 500 reference clk cycles
module protocol_stop(
    input clk,                  //FPGA reference clk (100MHz)
    input stop_flag,           //start flag toggled only once I2C lines confirmed to be released
    input reset,                //connected to user reset (asynchronous, active high)
    output reg scl_en,          //0 -> enable(drive); 1 -> disable (release)
    output reg sda_en,          //0 -> enable(drive); 1 -> disable (release)
    output reg complete         //complete flag indicating start protocol generation finish    
    );
    
    reg[2:0] current_state, next_state;
    
    parameter[2:0] IDLE           = 3'd0;    //submodule not currently in use
    parameter[2:0] DRIVE_SCL_LOW  = 3'd1;    //drive scl low to setup for stop signal
    parameter[2:0] DRIVE_SDA_LOW  = 3'd2;    //drive sda low & hold scl/sda low for 5 us
    parameter[2:0] DRIVE_SCL_HIGH = 3'd3;    //drive scl high while keeping sda low
    parameter[2:0] SCL_HOLD_HIGH  = 3'd4;    //guarantee sda low, scl high for 5 us
    parameter[2:0] DRIVE_SDA_HIGH = 3'd5;    //drive sda high while keeping scl high
    parameter[2:0] DONE           = 3'd6;    //send done signal to main control module   
    
    reg[9:0] hold_counter;

    // Combinational logic to determine next_state
    always @(*) begin
        case (current_state)
            IDLE: begin
                if(stop_flag) begin
                    next_state = DRIVE_SCL_LOW;
                end
                else next_state = IDLE;
            end
            DRIVE_SCL_LOW: begin
                next_state = DRIVE_SDA_LOW;
            end
            DRIVE_SDA_LOW: begin
                if(hold_counter == 10'd499) next_state = DRIVE_SCL_HIGH;
                else next_state = DRIVE_SDA_LOW;
            end
            DRIVE_SCL_HIGH: begin
                next_state = SCL_HOLD_HIGH;
            end
            SCL_HOLD_HIGH: begin
                if(hold_counter == 10'd499) next_state = DRIVE_SDA_HIGH;
                else next_state = SCL_HOLD_HIGH;                
            end
            DRIVE_SDA_HIGH: begin
                next_state = DONE;            
            end
            DONE: begin
                if(hold_counter == 10'd499) begin
                    next_state = IDLE;
                end
                else next_state = DONE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    // Sequential logic to update state, outputs, and counter
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            current_state <= IDLE;
            hold_counter <= 0;
            scl_en <= 1;
            sda_en <= 1;
            complete <= 0;
        end
        else begin
            current_state <= next_state;
            case (current_state)
                IDLE: begin
                    hold_counter <= 0;
                    scl_en <= 0;
                    sda_en <= 1;
                    complete <= 0;
                end
                DRIVE_SCL_LOW: begin
                    hold_counter <= 0;
                    scl_en <= 0;
                    sda_en <= 1;
                    complete <= 0;
                end
                DRIVE_SDA_LOW: begin
                    hold_counter <= hold_counter + 1;
                    scl_en <= 0;
                    sda_en <= 0;
                    complete <= 0;
                end
                DRIVE_SCL_HIGH: begin
                    hold_counter <= 0;
                    scl_en <= 1;
                    sda_en <= 0;
                    complete <= 0;
                end
                SCL_HOLD_HIGH: begin
                    hold_counter <= hold_counter + 1;
                    scl_en <= 1;
                    sda_en <= 0;
                    complete <= 0;
                end
                DRIVE_SDA_HIGH: begin
                    hold_counter <= 0;
                    scl_en <= 1;
                    sda_en <= 1;
                    complete <= 0;
                end
                DONE: begin
                    hold_counter <= hold_counter + 1;
                    scl_en <= 1;
                    sda_en <= 1;
                    complete <= (hold_counter == 10'd499);
                end
                default: begin
                    hold_counter <= 0;
                    scl_en <= 1;
                    sda_en <= 1;
                    complete <= 0;
                end
            endcase
        end
    end
  
endmodule
