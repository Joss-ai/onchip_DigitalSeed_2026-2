`timescale 1ns / 1ps

module MUX(
input [7:0] A,
input [7:0] B,
input sel,
output [7:0] C
    );
    
    assign C = sel ? A : B;
    
endmodule
