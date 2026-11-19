`default_nettype none
`timescale 1ns/1ps

module uart_tx_ctrl (
  input  wire logic       clk,
  input  wire logic       rst,
  input  wire logic       bclk_tick,
  input  wire logic       osm_sel,
  input  wire logic [7:0] tx_data,
  input  wire logic       tx_empty,
  input  wire logic [1:0] wls,
  input  wire logic       pen,
  input  wire logic       eps,
  input  wire logic       sp,
  input  wire logic       stb,
  input  wire logic       bc,
  input  wire logic       utrst,
  input  wire logic       cts_n,
  input  wire logic       afe,
  input  wire logic       loop,
  output logic            txd,
  output logic            tx_pop,
  output logic            tsr_empty,
  output logic            tx_serial_loop,
  output logic            tx_busy
);
  localparam logic [2:0] IDLE   = 3'd0,
                         START  = 3'd1,
                         DATA   = 3'd2,
                         PARITY = 3'd3,
                         STOP   = 3'd4;

  logic [2:0] state;
  logic [7:0] tsr;
  logic [2:0] bit_cnt;
  logic [5:0] tick_cnt;

  logic [2:0] l_last;
  logic       l_pen;
  logic       l_par;
  logic [5:0] l_bit_last;
  logic [5:0] l_stop_last;

  logic cts_n_m, cts_n_s;
  always_ff @(posedge clk)
    if (rst) {cts_n_s, cts_n_m} <= 2'b11;
    else     {cts_n_s, cts_n_m} <= {cts_n_m, cts_n};

  logic [7:0] mask;
  always_comb
    case (wls)
      2'b00:   mask = 8'h1F;
      2'b01:   mask = 8'h3F;
      2'b10:   mask = 8'h7F;
      default: mask = 8'hFF;
    endcase

  logic       par_xor, par_bit;
  logic [5:0] tpb_last, stop_last;
  assign par_xor   = ^(tx_data & mask);
`ifdef BUG_PARITY
  assign par_bit   = sp ? ~eps : (eps ? ~par_xor : par_xor);
`else
  assign par_bit   = sp  ? ~eps
                   : eps ? par_xor
                   :       ~par_xor;
`endif
  assign tpb_last  = osm_sel ? 6'd12 : 6'd15;
  assign stop_last = !stb           ? tpb_last
                   : (wls == 2'b00) ? (osm_sel ? 6'd18 : 6'd23)
                   :                  (osm_sel ? 6'd25 : 6'd31);

  logic bit_done, can_start, slot_free;
  assign bit_done  = bclk_tick &&
                     (tick_cnt == ((state == STOP) ? l_stop_last : l_bit_last));
  assign can_start = !tx_empty && !(afe && cts_n_s);
  assign slot_free = (state == IDLE) || (state == STOP && bit_done);
  assign tx_pop    = !rst && utrst && bclk_tick && slot_free && can_start;

  always_ff @(posedge clk) begin
    if (rst || !utrst) begin
      state       <= IDLE;
      tsr         <= 8'hFF;
      bit_cnt     <= 3'd0;
      tick_cnt    <= 6'd0;
      l_last      <= 3'd7;
      l_pen       <= 1'b0;
      l_par       <= 1'b1;
      l_bit_last  <= 6'd15;
      l_stop_last <= 6'd15;
    end else if (tx_pop) begin
      state       <= START;
      tsr         <= tx_data;
      bit_cnt     <= 3'd0;
      tick_cnt    <= 6'd0;
      l_last      <= {1'b1, wls};
      l_pen       <= pen;
      l_par       <= par_bit;
      l_bit_last  <= tpb_last;
      l_stop_last <= stop_last;
    end else if (bclk_tick && state != IDLE) begin
      if (!bit_done)
        tick_cnt <= tick_cnt + 6'd1;
      else begin
        tick_cnt <= 6'd0;
        case (state)
          START:  state <= DATA;
          DATA: begin
            tsr <= {1'b1, tsr[7:1]};
            if (bit_cnt == l_last) begin
              bit_cnt <= 3'd0;
              state   <= l_pen ? PARITY : STOP;
            end else
              bit_cnt <= bit_cnt + 3'd1;
          end
          PARITY:  state <= STOP;
          STOP:    state <= IDLE;
          default: state <= IDLE;
        endcase
      end
    end
  end

  logic serial;
  always_comb
    case (state)
      START:   serial = 1'b0;
      DATA:    serial = tsr[0];
      PARITY:  serial = l_par;
      default: serial = 1'b1;
    endcase

  assign tx_serial_loop = serial & ~bc;
  assign txd            = loop ? 1'b1 : tx_serial_loop;
  assign tsr_empty      = (state == IDLE);
  assign tx_busy        = ~tsr_empty;

`ifdef FORMAL
  `define UART_TX_CHECKS
  `define CHK(c, msg) assert (c);
