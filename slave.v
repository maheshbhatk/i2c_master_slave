`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mahesh Bhat K 
// 
// Create Date: 08/02/2020 02:38:36 PM
// Design Name: 
// Module Name: i2c_slave
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


module i2c_slave(
    input clk,
    input rst,
    input enable,
    inout sda,
    input scl,
    output reg [7:0] data_received
    );
reg direction;
reg SDA;
assign sda=direction?SDA:1'bz;
reg [7:0]add_in;
reg [3:0] state; 
reg [7:0] address=8'b1010111X;         // slave address
reg [7:0] count;
reg ack;
reg received_bit;
reg [7:0] read_value=8'b11110101;
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
    if(rst==1) begin
        state<=STATE_IDLE;
        count<=8'd0; 
             
       end
    else 
        case(state)
        
       STATE_IDLE:  begin                     //idle
                        direction<=0;
                        if(enable)
                            state<=STATE_START;
                    end         
       STATE_START: begin                       //start
                        if(sda==0) begin
                            count<=8;
                            state<=STATE_ADD_RW;  end  
                        else state<=STATE_START;
                    end
       STATE_ADD_RW: begin
                     if(scl==0) begin
                        add_in[count-1]<=sda;
                        count<=count-1'b1;
                        if(count==0) begin  state<=STATE_ACK; count<=0;SDA=0; direction<=1; end
                        else state<=STATE_ADD_RW;
                        end
                     else state<=STATE_ADD_RW;
                     end
       STATE_ACK: begin if(add_in[7:1]==address[7:1])
                          begin  SDA=0; direction<=1; 
                               //if(count==1)
                                if(add_in[0]==0)  begin state<=STATE_DATA_READ; direction<=1; count<=8'd7;SDA<=read_value[7]; end  //master read means send data to master
                                else begin state<=STATE_DATA_WRITE; direction<=0; count<=8'd8; end
                               //else count<=count+1;
                          end
                         else begin SDA<=1; state<=STATE_IDLE; end      
                  end 
       STATE_DATA_READ: begin       
                        if(scl==0) begin
                            SDA<=read_value[count-1];
                            count<=count-1'b1;
                            if(count==0) begin state<=STATE_RACK; direction<=0; end
                            else state<=STATE_DATA_READ;
                            end
                        else state<=STATE_DATA_READ;
                        end
       STATE_DATA_WRITE: begin
                        if(scl==0) begin
                        data_received[count-1]<=sda;
                        count<=count-1'b1;
                        if(count==0) begin state<=STATE_WACK;direction<=1;SDA=0; end
                        else state<=STATE_DATA_WRITE;
                        end
                        else state<=STATE_DATA_WRITE;
                        end
       STATE_RACK: begin
                    if(scl==0) begin
                    ack=sda;
                    if(ack==0)  begin state<=STATE_STOP; end
                    else state<=STATE_IDLE;
                    end
                    else state<=STATE_RACK;
                    end
       STATE_WACK: begin
                    SDA<=0;
                    direction<=1;
                    state<=STATE_STOP;
                   end
       STATE_STOP: begin
                    //if(scl==0)
                        ack=sda;
                        state<=STATE_IDLE;
                   end       
       default: begin state<=STATE_IDLE; end
endcase
endmodule
