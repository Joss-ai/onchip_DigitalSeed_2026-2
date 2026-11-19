`timescale 1ns / 1ps

module uart_tx_ctrl (
    input  logic       clk,
    input  logic       rst,
    input  logic       bclk_tick,
    input  logic       osm_sel,
    input  logic [7:0] tx_data,
    input  logic       tx_empty,
    input  logic [1:0] wls,
    input  logic       pen,
    input  logic       eps,
    input  logic       sp,
    input  logic       stb,
    input  logic       bc,
    input  logic       utrst,
    input  logic       cts_n,
    input  logic       afe,
    input  logic       loop,
    output logic       txd,
    output logic       tx_pop,
    output logic       tsr_empty,
    output logic       tx_serial_loop,
    output logic       tx_busy
);

  logic [7:0] TSR;
  logic [5:0] CUENTA_TICK;
  logic [2:0] CUENTA_BIT;

  logic [2:0] ULTIMO_BIT;
  logic       CON_PARIDAD;
  logic       BIT_PARIDAD;
  logic [5:0] FIN_BIT_N;
  logic [5:0] FIN_STOP_N;

  logic CTS_A, CTS_B;

  logic       FIN_BIT;
  logic       ULTIMO;
  logic       HAY_DATO;
  logic       CARGA;
  logic       DESPLAZA;
  logic [7:0] MASCARA;
  logic       PARIDAD_CALC;
  logic [1:0] SEL;
  logic       OCUPADO;
  logic       LINEA;

  typedef enum logic [2:0] {
    IDLE    = 3'b000,
    START   = 3'b001,
    DATOS   = 3'b010,
    PARIDAD = 3'b011,
    STOP    = 3'b100
  } estado_t;

  estado_t presente, futuro;

  always_ff @(posedge clk)
    if (rst || !utrst)
      presente <= IDLE;
    else
      presente <= futuro;

  always_comb begin
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

      default:
        futuro = IDLE;
    endcase
  end

  always_comb begin
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
  end

  always_ff @(posedge clk)
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

  always_ff @(posedge clk)
    if (rst || !utrst)
      TSR <= 8'hFF;
    else if (CARGA)
      TSR <= tx_data;
    else if (DESPLAZA)
      TSR <= {1'b1, TSR[7:1]};

  always_ff @(posedge clk)
    if (rst || !utrst || CARGA)
      CUENTA_TICK <= 6'd0;
    else if (bclk_tick && presente != IDLE)
      CUENTA_TICK <= FIN_BIT ? 6'd0 : CUENTA_TICK + 6'd1;

  always_ff @(posedge clk)
    if (rst || !utrst || CARGA)
      CUENTA_BIT <= 3'd0;
    else if (DESPLAZA)
      CUENTA_BIT <= ULTIMO ? 3'd0 : CUENTA_BIT + 3'd1;

  always_ff @(posedge clk)
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
      FIN_STOP_N  <= !stb           ? (osm_sel ? 6'd12 : 6'd15)
                   : (wls == 2'b00) ? (osm_sel ? 6'd18 : 6'd23)
                   :                  (osm_sel ? 6'd25 : 6'd31);
    end

  always_comb begin
    case (SEL)
      2'b00:   LINEA = 1'b0;
      2'b01:   LINEA = TSR[0];
      2'b10:   LINEA = BIT_PARIDAD;
      default: LINEA = 1'b1;
    endcase
  end

  assign tx_serial_loop = LINEA & ~bc;
  assign txd            = loop ? 1'b1 : tx_serial_loop;
  assign tx_pop         = CARGA;
  assign tsr_empty      = !OCUPADO;
  assign tx_busy        = OCUPADO;

endmodule
