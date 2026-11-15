// =============================================================================
//  baud_gen.sv  ---  Generador de baudios (parte de MI Control Logic)
//
//  Qué hace:
//    Divide el reloj del sistema (clk) entre "divisor" y entrega un PULSO de un
//    ciclo (bclk_tick) cada "divisor" ciclos de clk. Ese pulso es el BCLK de la
//    guía de TI (SPRUGP1, sec. 2.1); el TX y el RX lo cuentan para medir cada bit.
//
//  Decisiones (iguales al baud_gen.v anterior, ahora con verificación formal):
//    - divisor = 0  -> "sin programar": no hay tick y la cuenta se queda en 0.
//    - divisor = 1  -> tick en todos los ciclos.
//    - se compara con ">=" (no "=="): si el divisor BAJA a mitad de cuenta, el
//      contador se recupera solo en vez de contar hasta 65535.
//    - osm_sel (16x/13x) NO entra aquí: lo usan TX y RX para contar ticks por bit.
// =============================================================================
module baud_gen (
    input  logic        clk,        // reloj del sistema
    input  logic        rst,        // reset síncrono, activo en alto
    input  logic [15:0] divisor,    // {DLH, DLL} que sale de la Control Logic
    output logic        bclk_tick   // pulso de 1 ciclo cada "divisor" ciclos de clk
);

    logic [15:0] cnt;                          // ciclos de clk dentro del periodo actual

    wire         div_valid = |divisor;         // 1 si divisor != 0
    wire  [15:0] last      = divisor - 16'd1;  // último valor de la cuenta (0..divisor-1)
    wire         at_last   = (cnt >= last);    // ">=" para recuperarse si el divisor baja

    always_ff @(posedge clk) begin
        if (rst || !div_valid) cnt <= 16'd0;   // reset o sin divisor: cuenta en cero
        else if (at_last)      cnt <= 16'd0;   // fin del periodo: reinicia
        else                   cnt <= cnt + 16'd1;
    end

    // Pulso combinacional en el último ciclo del periodo.
    assign bclk_tick = div_valid & at_last & ~rst;

`ifdef FORMAL
    // =========================================================================
    // VERIFICACIÓN FORMAL
    // =========================================================================

    // --- Preparación (igual que en los ejemplos de clase) --------------------
    logic f_past_valid = 1'b0;
    always_ff @(posedge clk) f_past_valid <= 1'b1;
    always @* if (!f_past_valid) assume (rst);        // arranca en reset

    // =========================================================================
    // PARTE A: propiedades que valen con CUALQUIER divisor (sin assume extra)
    // =========================================================================
    always @* begin
        // A1: sin divisor programado nunca hay tick
        if (divisor == 16'd0) assert (!bclk_tick);
        // A2: divisor = 1 -> tick en cada ciclo fuera de reset
        if (!rst && divisor == 16'd1) assert (bclk_tick);
        // A3: en reset nunca hay tick
        if (rst) assert (!bclk_tick);
        // A4: un tick solo puede salir cuando la cuenta ya llegó al final
        if (bclk_tick) assert (cnt >= divisor - 16'd1);
    end

    always_ff @(posedge clk) if (f_past_valid) begin
        // A5: tras un reset o con divisor 0 la cuenta vale 0
        if ($past(rst) || $past(divisor) == 16'd0) assert (cnt == 16'd0);
        // A6: tras un tick la cuenta vuelve a 0 (reinicia el periodo)
        if ($past(bclk_tick)) assert (cnt == 16'd0);
    end

    // =========================================================================
    // PARTE B: periodo EXACTO (modelo de referencia, como el f_gap de sticky_flag)
    //   assume: el divisor no cambia mientras funciona (el software lo programa
    //           una vez; en reset sí puede cambiar).
    // =========================================================================
    always_ff @(posedge clk) if (f_past_valid && !$past(rst)) assume ($stable(divisor));

    // f_gap = ciclos transcurridos desde el último tick/reset (modelo de referencia)
    logic [15:0] f_gap = 16'd0;
    always_ff @(posedge clk) begin
        if (rst || divisor == 16'd0 || bclk_tick) f_gap <= 16'd0;
        else                                       f_gap <= f_gap + 16'd1;
    end

    always @* begin
        if (f_past_valid) begin
            // B1: el contador real coincide con el modelo de referencia
            assert (cnt == f_gap);
            // B2: hay tick EXACTAMENTE cuando han pasado divisor-1 ciclos
            if (!rst && divisor != 16'd0) assert (bclk_tick == (f_gap == divisor - 16'd1));
            // B3: la cuenta nunca pasa del último valor del periodo
            if (divisor != 16'd0) assert (cnt <= divisor - 16'd1);
        end
    end

    // =========================================================================
    // COVER: los casos importantes SÍ ocurren (evita que todo pase "en vacío")
    // =========================================================================
    always_ff @(posedge clk) if (f_past_valid) begin
        cover (bclk_tick && divisor == 16'd1);                          // divisor mínimo
        cover (bclk_tick && divisor == 16'd4);                          // un tick normal (divisor > 1)
        cover ($past(bclk_tick, 3) && bclk_tick && divisor == 16'd3);   // dos ticks separados 3 ciclos
        cover (!rst && divisor == 16'd0);                               // divisor sin programar
    end
`endif

endmodule
