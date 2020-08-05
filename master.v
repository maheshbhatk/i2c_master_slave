`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: MAHESH BHAT K
// 
// Create Date: 08/02/2020 01:47:14 PM
// Design Name: 
// Module Name: i2c_master
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


module i2c_master(
    input clk,
    input rst,
    input enable,
    input read_write,   //0- read,1- write
    input [7:0]data_write,      //data to be write on slave
    output reg scl,
    inout sda,
    output reg [7:0]data        //data read from slave
    );
reg [7:0]data_in;
reg direction=1;  
reg SDA;
assign sda=direction?SDA:1'bZ;   
reg [3:0] state; 
reg [7:0] address;         // ADDRESS including read/write bit.
reg [7:0] count;
reg ack;
reg ack1;
reg received_bit;
parameter STATE_IDLE=0,
          STATE_START=1,
          STATE_ADD_RW=2,
          STATE_ACK=3,
          STATE_DATA_READ=4,
          STATE_DATA_WRITE=5,
          STATE_RACK=6,
          STATE_WACK=7,
          STATE_STOP=8;    
    
always@(negedge clk)
begin
    if(rst==1)  scl<=1;
    else begin
             if((state==STATE_IDLE)||(state==STATE_START))  
                     scl<=1;
            else    scl<=~scl;
         end 
end 

always@(posedge clk)
begin
    if(rst==1) begin
        state<=STATE_IDLE;
        direction<=1;
        SDA<=1;
        address<=8'b1010111X;  
        count<=8'd0;      
       end
    else begin
        case(state)
        
       STATE_IDLE:  begin                     //idle
                        direction<=1;
                        SDA<=1;
                        if(enable)
                            state<=STATE_START;
                            address[0]=read_write;
                     end  
       STATE_START: begin                       //start
                        SDA<=0;
                        count<=8;
                        state<=STATE_ADD_RW;
                    end
       STATE_ADD_RW: begin                       //address
                        if(scl==0) begin
                            SDA<=address[count-1];
                            if(count==0)  begin  state<=STATE_ACK; direction<=0;   end
                            else count<=count-1;
                            end
                        else state<=STATE_ADD_RW;
                     end
       STATE_ACK:    begin                       //acknowledge by slave
                        ack=sda;                 //ack<=sda for real time
                        if(ack==0) 
                                if(address[0]) begin  state<=STATE_DATA_WRITE; count<=8; direction<=1;SDA<=0;  end
                                else begin state<=STATE_DATA_READ; count<=8; direction<=0; end
                        else    begin  state<=STATE_IDLE;   end
                     end
       STATE_DATA_READ: begin                        //start to receive data by slave
                         if(scl==0) begin           //data is received only when scl is low
                          received_bit<=sda;
                          data_in[0]=received_bit;
                          data_in<=data_in<<1'b1;
                          count<=count-1'b1;
                          if(count==0) begin     state<=STATE_RACK;
                                                 direction<=1; SDA<=0;      //actual ack
                                                 data<=data_in;               
                                       end
                          else    begin    
                                            state<=STATE_DATA_READ;   end
                         end
                         else state<=STATE_DATA_READ;
                    end
       
       STATE_DATA_WRITE: begin
                             if(scl==0) begin
                                SDA<=data_write[count-1];
                                count<=count-1'b1;
                                if(count==0) begin state<=STATE_WACK;direction<=0;
                                                    end
                                else state<=STATE_DATA_WRITE;  end
                             else state<=STATE_DATA_WRITE;
                    end
       STATE_RACK:begin
                    if(scl==0) begin
                        SDA<=0;             //making the line zero so that SDA toggles next when scl is one for stop
                        state<=STATE_STOP;
                    end
                    else state<=STATE_RACK;
                  end                 
       STATE_WACK:begin
                    if(scl==0) begin
                        
                        ack1=sda;
                        if(ack1==0) begin state<=STATE_STOP; direction<=1;  end
                        else state<=STATE_IDLE;   end
                    else state<=STATE_WACK;                   
                  end
       STATE_STOP:begin
                        SDA<=1;
                        state<=STATE_IDLE;
                  end  
       default: begin state<=STATE_IDLE; end               
 endcase
 end
 end      
endmodule
