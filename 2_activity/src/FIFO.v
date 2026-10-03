`timescale 1ns / 1ps

module FIFO(
inout vdd,
inout vss,
input clk,
input wr_en,
input [7:0] din,
input rstn,
input rd_en,
output full,
output empty,
output [7:0] dout
    );

wire [7:0] infif, out1, out2, out3, out4, out5, out6, out7, out8;
wire [7:0] out9, out10, out11, out12, out13, out14, out15, out16;

MUX MUXIN(.A(din), .B(8'd0), .sel(wr_en), .C(infif));

FFD FFD1(.D(infif), .clk(clk), .rstn(rstn), .Q(out1));
FFD FFD2(.D(out1),  .clk(clk), .rstn(rstn), .Q(out2));
FFD FFD3(.D(out2),  .clk(clk), .rstn(rstn), .Q(out3));
FFD FFD4(.D(out3),  .clk(clk), .rstn(rstn), .Q(out4));
FFD FFD5(.D(out4),  .clk(clk), .rstn(rstn), .Q(out5));
FFD FFD6(.D(out5),  .clk(clk), .rstn(rstn), .Q(out6));
FFD FFD7(.D(out6),  .clk(clk), .rstn(rstn), .Q(out7));
FFD FFD8(.D(out7),  .clk(clk), .rstn(rstn), .Q(out8));
FFD FFD9(.D(out8),  .clk(clk), .rstn(rstn), .Q(out9));
FFD FFD10(.D(out9), .clk(clk), .rstn(rstn), .Q(out10));
FFD FFD11(.D(out10), .clk(clk), .rstn(rstn), .Q(out11));
FFD FFD12(.D(out11), .clk(clk), .rstn(rstn), .Q(out12));
FFD FFD13(.D(out12), .clk(clk), .rstn(rstn), .Q(out13));
FFD FFD14(.D(out13), .clk(clk), .rstn(rstn), .Q(out14));
FFD FFD15(.D(out14), .clk(clk), .rstn(rstn), .Q(out15));
FFD FFD16(.D(out15), .clk(clk), .rstn(rstn), .Q(out16));

MUX MUXOUT(.A(out16), .B(8'd0), .sel(rd_en), .C(dout));

ANDGATE EMPTY(.A(out1), .B(out2), .C(out3), .D(out4), .E(out5), .F(out6), .G(out7), .H(out8),
               .I(out9), .J(out10), .K(out11), .L(out12), .M(out13), .N(out14), .O(out15), 
               .P(out16), .Q(empty));
               
modFull Full(.A(out1), .B(out2), .C(out3), .D(out4), .E(out5), .F(out6), .G(out7), .H(out8),
               .I(out9), .J(out10), .K(out11), .L(out12), .M(out13), .N(out14), .O(out15), 
               .P(out16), .Q(full));
               
endmodule

//Posibles optimizaciones, el primer FFD tenga el write enable y que este decida o no y asi nos
//ahorramos un MUX, el ultimo FFD tenga un read enable y asi nos ahorramos otro MUX
