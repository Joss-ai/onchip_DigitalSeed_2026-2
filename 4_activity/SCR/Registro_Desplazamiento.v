`timescale 1ns / 1ps

module Registro_Desplazamiento( // RSR: guarda los bits y verifica paridad
    input        clk,
    input        rst,
    input        urrst,        // activo en 1 (el top ya la invierte)
    input        rxd_in,       // linea serial YA sincronizada
    input        sample,
    input        shift_en,
    input        clr,
    input  [1:0] wls,          // 00=5 bits de dato, 01=6, 10=7, 11=8
    input        pen,
    input        eps,          // 1: par, 0: impar
    input        sp,           // stick parity
    output [8:0] rx_dataP,     // bits recibidos alineados a la derecha (paridad arriba)
    output [7:0] rx_data,      // solo los bits de dato
    output       pe
    );

    reg [8:0] rsr;

    // n = wls + 5 + pen bits recibidos; alinear = 9 - n = 4 - wls - pen
    wire [2:0] shift = 3'd4 - {1'b0, wls} - {2'b00, pen};
    assign rx_dataP = rsr >> shift;

    // Mascara de los bits de dato: 5 a 8 bits bajos
    wire [7:0] mask = 8'hFF >> (2'd3 - wls);
    assign rx_data  = rx_dataP[7:0] & mask;

    // Paridad (el bit de paridad esta en la posicion wls + 5)
    wire par_bit = rx_dataP[{2'b00, wls} + 4'd5];
    wire par_xor = ^rx_data;
    wire par_exp = sp  ? ~eps :
                   eps ?  par_xor : ~par_xor;

    assign pe = pen & (par_bit != par_exp);

    always @(posedge clk) begin
        if (rst || urrst || clr)
            rsr <= 9'd0;
        else if (sample && shift_en)
            rsr <= {rxd_in, rsr[8:1]};
    end

endmodule