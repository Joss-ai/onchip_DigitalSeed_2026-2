`timescale 1ns / 1ps

module FSM(
    input  wire clk,
    input  wire rst,
    input  wire urrst,      // activo en 1 (el top ya la invierte)
    input  wire rxd_in,     // linea serial YA sincronizada
    input  wire sample,     // pulso de muestreo desde C_TICKS
    input  wire Done,       // todos los bits de dato + paridad recibidos
    output reg  clr,
    output reg  shift_en,
    output reg  bit_en,
    output wire char_done,  // pulso: se muestreo el bit de stop
    output wire busy
);

    localparam S_INICIAL  = 3'd0;
    localparam S_REVISION = 3'd1;
    localparam S_ENTRADA  = 3'd2;
    localparam S_STOP     = 3'd3;
    localparam S_ESPERA   = 3'd4;   // espera a que la linea suba tras un fe

    reg [2:0] state, next_state;

    always @(posedge clk) begin
        if (rst || urrst) state <= S_INICIAL;
        else              state <= next_state;
    end

    always @(*) begin
        next_state = state;
        clr = 1'b0;  shift_en = 1'b0;  bit_en = 1'b0;

        case (state)
            S_INICIAL: begin
                clr = 1'b1;
                if (!rxd_in) next_state = S_REVISION;
            end

            S_REVISION:                       // valida el start en el sample
                if (sample) next_state = rxd_in ? S_INICIAL : S_ENTRADA;

            S_ENTRADA: begin
                shift_en = 1'b1;
                bit_en   = sample;            // cuenta solo en el pulso de muestreo
                if (Done) next_state = S_STOP;
            end

            S_STOP:                           // el siguiente sample cae en mitad del stop
                if (sample) next_state = rxd_in ? S_INICIAL : S_ESPERA;

            S_ESPERA: begin
                clr = 1'b1;
                if (rxd_in) next_state = S_INICIAL;
            end

            default: next_state = S_INICIAL;
        endcase
    end

    assign char_done = (state == S_STOP) && sample;
    assign busy      = (state != S_INICIAL);

endmodule

