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

`ifdef FORMAL
    reg f_past_valid = 1'b0;
    always @(posedge clk) f_past_valid <= 1'b1;
    always @* if (!f_past_valid) assume (rst);

    // Entorno: el modo 16x/13x es una configuracion estable
    always @(posedge clk) if (f_past_valid) assume ($stable(osm_sel));

    // El contador nunca supera el limite de su modo
    always @* if (f_past_valid) begin
        if (osm_sel) assert (tick_cnt <= 4'd12);
        else         assert (tick_cnt <= 4'd15);
    end

    // sample: tras bclk_tick, sin reset/clr, en el tick correcto
    always @(posedge clk) if (f_past_valid && sample) begin
        assert ($past(bclk_tick));
        assert (!($past(rst) || $past(urrst) || $past(clr)));
        if ($past(osm_sel)) assert ($past(tick_cnt) == 4'd5);
        else                assert ($past(tick_cnt) == 4'd7);
    end

    // reset/clr -> 0; sin tick -> se mantiene
    always @(posedge clk) if (f_past_valid) begin
        if ($past(rst) || $past(urrst) || $past(clr))
            assert (tick_cnt == 4'd0);
        else if (!$past(bclk_tick))
            assert (tick_cnt == $past(tick_cnt));
    end

    always @(posedge clk) begin
        cover (f_past_valid && sample && !osm_sel);
        cover (f_past_valid && sample &&  osm_sel);
        cover (f_past_valid && $past(tick_cnt) == 4'd15 && tick_cnt == 4'd0 && !osm_sel);
        cover (f_past_valid && $past(tick_cnt) == 4'd12 && tick_cnt == 4'd0 &&  osm_sel);
    end
`endif

endmodule
