module i2c_slave1(    );
reg clk,rst,enable,read_write;
reg [7:0]data_write;
wire scl;
wire sda;
//reg SDA;
//wire direction=1;
//assign sda=direction?SDA:1'bZ;
wire [7:0]data;
wire [7:0]data_received;
reg scl_in;
//tri1 sda_in;
i2c_master master2(clk,rst,enable,read_write,data_write,scl,sda,data);
i2c_slave slave2(clk,rst,enable,sda,scl_in,data_received);

initial
clk=0;
always #2 clk=~clk;

initial
begin
rst=1;
enable=1;
read_write=1;
data_write=8'b10110011;
#10 rst=0;
#350 data_write=8'b10111100;
#590 $finish;
end
always@(*)
scl_in<=scl;
endmodule
