`timescale 1ns / 1ps

module uart_tx_ctrl(
    input        clk,
    input        rst,
    input        bclk_tick,
    input        osm_sel,
    input  [7:0] tx_data,
    input        tx_empty,
    input  [1:0] wls,
    input        pen,
    input        eps,
    input        sp,
    input        stb,
    input        bc,
    input        utrst,
    input        cts_n,
    input        afe,
    input        loop,
    output       txd,
    output       tx_pop,
    output       tsr_empty,
    output       tx_serial_loop,
    output       tx_busy
    );

 reg [7:0] TSR;
 reg [5:0] CUENTA_TICK;
 reg [2:0] CUENTA_BIT;

 reg [2:0] ULTIMO_BIT;
 reg       CON_PARIDAD;
 reg       BIT_PARIDAD;
 reg [5:0] FIN_BIT_N;
 reg [5:0] FIN_STOP_N;

 reg CTS_A, CTS_B;

 wire       FIN_BIT;
 wire       ULTIMO;
 wire       HAY_DATO;
 wire       CARGA;
 wire       DESPLAZA;
 wire [7:0] MASCARA;
 wire       PARIDAD_CALC;
 reg  [1:0] SEL;
 reg        OCUPADO;
 wire       LINEA;

 parameter IDLE    = 3'b000;
 parameter START   = 3'b001;
 parameter DATOS   = 3'b010;
 parameter PARIDAD = 3'b011;
 parameter STOP    = 3'b100;

 reg [2:0] presente = IDLE;
 reg [2:0] futuro;

 always @(posedge clk)
     if (rst || !utrst)
         presente <= IDLE;
     else
         presente <= futuro;

 always @(*)
     begin
     case (presente)
         IDLE:
             if (bclk_tick && HAY_DATO)
                 futuro = START;
             else
                 futuro = IDLE;

         START:
             if (FIN_BIT)
                 futuro = DATOS;
             else
                 futuro = START;

         DATOS:
             if (FIN_BIT && ULTIMO)
                 futuro = CON_PARIDAD ? PARIDAD : STOP;
             else
                 futuro = DATOS;

         PARIDAD:
             if (FIN_BIT)
                 futuro = STOP;
             else
                 futuro = PARIDAD;

         STOP:
             if (FIN_BIT && HAY_DATO)
                 futuro = START;
             else if (FIN_BIT)
                 futuro = IDLE;
             else
                 futuro = STOP;

         default
             futuro = IDLE;
     endcase
     end

 always @(*)
     case (presente)
     IDLE: begin
         SEL     = 2'b11;
         OCUPADO = 1'b0;
     end
     START: begin
         SEL     = 2'b00;
         OCUPADO = 1'b1;
     end
     DATOS: begin
         SEL     = 2'b01;
         OCUPADO = 1'b1;
     end
     PARIDAD: begin
         SEL     = 2'b10;
         OCUPADO = 1'b1;
     end
     STOP: begin
         SEL     = 2'b11;
         OCUPADO = 1'b1;
     end
     default: begin
         SEL     = 2'b11;
         OCUPADO = 1'b0;
     end
     endcase

 always @(posedge clk)
     if (rst) begin
         CTS_A <= 1'b1;
         CTS_B <= 1'b1;
     end else begin
         CTS_A <= cts_n;
         CTS_B <= CTS_A;
     end

 assign HAY_DATO = !tx_empty && !(afe && CTS_B);
 assign FIN_BIT  = bclk_tick && (CUENTA_TICK == ((presente == STOP) ? FIN_STOP_N : FIN_BIT_N));
 assign ULTIMO   = (CUENTA_BIT == ULTIMO_BIT);
 assign CARGA    = !rst && utrst && bclk_tick && HAY_DATO &&
                   ((presente == IDLE) || (presente == STOP && FIN_BIT));
 assign DESPLAZA = (presente == DATOS) && FIN_BIT;

 assign MASCARA      = 8'hFF >> (2'd3 - wls);
 assign PARIDAD_CALC = ^(tx_data & MASCARA);

 always @(posedge clk)
     if (rst || !utrst)
         TSR <= 8'hFF;
     else if (CARGA)
         TSR <= tx_data;
     else if (DESPLAZA)
         TSR <= {1'b1, TSR[7:1]};

 always @(posedge clk)
     if (rst || !utrst || CARGA)
         CUENTA_TICK <= 6'd0;
     else if (bclk_tick && presente != IDLE)
         CUENTA_TICK <= FIN_BIT ? 6'd0 : CUENTA_TICK + 6'd1;

 always @(posedge clk)
     if (rst || !utrst || CARGA)
         CUENTA_BIT <= 3'd0;
     else if (DESPLAZA)
         CUENTA_BIT <= ULTIMO ? 3'd0 : CUENTA_BIT + 3'd1;

 always @(posedge clk)
     if (rst || !utrst) begin
         ULTIMO_BIT  <= 3'd7;
         CON_PARIDAD <= 1'b0;
         BIT_PARIDAD <= 1'b1;
         FIN_BIT_N   <= 6'd15;
         FIN_STOP_N  <= 6'd15;
     end else if (CARGA) begin
         ULTIMO_BIT  <= {1'b1, wls};
         CON_PARIDAD <= pen;
         BIT_PARIDAD <= sp ? ~eps : (eps ? PARIDAD_CALC : ~PARIDAD_CALC);
         FIN_BIT_N   <= osm_sel ? 6'd12 : 6'd15;
         FIN_STOP_N  <= !stb          ? (osm_sel ? 6'd12 : 6'd15)
                      : (wls == 2'b00) ? (osm_sel ? 6'd18 : 6'd23)
                      :                  (osm_sel ? 6'd25 : 6'd31);
     end

 assign LINEA = (SEL == 2'b00) ? 1'b0 :
                (SEL == 2'b01) ? TSR[0] :
                (SEL == 2'b10) ? BIT_PARIDAD : 1'b1;

 assign tx_serial_loop = LINEA & ~bc;
 assign txd            = loop ? 1'b1 : tx_serial_loop;
 assign tx_pop         = CARGA;
 assign tsr_empty      = !OCUPADO;
 assign tx_busy        = OCUPADO;

`ifdef FORMAL
    reg f_past_valid = 1'b0;
    always @(posedge clk) f_past_valid <= 1'b1;
    always @* if (!f_past_valid) assume (rst);

    // Invariantes: estado, contadores y configuracion siempre en rango
    always @* if (f_past_valid) begin
        assert (presente <= STOP);
        assert (ULTIMO_BIT >= 3'd4);
        assert (FIN_BIT_N == 6'd12 || FIN_BIT_N == 6'd15);
        if (presente == IDLE)  assert (CUENTA_TICK == 6'd0);
        if (presente == STOP)  assert (CUENTA_TICK <= FIN_STOP_N);
        else                   assert (CUENTA_TICK <= FIN_BIT_N);
        if (presente == DATOS) assert (CUENTA_BIT <= ULTIMO_BIT);
        else                   assert (CUENTA_BIT == 3'd0);
    end

    // Linea: valor correcto segun el estado, break y loopback
    always @* if (f_past_valid) begin
        if (loop) assert (txd == 1'b1);
        else      assert (txd == tx_serial_loop);
        if (bc)   assert (tx_serial_loop == 1'b0);
        else begin
            if (presente == START)                    assert (tx_serial_loop == 1'b0);
            if (presente == IDLE || presente == STOP) assert (tx_serial_loop == 1'b1);
            if (presente == DATOS)                    assert (tx_serial_loop == TSR[0]);
            if (presente == PARIDAD)                  assert (tx_serial_loop == BIT_PARIDAD);
        end
        assert (tsr_empty == (presente == IDLE));
    end

    // tx_pop: solo cuando es legal
    always @* if (tx_pop) begin
        assert (!tx_empty && utrst && bclk_tick && !rst);
        assert (presente == IDLE || presente == STOP);
    end

    // Despues de tx_pop: START, TSR con el dato y sin un segundo pop
    always @(posedge clk) if (f_past_valid && $past(tx_pop)) begin
        assert (presente == START);
        assert (TSR == $past(tx_data));
        assert (CUENTA_TICK == 6'd0);
        assert (!tx_pop);
    end

    // Sin bclk_tick (y sin reset) nada se mueve
    always @(posedge clk)
        if (f_past_valid && !$past(rst) && $past(utrst) && !$past(bclk_tick)) begin
            assert (presente == $past(presente));
            assert (CUENTA_TICK == $past(CUENTA_TICK));
            assert (TSR == $past(TSR));
        end

    // reset o utrst = 0 -> IDLE
    always @(posedge clk) if (f_past_valid && ($past(rst) || !$past(utrst)))
        assert (presente == IDLE);

    always @(posedge clk) begin
        cover (f_past_valid && presente == DATOS);
        cover (f_past_valid && presente == PARIDAD);
        cover (f_past_valid && presente == STOP);
        cover (f_past_valid && tx_pop && presente == STOP);   // dos tramas seguidas
    end
`endif

endmodule