`endif
`ifdef ASSERTIONS
  `define UART_TX_CHECKS
  `define CHK(c, msg) assert (c) else $error("[uart_tx_ctrl] %s", msg);
`endif

`ifdef UART_TX_CHECKS
  logic f_past_valid = 1'b0;
  always @(posedge clk) f_past_valid <= 1'b1;

`ifdef FORMAL

  always @(*) if (!f_past_valid) assume (rst);
`endif

  logic [7:0] f_data = 8'h00;
  logic [1:0] f_wls  = 2'b11;
  logic       f_pen = 1'b0, f_eps = 1'b0, f_sp = 1'b0, f_stb = 1'b0, f_osm = 1'b0;
  always @(posedge clk)
    if (tx_pop) begin
      f_data <= tx_data; f_wls <= wls; f_pen <= pen; f_eps <= eps;
      f_sp   <= sp;      f_stb <= stb; f_osm <= osm_sel;
    end

  logic [2:0]  f_last;
  logic [7:0]  f_mask;
  logic [5:0]  f_bit_l, f_stp_l;
  logic [15:0] f_ext;
  logic [3:0]  f_nshift;
  assign f_last   = {1'b1, f_wls};
  assign f_mask   = 8'hFF >> (2'd3 - f_wls);
  assign f_bit_l  = f_osm ? 6'd12 : 6'd15;
  assign f_stp_l  = !f_stb ? f_bit_l
                  : (f_wls == 2'b00) ? (f_osm ? 6'd18 : 6'd23)
                  :                    (f_osm ? 6'd25 : 6'd31);
  assign f_ext    = {8'hFF, f_data};
  assign f_nshift = {1'b0, f_last} + 4'd1;

  always @(posedge clk) if (!rst) begin

    `CHK(state <= STOP,                                   "estado ilegal")
    `CHK(l_bit_last == 6'd15 || l_bit_last == 6'd12,     "l_bit_last ilegal")
    if (state == IDLE) `CHK(tick_cnt == 6'd0,            "tick_cnt != 0 en IDLE")
    if (state != DATA) `CHK(bit_cnt == 3'd0,             "bit_cnt != 0 fuera de DATA")
    else               `CHK(bit_cnt <= l_last,           "bit_cnt fuera de rango")
    if (state == STOP) `CHK(tick_cnt <= l_stop_last,     "tick_cnt fuera de rango (STOP)")
    else               `CHK(tick_cnt <= l_bit_last,      "tick_cnt fuera de rango")

    if (state != IDLE) begin
      `CHK(l_last      == f_last,                         "l_last no coincide con WLS capturado")
      `CHK(l_pen       == f_pen,                          "l_pen no coincide")
      `CHK(l_bit_last  == f_bit_l,                        "ticks/bit no coinciden con OSM")
      `CHK(l_stop_last == f_stp_l,                        "duración de stop incorrecta")
    end

    if (state == START) `CHK(tsr == f_data,                         "TSR != dato cargado")
    if (state == DATA)  `CHK(tsr == f_ext[{1'b0, bit_cnt} +: 8],    "TSR mal desplazado")
    if (state == PARITY || state == STOP)
                        `CHK(tsr == f_ext[f_nshift +: 8],           "TSR mal tras los datos")

    if (state == DATA)  `CHK(serial == f_data[bit_cnt],             "bit de datos incorrecto")

    if (state != IDLE && f_pen) begin
      if (f_sp)       `CHK(l_par == !f_eps,                         "stick parity incorrecta")
      else if (f_eps) `CHK((^{l_par, f_data & f_mask}) == 1'b0,     "paridad par incorrecta")
      else            `CHK((^{l_par, f_data & f_mask}) == 1'b1,     "paridad impar incorrecta")
    end
    if (state == PARITY) `CHK(f_pen && serial == l_par,             "PARITY sin pen o bit mal")

    if (loop)       `CHK(txd == 1'b1,                     "txd debe ser 1 en loopback")
    else if (bc)    `CHK(txd == 1'b0,                     "txd debe ser 0 con break")
    else if (state == IDLE || state == STOP)
                    `CHK(txd == 1'b1,                     "txd debe ser 1 en IDLE/STOP")
    else if (state == START)
                    `CHK(txd == 1'b0,                     "txd debe ser 0 en START")
    `CHK(tx_serial_loop == (serial & !bc),                "tx_serial_loop incorrecto")
    `CHK(tsr_empty == (state == IDLE),                    "tsr_empty incorrecto")
    `CHK(tx_busy   == !tsr_empty,                         "tx_busy incorrecto")

    if (tx_pop) begin
      `CHK(utrst && bclk_tick && !tx_empty,               "tx_pop sin utrst/tick/dato")
      `CHK(!(afe && cts_n_s),                             "tx_pop con CTS# bloqueando")
      `CHK(state == IDLE || (state == STOP && tick_cnt == l_stop_last),
                                                          "tx_pop con el TSR ocupado")
    end
  end

  always @(posedge clk) if (f_past_valid && !rst) begin
    if ($past(rst) || !$past(utrst))
      `CHK(state == IDLE,                                 "no volvió a IDLE tras reset/utrst")

    if ($past(tx_pop)) begin
      `CHK(state == START && tick_cnt == 6'd0 && tsr == $past(tx_data),
                                                          "carga incorrecta tras tx_pop")
      `CHK(!tx_pop,                                       "dos tx_pop seguidos")
    end

    if (!$past(rst) && $past(utrst) && !$past(bclk_tick))
      `CHK(state == $past(state) && tick_cnt == $past(tick_cnt)
           && bit_cnt == $past(bit_cnt) && tsr == $past(tsr),
                                                          "cambió el estado sin bclk_tick")

    if (!$past(rst) && $past(utrst) && $past(state) != IDLE
        && (state != $past(state) || bit_cnt != $past(bit_cnt)))
      `CHK($past(bclk_tick) && $past(tick_cnt) ==
           (($past(state) == STOP) ? $past(l_stop_last) : $past(l_bit_last)),
                                                          "bit terminó antes de tiempo")

    if (!$past(rst) && $past(utrst) && $past(bclk_tick) && $past(state) != IDLE
        && state == $past(state) && bit_cnt == $past(bit_cnt))
      `CHK(tick_cnt == $past(tick_cnt) + 6'd1,            "tick_cnt no avanzó en 1")
  end

`ifdef VERILATOR

  a_pop_start: assert property (@(posedge clk) disable iff (rst || !utrst)
                                tx_pop |=> (state == START));
  a_loop_high: assert property (@(posedge clk) disable iff (rst)
                                loop |-> txd);
`endif

`ifdef FORMAL
  always @(posedge clk) if (f_past_valid && !$past(rst)) begin
    cover ($past(state) == STOP && state == IDLE  && f_last == 3'd7 && !f_pen);
    cover ($past(state) == STOP && state == START);
    cover ($past(state) == STOP && state == IDLE  && f_pen && f_stb && f_osm);
  end
`endif
`endif

endmodule

`default_nettype wire
