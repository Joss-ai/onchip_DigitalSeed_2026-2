`timescale 1ns / 1ps

module Contador(
    input E,
    input rst,
    input clk,
    output [4:0] puntero
);
    
    wire [4:0] in;
    wire [4:0] out;  
    
    assign in = out + 1'b1;
    
    FFD FF_contador (
        .D(in),
        .Q(out),
        .E(E),
        .rst(rst),
        .clk(clk)
    );
    
    assign puntero = out;  

endmodule

