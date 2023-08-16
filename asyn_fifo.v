`timescale 1ns / 1ps

module top_fifo (
    input w_clk,w_en,w_rst,r_clk,r_en,r_rst,
    input [7:0] data_in,
    output [7:0] data_out,
    output full,empty
);

wire [3:0] b_wptr,g_wptr,b_rptr,g_rptr;

wire [3:0] g_rptr_sync,g_wptr_sync;

synchronizer rptr_sync(w_clk,w_rst,g_rptr,g_rptr_sync);
synchronizer wptr_sync(r_clk,r_rst,g_wptr,g_wptr_sync);
write_pointer_handler wph(w_clk,w_en,w_rst,g_rptr_sync,full,b_wptr,g_wptr);
read_pointer_handler rph(r_clk,r_en,r_rst,g_wptr_sync,empty,b_rptr,g_rptr);
fifo_mem mem(w_clk,r_clk,w_en,r_en,b_wptr,b_rptr,data_in,full,empty,data_out);
  
endmodule




module synchronizer (
    input clk,rst, 
    input [3:0] in,
    output reg [3:0] out
);
    reg [3:0] stage1;
    always @(posedge clk) begin
        if(rst)begin
            out <=4'b0;
            stage1 <= 4'b0; 
        end
        else begin
            stage1<=in;
            out<=stage1;
        end
    end
endmodule

module write_pointer_handler(
    input w_clk,w_en,w_rst,
    input [3:0] g_rptr_sync,
    output reg full,
    output reg [3:0] b_wptr,g_wptr
);

    wire [3:0] b_wptr_nxt,g_wptr_nxt;
    wire full_nxt;
    assign b_wptr_nxt = b_wptr+(w_en&!full);
    assign g_wptr_nxt=(b_wptr_nxt>>1)^b_wptr_nxt;
    wire [2:0] bin;
    assign bin[3] = g_rptr_sync[3];
    assign bin[2] = g_rptr_sync[3] ^ g_rptr_sync[2];
    assign bin[1] = g_rptr_sync[3] ^ g_rptr_sync[2] ^ g_rptr_sync[1];
    assign bin[0] = g_rptr_sync[3] ^ g_rptr_sync[2] ^ g_rptr_sync[1] ^ g_rptr_sync[0];
  
  
   assign full_nxt=(bin == {~b_wptr_nxt[3],b_wptr_nxt[2:0]});

    always @(posedge w_clk or posedge w_rst) begin
        if(w_rst) begin
            b_wptr<=4'b0;
            g_wptr<=4'b0;
        end
        else begin
            b_wptr<=b_wptr_nxt;
            g_wptr<=g_wptr_nxt;
        end
    end
    always @(posedge w_clk or negedge w_rst) begin
            if(w_rst) begin
                full<=1'b0;
        end
        else begin
            full<=full_nxt;
        end
    end 
endmodule


module read_pointer_handler(
    input r_clk,r_en,r_rst,
    input [3:0] g_wptr_sync,
    output reg empty,
    output reg [3:0] b_rptr,g_rptr
);

    wire [3:0] b_rptr_nxt,g_rptr_nxt;
    wire empty_nxt;
    assign b_rptr_nxt = b_rptr+(r_en&!empty);
    assign g_rptr_nxt=(b_rptr_nxt>>1)^b_rptr_nxt;
    
        wire [2:0] b_w_pr;
    assign b_w_pr[3] = g_wptr_sync[3];
    assign b_w_pr[2] = g_wptr_sync[3] ^ g_wptr_sync[2];
    assign b_w_pr[1] = g_wptr_sync[3] ^ g_wptr_sync[2] ^ g_wptr_sync[1];
    assign b_w_pr[0] = g_wptr_sync[3] ^ g_wptr_sync[2] ^ g_wptr_sync[1] ^ g_wptr_sync[0];
    
    
    
    assign empty_nxt=(g_rptr_nxt == b_w_pr);

    always @(posedge r_clk or posedge r_rst) begin
        if(r_rst) begin
            b_rptr<=4'b0;
            g_rptr<=4'b0;
        end
        else begin
            b_rptr<=b_rptr_nxt;
            g_rptr<=g_rptr_nxt;
        end
    end
    always @(posedge r_clk or posedge r_rst) begin
            if(r_rst) begin
                empty<=1'b1;
        end
        else begin
            empty<=empty_nxt;
        end
    end 
endmodule

module fifo_mem (
    input w_clk,r_clk,w_en,r_en,
    input [3:0] b_wptr,b_rptr,
    input [7:0] data_in,
    input full,empty,
    output reg [7:0] data_out  
);
reg [7:0]mem[7:0];

    always @(posedge w_clk) begin
        if(w_en&(!full))begin
            mem[b_wptr[2:0]]<=data_in;
        end
    end

    always @(posedge r_clk) begin
        if(r_en&(!empty))begin
            data_out<=mem[b_rptr[2:0]];
        end
    end 
endmodule





