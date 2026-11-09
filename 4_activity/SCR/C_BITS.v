`timescale 1ns / 1ps

module C_BITS( //cuenta los bits recibidos 
    input        clk,
    input        rst,
    input        urrst,       // reset del receptor (PWREMU_MGMT)
    input        clr,         // desde la FSM: reinicia la cuenta (al entrar a DATA)
    input        bit_en,      // desde la FSM: un bit de datos fue recibido
    input  [1:0] wls,         // longitud de palabra
    input        pen,         // Dice si se tiene o no bit de paridad
    output reg   Done         // ya se recibieron todos los bits del caracter
    );

    wire [3:0] n_bits = {2'b00, wls} + 4'd5 + pen;   // 6 a 9 bits dato+paridad
    reg  [3:0] count;

    always @(posedge clk) begin
        if (rst || urrst || clr)       // logica de reinicio
            count <= 4'd0;
	    Done  <= 1'b0;
        else if (bit_en)               // aumenta cuando la FSM lo ordena
            count <= count + 4'd1;

        if (count == n_bits)           // si ya llegaron todos los bits, avisa
            Done <= 1'b1;
        else
            Done <= 1'b0;
    end

endmodule