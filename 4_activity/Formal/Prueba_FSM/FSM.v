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
    
    
    
`ifdef FORMAL
    reg f_past_valid = 1'b0;
    always @(posedge clk) f_past_valid <= 1'b1;
    always @* if (!f_past_valid) assume (rst);

    // Solo 5 estados validos
    always @* if (f_past_valid) assert (state <= S_ESPERA);

    // Salidas coherentes con el estado
    always @* if (f_past_valid) begin
        assert (clr       == (state == S_INICIAL || state == S_ESPERA));
        assert (shift_en  == (state == S_ENTRADA));
        assert (bit_en    == (state == S_ENTRADA && sample));
        assert (busy      == (state != S_INICIAL));
        assert (char_done == (state == S_STOP && sample));
        assert (!(clr && shift_en));
        if (bit_en) assert (shift_en && sample);
    end

    // Tabla de transiciones
    always @(posedge clk) if (f_past_valid) begin
        if ($past(rst) || $past(urrst)) assert (state == S_INICIAL);
        else begin
            if ($past(state) == S_INICIAL  && !$past(rxd_in)) assert (state == S_REVISION);
            if ($past(state) == S_INICIAL  &&  $past(rxd_in)) assert (state == S_INICIAL);
            if ($past(state) == S_REVISION && $past(sample) &&  $past(rxd_in)) assert (state == S_INICIAL);
            if ($past(state) == S_REVISION && $past(sample) && !$past(rxd_in)) assert (state == S_ENTRADA);
            if ($past(state) == S_REVISION && !$past(sample)) assert (state == S_REVISION);
            if ($past(state) == S_ENTRADA  &&  $past(Done)) assert (state == S_STOP);
            if ($past(state) == S_ENTRADA  && !$past(Done)) assert (state == S_ENTRADA);
            if ($past(state) == S_STOP && $past(sample) &&  $past(rxd_in)) assert (state == S_INICIAL);
            if ($past(state) == S_STOP && $past(sample) && !$past(rxd_in)) assert (state == S_ESPERA);
            if ($past(state) == S_ESPERA &&  $past(rxd_in)) assert (state == S_INICIAL);
            if ($past(state) == S_ESPERA && !$past(rxd_in)) assert (state == S_ESPERA);
        end
    end

    always @(posedge clk) if (f_past_valid) begin
        cover (char_done &&  rxd_in);
        cover (char_done && !rxd_in);
        cover (state == S_ESPERA);
        cover ($past(state) == S_REVISION && state == S_INICIAL);  // falso start
    end
`endif


endmodule

