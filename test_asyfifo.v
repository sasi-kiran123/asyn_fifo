`timescale 1ns / 1ps

module test_asyfifo;
reg wr_clk,rd_clk,reset;
wire wr_full,rd_empty;
wire [7:0] data_out;

asy_fifo dut(data_out, wr_full, rd_empty,
rd_clk, wr_clk, reset);


initial 
begin
wr_clk=0;
rd_clk=0;
reset=1;

end


initial
#5 reset=0;

always
#25 wr_clk=~wr_clk;

always
#250 rd_clk=~rd_clk;

endmodule









