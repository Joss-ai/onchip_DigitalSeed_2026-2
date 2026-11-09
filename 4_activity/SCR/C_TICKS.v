`timescale 1ns / 1ps

module C_TICKS( // Cuenta en ticks
    input        clk,
    input        rst,
    input        urrst,        // reset del receptor (PWREMU_MGMT)
    input        bclk_tick,    // pulso del generador de baudios (1 ciclo de clk)
    input        osm_sel,      // 0: 16x, 1: 13x
    input        clr,          // desde la FSM: pone el contador en 0
    output reg [3:0] tick_cnt, // ticks transcurridos dentro del bit actual
    output reg       sample    // pulso de 1 ciclo de clk: "muestrea ahora"
    );

    wire [3:0] last  = osm_sel ? 4'd12 : 4'd15;
    wire [3:0] point = osm_sel ? 4'd5  : 4'd7;

    always @(posedge clk) begin
        sample <= 1'b0;                      // por defecto no hay pulso

        if (rst || urrst || clr) begin
            tick_cnt <= 4'd0;
        end else if (bclk_tick) begin        // solo avanza con el tick

            if (tick_cnt == last)            // reinicia si termino de contar
                tick_cnt <= 4'd0;
            else                             // suma 1 en cada tick
                tick_cnt <= tick_cnt + 4'd1;

            if (tick_cnt == point)           // llego al punto de muestreo
                sample <= 1'b1;
        end
    end

endmodule