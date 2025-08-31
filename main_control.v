`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/29/2025 04:49:23 PM
// Design Name: 
// Module Name: main_control
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


module main_control(
    input clk,                  //FPGA reference clk (100 MHz)
    input[7:0] device_address,  //(for write protocol) device address to access
    input[7:0] word_address,    //(for write protocol) word address/offset to access
    input[7:0] data_write,      //(for write protocol) data to write
    input[7:0] in_signals,      //input signals (xxxxx[reset][R/W][start])
    
    output reg[7:0] out_signals,    //output signals (xxxxx[bus busy][error][done])
    output wire[7:0] data_read,     //byte of data read from read protocol
    
    inout sda_wire,             //actual sda wire (external pull-up)
    inout scl_wire,              //actual scl wire (external pull-up)
    
    output reg[2:0] main_state,  //debugging purpose
    output reg[3:0] read_state,  //debugging purpose
    output reg[2:0] write_state,  //debugging purpose
    
    output wire sda_read_debug,    //debugging purpose
    output wire scl_read_debug
    );
    
    //--------- main control FSM states ---------//
    parameter[2:0] IDLE          = 3'd0;
    parameter[2:0] READ_OR_WRITE = 3'd1;
    parameter[2:0] RANDOM_READ   = 3'd2;
    parameter[2:0] BYTE_WRITE    = 3'd3;
    parameter[2:0] DONE          = 3'd4;
    parameter[2:0] ERROR         = 3'd5;
    //--------- main control FSM states ---------//
    
    //--------- RANDOM_READ FSM states ---------//
    parameter[3:0] R_IDLE            = 4'd0;
    parameter[3:0] R_DUMMY_START     = 4'd1;
    parameter[3:0] R_DEVICE_ADDRESSW = 4'd2;
    parameter[3:0] R_WORD_ADDRESS    = 4'd3;
    parameter[3:0] R_START           = 4'd4;
    parameter[3:0] R_DEVICE_ADDRESSR = 4'd5;
    parameter[3:0] R_BYTE_RECEIVE    = 4'd6;
    parameter[3:0] R_STOP            = 4'd7;
    parameter[3:0] R_DONE            = 4'd8;
    parameter[3:0] R_ERROR           = 4'd9;
    //--------- RANDOM_READ FSM states ---------//
      
    //--------- BYTE_WRITE FSM states ---------//
    parameter[2:0] W_IDLE            = 3'd0;
    parameter[2:0] W_START           = 3'd1;
    parameter[2:0] W_DEVICE_ADDRESS  = 3'd2;
    parameter[2:0] W_WORD_ADDRESS    = 3'd3;
    parameter[2:0] W_BYTE_SEND       = 3'd4;
    parameter[2:0] W_STOP            = 3'd5;
    parameter[2:0] W_DONE            = 3'd6;
    parameter[2:0] W_ERROR           = 3'd7;    
    //--------- BYTE_WRITE FSM states ---------//
    
    //--------- FSM regs ---------//
    reg[2:0] current_state, next_state;
    reg[3:0] R_current_state, R_next_state;
    reg[3:0] W_current_state, W_next_state;
    wire[6:0] device_address7 = {device_address[7:4], device_address[2:0]};
    reg[7:0] tx_byte_reg;                   //internal register for byte transmission
    reg[7:0] tx_byte_next;                 //combinational next value for tx_byte_reg
    reg[2:0] enable_connect;
    reg[2:0] enable_connect_next;
    //--------- FSM regs ---------//
    
    //--------- extracted input signals ---------//
    wire reset;
    wire read_write;
    wire start;
    reg start_sync;
    wire start_pulse = start & !start_sync;
    //--------- extracted input signals ---------//
    
    //--------- submodule control flags ---------//
    reg start_flag;        
    reg stop_flag;
    reg sendbyte_flag;
    reg receivebyte_flag;
    
    reg start_flag_ff;        
    reg stop_flag_ff;
    reg sendbyte_flag_ff;
    reg receivebyte_flag_ff;    
    //--------- submodule control flags ---------//
    
    //--------- I2C tri-state buffer connections ---------//
    wire scl_read;
    wire sda_read;
    reg scl_en;
    reg sda_en;
    assign sda_read_debug = sda_read;       //debugging purpose
    assign scl_read_debug = scl_read;       //debugging purpose
    //--------- I2C tri-state buffer connections ---------//
    
    //--------- submodule I2C line enable ---------// 
    wire scl_en_start;
    wire sda_en_start;
    wire scl_en_stop;
    wire sda_en_stop;
    wire scl_en_sendbyte;
    wire sda_en_sendbyte;
    wire scl_en_receivebyte;
    wire sda_en_receivebyte;    
    //--------- submodule I2C line enable ---------//
    
     
    //--------- submodule completed flags ---------//
    wire start_complete;
    wire stop_complete;
    wire sendbyte_complete;
    wire receivebyte_complete;
    //--------- submodule completed flags ---------//
    
    //--------- submodule error flags ---------//
    wire sendbyte_error;
    wire receivebyte_error;
    //--------- submodule error flags ---------//
   
    
    
    input_extractor in_extract(       //extract reset, read_write, and start signals from input
        .input_signals(in_signals),
        .reset_bit(reset),
        .readwrite_bit(read_write),
        .start_bit(start)
    ); 
    
    protocol_start start_submod(        //protocol start generation submodule
        .clk(clk),
        .start_flag(start_flag_ff),      //input => flip-flop-controlled start flag
        .reset(reset),
        .scl_en(scl_en_start),
        .sda_en(sda_en_start),
        .complete(start_complete)
    );
    
    protocol_stop stop_submod(         //protocol stop generation submodule
        .clk(clk),
        .stop_flag(stop_flag_ff),        //input => flip-flop-controlled start flag
        .reset(reset),
        .scl_en(scl_en_stop),
        .sda_en(sda_en_stop),
        .complete(stop_complete)
    );
    
    protocol_sendbyte sendbyte_submod(      //bytesend protocol submodule
        .clk(clk),
        .sendbyte_flag(sendbyte_flag_ff),   //input => ff-controlled start flag
        .data(tx_byte_reg),
        .reset(reset),
        .sda_read(sda_read),
        .scl_en(scl_en_sendbyte),
        .sda_en(sda_en_sendbyte),
        .complete(sendbyte_complete),
        .error(sendbyte_error)
    );
    
    protocol_receivebyte receivebyte_submod(    //bytereceive protocol submodule
        .clk(clk),
        .receivebyte_flag(receivebyte_flag_ff), //input => ff-controlled start flag
        .read_write(read_write),
        .reset(reset),
        .sda_read(sda_read),
        .scl_en(scl_en_receivebyte),
        .data_read(data_read),
        .complete(receivebyte_complete),
        .error(receivebyte_error)   
    );
    
    IOBUF scl_buf(     //tri-state, open-drain buffer for SCL wire
        .I(1'b0),
        .O(scl_read),
        .T(scl_en),
        .IO(scl_wire)
    );
    
    IOBUF sda_buf(     //tri-state, open-drain buffer for SDA wire
        .I(1'b0),
        .O(sda_read),
        .T(sda_en),
        .IO(sda_wire)
    );    

     // Combinational logic for next states and control flags
    always @(*) begin
        // Default assignments to prevent latch creation
        next_state = current_state;
        R_next_state = R_current_state;
        W_next_state = W_current_state;
        start_flag = 0;
        stop_flag = 0;
        sendbyte_flag = 0;
        receivebyte_flag = 0;
        
        // This calculates the next value for tx_byte_reg
        tx_byte_next = tx_byte_reg;
        
        // This calculates the next value for enable_connect
        enable_connect_next = enable_connect;
        
        // Main FSM
        case(current_state)
            IDLE: begin
                if(start_pulse) begin
                    next_state = READ_OR_WRITE;
                end
                else next_state = IDLE;
            end
            READ_OR_WRITE: begin
                if(read_write) begin          //if R/W is HIGH => read is active
                    next_state = RANDOM_READ;
                end
                else begin
                    next_state = BYTE_WRITE;  //if R/W is LOW => write is active
                end
            end
            RANDOM_READ: begin
                // Sub-FSM for Read Protocol
                case(R_current_state)
                    R_IDLE: begin
                        if(current_state == RANDOM_READ) begin
                            enable_connect_next = 3'd1;
                            R_next_state = R_DUMMY_START;
                        end
                        else R_next_state = R_IDLE;
                        next_state = RANDOM_READ;
                    end
                    R_DUMMY_START: begin
                        start_flag = 1;
                        R_next_state = R_DEVICE_ADDRESSW;
                        next_state = RANDOM_READ;
                    end
                    R_DEVICE_ADDRESSW: begin
                        if(start_complete) begin
                            enable_connect_next = 3'd3;
                            tx_byte_next  = {device_address7, 1'b0};
                            sendbyte_flag = 1;
                            R_next_state  = R_WORD_ADDRESS;
                        end
                        else R_next_state = R_DEVICE_ADDRESSW;
                        next_state = RANDOM_READ;
                    end
                    R_WORD_ADDRESS: begin
                        if(sendbyte_error) R_next_state = R_ERROR;
                        else if(sendbyte_complete) begin
                            tx_byte_next  = word_address;
                            sendbyte_flag = 1;
                            R_next_state  = R_START;
                        end
                        else R_next_state = R_WORD_ADDRESS;
                        next_state = RANDOM_READ;
                    end
                    R_START: begin
                        if(sendbyte_error) R_next_state = R_ERROR;
                        else if(sendbyte_complete) begin
                            start_flag = 1;
                            enable_connect_next = 3'd1;
                            R_next_state = R_DEVICE_ADDRESSR;
                        end
                        else R_next_state = R_START;
                        next_state = RANDOM_READ;
                    end
                    R_DEVICE_ADDRESSR: begin
                        if(sendbyte_error) R_next_state = R_ERROR;
                        else if(start_complete) begin
                            tx_byte_next = {device_address7, 1'b1};
                            sendbyte_flag = 1;
                            enable_connect_next = 3'd3;
                            R_next_state = R_BYTE_RECEIVE;
                        end
                        else R_next_state = R_DEVICE_ADDRESSR;
                        next_state = RANDOM_READ;
                    end
                    R_BYTE_RECEIVE: begin
                        if(sendbyte_error) R_next_state = R_ERROR;
                        else if(sendbyte_complete) begin
                            receivebyte_flag = 1;
                            enable_connect_next = 3'd4;
                            R_next_state = R_STOP;
                        end
                        else R_next_state = R_BYTE_RECEIVE;
                        next_state = RANDOM_READ;
                    end
                    R_STOP: begin
                        if(receivebyte_error) R_next_state = R_ERROR;
                        else if(receivebyte_complete) begin
                            stop_flag = 1;
                            enable_connect_next = 3'd2;
                            R_next_state = R_DONE;
                        end
                        else R_next_state = R_STOP;
                        next_state = RANDOM_READ;
                    end
                    R_DONE: begin
                        if(stop_complete) begin
                            enable_connect_next = 3'd0;
                            R_next_state = R_IDLE;
                            next_state = DONE;
                        end
                        else R_next_state = R_DONE;
                    end
                    R_ERROR: begin
                        enable_connect_next = 3'd0;
                        R_next_state = R_IDLE;
                        next_state = ERROR;
                    end
                    default: begin
                        R_next_state = R_IDLE;
                        next_state = RANDOM_READ;
                    end
                endcase
            end
            BYTE_WRITE: begin
                // Sub-FSM for Write Protocol
                case(W_current_state)
                    W_IDLE: begin
                        if(current_state == BYTE_WRITE) begin
                            enable_connect_next = 3'd1;
                            W_next_state = W_START;
                        end
                        else W_next_state = W_IDLE;
                        next_state = BYTE_WRITE;
                    end
                    W_START: begin
                        start_flag = 1;
                        W_next_state = W_DEVICE_ADDRESS;
                        next_state = BYTE_WRITE;
                    end
                    W_DEVICE_ADDRESS: begin
                        if(start_complete) begin
                            tx_byte_next  = {device_address7, 1'b0};
                            sendbyte_flag = 1;
                            enable_connect_next = 3'd3;
                            W_next_state = W_WORD_ADDRESS;
                        end
                        else W_next_state = W_DEVICE_ADDRESS;
                        next_state = BYTE_WRITE;
                    end
                    W_WORD_ADDRESS: begin
                        if(sendbyte_error) W_next_state = W_ERROR;
                        else if(sendbyte_complete) begin
                            tx_byte_next = word_address;
                            sendbyte_flag = 1;
                            W_next_state = W_BYTE_SEND;
                        end
                        else W_next_state = W_WORD_ADDRESS;
                        next_state = BYTE_WRITE;
                    end
                    W_BYTE_SEND: begin
                        if(sendbyte_error) W_next_state = W_ERROR;
                        else if(sendbyte_complete) begin
                            tx_byte_next = data_write;
                            sendbyte_flag = 1;
                            W_next_state = W_STOP;
                        end
                        else W_next_state = W_BYTE_SEND;
                        next_state = BYTE_WRITE;
                    end
                    W_STOP: begin
                        if(sendbyte_error) W_next_state = W_ERROR;
                        else if(sendbyte_complete) begin
                            W_next_state = W_DONE;
                            stop_flag = 1;
                            enable_connect_next = 3'd2;
                        end
                        else W_next_state = W_STOP;
                        next_state = BYTE_WRITE;
                    end
                    W_DONE: begin
                        if(stop_complete) begin
                            enable_connect_next = 3'd0;
                            W_next_state = W_IDLE;
                            next_state = DONE;
                        end
                        else W_next_state = W_DONE;
                    end
                    W_ERROR: begin
                        enable_connect_next = 3'd0;
                        W_next_state = W_IDLE;
                        next_state = ERROR;
                    end
                    default: begin
                        W_next_state = W_IDLE;
                        next_state = BYTE_WRITE;
                    end
                endcase
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
    
    // Synchronous logic to update all registers
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            current_state <= IDLE;
            R_current_state <= R_IDLE;
            W_current_state <= W_IDLE;
            
            tx_byte_reg         <= 8'd0;
            enable_connect      <= 3'd0;
            start_sync          <= 1'b0;
            
            start_flag_ff       <= 0;
            stop_flag_ff        <= 0;
            sendbyte_flag_ff    <= 0;
            receivebyte_flag_ff <= 0;
            
            out_signals         <= 8'd0;
            main_state          <= 3'd0;
            read_state          <= 4'd0;
            write_state         <= 3'd0;
            
            // Set default tristate buffer enables
            scl_en <= 1'b1;
            sda_en <= 1'b1;
        end
        else begin
            // Update FSM states
            current_state   <= next_state;
            R_current_state <= R_next_state;
            W_current_state <= W_next_state;
        
            // Update debug outputs
            main_state <= current_state;
            read_state <= R_current_state;
            write_state <= W_current_state;

            // Update flags for submodules
            start_flag_ff       <= start_flag;
            stop_flag_ff        <= stop_flag;
            sendbyte_flag_ff    <= sendbyte_flag;
            receivebyte_flag_ff <= receivebyte_flag;
            start_sync          <= start;
            
            // Latch the calculated next value into the tx_byte register
            tx_byte_reg <= tx_byte_next;
            
            // Latch the MUX selector
            enable_connect <= enable_connect_next;
            
            // MUX for tristate buffer enables (now synchronous)
            case(enable_connect)
                3'd0: begin
                    scl_en <= 1'b1;
                    sda_en <= 1'b1;
                end
                3'd1: begin
                    scl_en <= scl_en_start;
                    sda_en <= sda_en_start;
                end
                3'd2: begin
                    scl_en <= scl_en_stop;
                    sda_en <= sda_en_stop;
                end
                3'd3: begin
                    scl_en <= scl_en_sendbyte;
                    sda_en <= sda_en_sendbyte;
                end
                3'd4: begin
                    scl_en <= scl_en_receivebyte;
                    sda_en <= 1'b1; // sda is always an input during receive
                end
                default: begin
                    scl_en <= 1'b1;
                    sda_en <= 1'b1;           
                end
            endcase
            
            // Update top-level outputs
            if(current_state == IDLE && !sda_read) begin
                out_signals[2] <= 1'b1;
            end
            else if(next_state == READ_OR_WRITE) begin
                out_signals <= 8'd0;
            end
            else if (next_state == DONE) begin
                out_signals[0] <= 1'b1;
            end 
            else if (next_state == ERROR) begin
                out_signals[1] <= 1'b1;
            end 
            else begin
                out_signals <= out_signals;
            end
        end
    end
    
endmodule
