`default_nettype none
`timescale 1ns/1ps

module uart_tx_ctrl (

  input  wire logic       clk, rst,
  input  wire logic       bclk_tick,
  input  wire logic       osm_sel,
  input  wire logic [7:0] tx_data,
  input  wire logic       tx_empty,
  input  wire logic [1:0] wls,
  input  wire logic       pen, eps, sp,
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

  localparam logic [2:0] IDLE = 0, START = 1, DATA = 2, PARITY = 3, STOP = 4;
  logic [2:0] state;

  logic [7:0] tsr;
  logic [5:0] tick_cnt;
  logic [2:0] bit_cnt;

  logic [2:0] last_bit;
  logic       con_paridad, bit_paridad;
  logic [5:0] fin_bit, fin_stop;

  logic cts_a, cts_b;
  always_ff @(posedge clk) {cts_b, cts_a} <= rst ? 2'b11 : {cts_a, cts_n};

  logic [7:0] mascara;
  assign mascara = 8'hFF >> (2'd3 - wls);
  logic unos_impar;
  assign unos_impar = ^(tx_data & mascara);

  logic termino_bit;
  assign termino_bit = bclk_tick &&
                       (tick_cnt == ((state == STOP) ? fin_stop : fin_bit));

  logic puedo_empezar;
  assign puedo_empezar = !tx_empty && !(afe && cts_b);
  assign tx_pop = !rst && utrst && bclk_tick && puedo_empezar &&
                  (state == IDLE || (state == STOP && termino_bit));

  always_ff @(posedge clk) begin
    if (rst || !utrst) begin
      state    <= IDLE;
      tsr      <= 8'hFF;
      tick_cnt <= 0;
      bit_cnt  <= 0;
      last_bit <= 7;  con_paridad <= 0;  bit_paridad <= 1;
      fin_bit  <= 15; fin_stop    <= 15;

    end else if (tx_pop) begin
      state    <= START;
      tsr      <= tx_data;
      tick_cnt <= 0;
      bit_cnt  <= 0;

      last_bit    <= {1'b1, wls};
      con_paridad <= pen;
      bit_paridad <= sp ? ~eps : (eps ? unos_impar : ~unos_impar);
      fin_bit     <= osm_sel ? 6'd12 : 6'd15;
      fin_stop    <= !stb         ? (osm_sel ? 6'd12 : 6'd15)
                   : (wls == 2'b00) ? (osm_sel ? 6'd18 : 6'd23)
                   :                  (osm_sel ? 6'd25 : 6'd31);

    end else if (bclk_tick && state != IDLE) begin
      if (!termino_bit)
        tick_cnt <= tick_cnt + 1;
      else begin
        tick_cnt <= 0;
        case (state)
          START:  state <= DATA;
          DATA: begin
            tsr <= {1'b1, tsr[7:1]};
            if (bit_cnt == last_bit) begin
              bit_cnt <= 0;
              state   <= con_paridad ? PARITY : STOP;
            end else
              bit_cnt <= bit_cnt + 1;
          end
          PARITY:  state <= STOP;
          default: state <= IDLE;
        endcase
      end
    end
  end

  logic bit_actual;
  always_comb
    case (state)
      START:   bit_actual = 1'b0;
      DATA:    bit_actual = tsr[0];
      PARITY:  bit_actual = bit_paridad;
      default: bit_actual = 1'b1;
    endcase

  assign tx_serial_loop = bit_actual & ~bc;
  assign txd            = loop ? 1'b1 : tx_serial_loop;
  assign tsr_empty      = (state == IDLE);
  assign tx_busy        = !tsr_empty;

endmodule
`default_nettype wire
