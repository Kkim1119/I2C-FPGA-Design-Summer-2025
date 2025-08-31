/******************************************************************************
* Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <xil_assert.h>
#include "platform.h"
#include "xil_printf.h"
#include "xgpio.h"
#include "xparameters.h"
#include "sleep.h"


int main()
{
    init_platform();

    print("============== START ==============\n\r");

    XGpio input1, input2;
    XGpio output1, output2, output3, output4;

    int device_addr_in;     //given by firmware / output1
    int word_addr_in;       //given by firmware / output2
    int data_write_in;      //given by firmware / output3
    int status_input_reg;   //given by firmware / output4
    int data_read_out;      //received by firmware / input1
    int status_output_reg;  //received by firmware / input2
    int *mailbox_0;
    int *mailbox_1;
    int mailbox_buf;
    int counter_addr, counter_data, validation_counter;
    int nop0=0, nop1=1;
    int i;
    int j;
    int timeout_counter=100;

    mailbox_0 = (int *) 0xFFD80034;     //mailbox for user debug command 
    mailbox_1 = (int *) 0xFFD8003C;     //mailbox for data

    XGpio_Initialize(&output1, XPAR_AXI_GPIO_0_BASEADDR);
    XGpio_Initialize(&output2, XPAR_AXI_GPIO_1_BASEADDR);
    XGpio_Initialize(&output3, XPAR_AXI_GPIO_2_BASEADDR);
    XGpio_Initialize(&output4, XPAR_AXI_GPIO_3_BASEADDR);
    XGpio_Initialize(&input1, XPAR_AXI_GPIO_4_BASEADDR);
    XGpio_Initialize(&input2, XPAR_AXI_GPIO_5_BASEADDR);

    XGpio_SetDataDirection(&input1, 1, 1);
    XGpio_SetDataDirection(&input2, 1, 1);
    XGpio_SetDataDirection(&output1, 1, 0);
    XGpio_SetDataDirection(&output1, 1, 0);
    XGpio_SetDataDirection(&output2, 1, 0);
    XGpio_SetDataDirection(&output3, 1, 0);
    XGpio_SetDataDirection(&output4, 1, 0);

    //XGpio_DiscreteWrite(&output1, 1, 0xA0);
    //XGpio_DiscreteWrite(&output4, 1, 0x01);

    device_addr_in = XGpio_DiscreteRead(&output1, 1);
    word_addr_in = XGpio_DiscreteRead(&output2, 1);
    data_write_in = XGpio_DiscreteRead(&output3, 1);
    status_input_reg = XGpio_DiscreteRead(&output4, 1);
    data_read_out = XGpio_DiscreteRead(&input1, 1);
    status_output_reg = XGpio_DiscreteRead(&input2, 1);

    printf("device_addr_in = %x\n\r", device_addr_in);
    printf("word_addr_in = %x\n\r", word_addr_in);
    printf("data_write_in = %x\n\r", data_write_in);
    printf("status_input_reg = %x\n\r", status_input_reg);
    printf("data_read_out = %x\n\r", data_read_out);
    printf("status_output_reg = %x\n\r", status_output_reg);
    

    while(1){
        mailbox_buf = *mailbox_0;
        if(mailbox_buf != 0x00) {   
            switch(mailbox_buf)      //read mailbox value -> if not 0, case is given
            {   
                case 0x01:                                                                 //change device address
                    XGpio_DiscreteWrite(&output1, 1, *mailbox_1);   //update device address to user input in mailbox_1
                    device_addr_in = XGpio_DiscreteRead(&output1, 1);
                    printf("DEBUG: device_addr_in = %x\n\r", device_addr_in);
                    break;
                
                case 0x02:                                                                 //change word address
                    XGpio_DiscreteWrite(&output2, 1, *mailbox_1);   //update word address to user input in mailbox_1
                    word_addr_in = XGpio_DiscreteRead(&output2, 1);
                    printf("DEBUG: word_addr_in = %x\n\r", word_addr_in);
                    break;

                case 0x03:                                                                 //change write data
                    XGpio_DiscreteWrite(&output3, 1, *mailbox_1);   //update write data to user input in mailbox_1
                    data_write_in = XGpio_DiscreteRead(&output3, 1);
                    printf("DEBUG: data_write_in = %x\n\r", data_write_in);
                    break;       

                case 0x04:                                                                 //change status input bits
                    XGpio_DiscreteWrite(&output4, 1, *mailbox_1);   //update status input bits to user input in mailbox_1
                    status_input_reg = XGpio_DiscreteRead(&output4, 1);
                    printf("DEBUG: status_input_reg = %x\n\r", status_input_reg);
                    break;     
                ///////////////////////// validation code for i2c_ip ver. 1/////////////////////////                     
                case 0x05:     
                
                        validation_counter = *mailbox_1;                      
                        XGpio_DiscreteWrite(&output4, 1, 0x80); // reset ip
                        XGpio_DiscreteWrite(&output4, 1, 0x00);
                        XGpio_DiscreteWrite(&output1, 1, 0xA0); // set device address

                        for (i=0; i<validation_counter; i++)     
                        {                   
                            for (counter_addr=0; counter_addr<256; counter_addr++)
                            {                                                       

                                XGpio_DiscreteWrite(&output2, 1, counter_addr); // set word address
                                for (counter_data=0; counter_data<256; counter_data++)
                                {          
                                    usleep(10000); // tBUF spec 4.7us
                                    
                                    while (XGpio_DiscreteRead(&input2, 1) & 0x08) {nop0 = nop1;}// bus busy                  

                                    XGpio_DiscreteWrite(&output3, 1, counter_data); // set data                                    
                                    XGpio_DiscreteWrite(&output4, 1, 0x00); // clear done bit
                                    XGpio_DiscreteWrite(&output4, 1, 0x04);
                                    while (XGpio_DiscreteRead(&input2, 1) & 0x02) { nop0 = nop1; }// check if done bit == 0 

                                    XGpio_DiscreteWrite(&output4, 1, 0x00); // start write
                                    XGpio_DiscreteWrite(&output4, 1, 0x01);
                                    while (!(XGpio_DiscreteRead(&input2, 1) & 0x02)) { nop0 = nop1; }// check if done bit == 1

                                    usleep(10000); // tBUF spec 4.7us

                                    XGpio_DiscreteWrite(&output4, 1, 0x00); // clear done bit
                                    XGpio_DiscreteWrite(&output4, 1, 0x04);                                   
                                    while (XGpio_DiscreteRead(&input2, 1) & 0x02) { nop0 = nop1; }// check done bit == 0 

                                    XGpio_DiscreteWrite(&output4, 1, 0x00); // start read
                                    XGpio_DiscreteWrite(&output4, 1, 0x02);                                    
                                    while (!(XGpio_DiscreteRead(&input2, 1) & 0x02)) { nop0 = nop1; }// check if done bit == 1 

                                    if (XGpio_DiscreteRead(&input2, 1) & 0x01) // if ack error == 1
                                    {
                                        printf("Ack Error!! 0x%02X:0x%02X-0x%02X, control_reg:0x%02X\r\n", counter_addr, counter_data, data_read_out, XGpio_DiscreteRead(&input2, 1));
                                    }
                                    else
                                    {                                  
                                        data_read_out = XGpio_DiscreteRead(&input1, 1); // read data

                                        if (data_read_out == counter_data)  // verification
                                        {
                                            printf("matched-0x%02X:0x%02X-0x%02X, control_reg:0x%02X\r\n", counter_addr, counter_data, data_read_out, XGpio_DiscreteRead(&input2, 1));
                                        }
                                        else {
                                            printf("mismatched-0x%02X:0x%02X-0x%02X,  control_reg:0x%02X\r\n", counter_addr, counter_data,  data_read_out, XGpio_DiscreteRead(&input2, 1));
                                        }
                                    }
                                }        

                            }    
                        }                        
                    break;
                    ///////////////////////////////////////////////////////////////////////////////// 

                ///////////////////////// validation code for i2c_ip ver. 2 /////////////////////////                     
                case 0x06:     
                
                        validation_counter = *mailbox_1;         
                        XGpio_DiscreteWrite(&output4, 1, 0x00);            
                        XGpio_DiscreteWrite(&output4, 1, 0x04); // reset ip
                        XGpio_DiscreteWrite(&output4, 1, 0x00);
                        XGpio_DiscreteWrite(&output1, 1, 0xA0); // set device address

                        for (i=0; i<validation_counter; i++)     
                        {                   
                            for (counter_addr=0; counter_addr<256; counter_addr++)
                            {                                                       

                                XGpio_DiscreteWrite(&output2, 1, counter_addr); // set word address
                                for (counter_data=0; counter_data<256; counter_data++)
                                {          
                                    usleep(10000); // tBUF spec 4.7us

                                    //while (XGpio_DiscreteRead(&input2, 1) & 0x04) {nop0 = nop1;}// bus busy                                     
                                    for (j=0; j<timeout_counter; j++){
                                        if(!(XGpio_DiscreteRead(&input2, 1) & 0x04)) {
                                            break;
                                        }     
                                        usleep(10);                                   
                                    }               
                                    if(j==timeout_counter){     //if timeout, break out of entire for loop nest
                                        printf("Timeout Error!! Bus Busy\r\n"); 
                                        counter_addr = 256;
                                        i = validation_counter;
                                        break;                                        
                                    }    

                                    XGpio_DiscreteWrite(&output3, 1, counter_data); // set data                                    

                                    XGpio_DiscreteWrite(&output4, 1, 0x00);
                                    XGpio_DiscreteWrite(&output4, 1, 0x01); // start write

                                    //while (!(XGpio_DiscreteRead(&input2, 1) & 0x01)) { nop0 = nop1; }// check if done bit == 1
                                    for (j=0; j<timeout_counter; j++){
                                        if((XGpio_DiscreteRead(&input2, 1) & 0x01)) {
                                            break;
                                        }     
                                        usleep(10);                                   
                                    }               
                                    if(j==timeout_counter){     //if timeout, break out of entire for loop nest
                                        printf("Timeout Error!! ACK error\r\n"); 
                                        counter_addr = 256;
                                        i = validation_counter;
                                        break;                                        
                                    }                                        

                                    usleep(10000); // tBUF spec 4.7us

                                    //while (XGpio_DiscreteRead(&input2, 1) & 0x04) {nop0 = nop1;}// bus busy 
                                    for (j=0; j<timeout_counter; j++){
                                        if(!(XGpio_DiscreteRead(&input2, 1) & 0x04)) {
                                            break;
                                        }     
                                        usleep(10);                                   
                                    }               
                                    if(j==timeout_counter){     //if timeout, break out of entire for loop nest
                                        printf("Timeout Error!! Bus Busy\r\n"); 
                                        counter_addr = 256;
                                        i = validation_counter;
                                        break;                                        
                                    }   

                                    XGpio_DiscreteWrite(&output4, 1, 0x00); 
                                    XGpio_DiscreteWrite(&output4, 1, 0x03); // start read    

                                    //while (!(XGpio_DiscreteRead(&input2, 1) & 0x01)) { nop0 = nop1; }// check if done bit == 1 
                                    for (j=0; j<timeout_counter; j++){
                                        if((XGpio_DiscreteRead(&input2, 1) & 0x01)) {
                                            break;
                                        }     
                                        usleep(10);                                   
                                    }               
                                    if(j==timeout_counter){     //if timeout, break out of entire for loop nest
                                        printf("Timeout Error!! ACK error\r\n"); 
                                        counter_addr = 256;
                                        i = validation_counter;
                                        break;                                        
                                    }  

                                    if (XGpio_DiscreteRead(&input2, 1) & 0x02) // if ack error == 1
                                    {
                                        printf("Ack Error!! 0x%02X:0x%02X-0x%02X, control_reg:0x%02X\r\n", counter_addr, counter_data, data_read_out, XGpio_DiscreteRead(&input2, 1));
                                    }
                                    else
                                    {                                  
                                        data_read_out = XGpio_DiscreteRead(&input1, 1); // read data

                                        if (data_read_out == counter_data)  // verification
                                        {
                                            printf("matched-0x%02X:0x%02X-0x%02X, control_reg:0x%02X\r\n", counter_addr, counter_data, data_read_out, XGpio_DiscreteRead(&input2, 1));
                                        }
                                        else {
                                            printf("mismatched-0x%02X:0x%02X-0x%02X,  control_reg:0x%02X\r\n", counter_addr, counter_data,  data_read_out, XGpio_DiscreteRead(&input2, 1));
                                        }
                                    }
                                }        

                            }    
                        }                        
                    break;
                    /////////////////////////////////////////////////////////////////////////////////     

            }

            data_read_out = XGpio_DiscreteRead(&input1, 1);
            status_output_reg = XGpio_DiscreteRead(&input2, 1);       

            printf("DEBUG: data_read_out = %x\n\r", data_read_out);
            printf("DEBUG: status_output_reg = %x\n\r", status_output_reg);  

            *mailbox_0 = 0x00;           
        }
    }

    cleanup_platform();
    return 0;
}
