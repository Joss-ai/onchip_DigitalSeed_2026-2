`timescale 1ns / 1ps

module ANDGATE(
input [7:0] A,
input [7:0] B,
input [7:0] C,
input [7:0] D,
input [7:0] E,
input [7:0] F,
input [7:0] G,
input [7:0] H,
input [7:0] I,
input [7:0] J,
input [7:0] K,
input [7:0] L,
input [7:0] M,
input [7:0] N,
input [7:0] O,
input [7:0] P,
output Q
    );

assign Q = (A == 8'd0) &&
           (B == 8'd0) &&
           (C == 8'd0) &&
           (D == 8'd0) &&
           (E == 8'd0) &&
           (F == 8'd0) &&
           (G == 8'd0) &&
           (H == 8'd0) &&
           (I == 8'd0) &&
           (J == 8'd0) &&
           (K == 8'd0) &&
           (L == 8'd0) &&
           (M == 8'd0) &&
           (N == 8'd0) &&
           (O == 8'd0) &&
           (P == 8'd0);

endmodule