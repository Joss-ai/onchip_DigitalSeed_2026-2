`timescale 1ns / 1ps

module RX_timming_Control (
    input  wire       clk,
    input  wire       rst,
    input  wire       urrst,         // PWREMU_MGMT.URRST: 1 = activo, 0 = reset
    input  wire       rxd_in,        // pin RXD o salida del TSR en loopback
    input  wire       bclk_tick,
    input  wire       osm_sel,       // MDR.OSM_SEL: 0 = 16x, 1 = 13x
    input  wire [1:0] wls,
    input  wire       pen,
    input  wire       eps,
    input  wire       sp,
    input  wire       fifo_full,
    input  wire       fifo_empty,
    input  wire       trig_reached,  // FIFO llego al nivel de trigger
    input  wire [1:0] rxfiftl,       // FCR.RXFIFTL (3 = trigger de 14)
    input  wire       afe,
    input  wire       rts_en,        // MCR.RTS

    output reg  [7:0] rx_data,
    output reg        rx_push,
    output wire       rx_activity,
    output reg        pe,
    output reg        fe,
    output reg        bi,
    output reg        oe,
    output wire       rts_n,
    output wire       rx_busy
);

    wire rx_rst = ~urrst;            // los submodulos reinician con 1

    // Sincronizador de 2 flip-flops
    reg [1:0] sync;
    always @(posedge clk) begin
        if (rst || rx_rst) sync <= 2'b11;
        else               sync <= {sync[0], rxd_in};
    end
    wire rxd_s = sync[1];

    // Senales internas
    wire clr, shift_en, bit_en, sample, Done, char_done;
    wire [8:0] rx_dataP;
    wire [7:0] rx_data_c;
    wire       pe_c;

    FSM fsm_inst (
        .clk(clk), .rst(rst), .urrst(rx_rst),
        .rxd_in(rxd_s), .sample(sample), .Done(Done),
        .clr(clr), .shift_en(shift_en), .bit_en(bit_en),
        .char_done(char_done), .busy(rx_busy)
    );

    C_TICKS ticks_inst (
        .clk(clk), .rst(rst), .urrst(rx_rst),
        .bclk_tick(bclk_tick), .osm_sel(osm_sel), .clr(clr),
        .tick_cnt(), .sample(sample)
    );

    C_BITS bits_inst (
        .clk(clk), .rst(rst), .urrst(rx_rst),
        .clr(clr), .bit_en(bit_en), .wls(wls), .pen(pen), .Done(Done)
    );

    Registro_Desplazamiento reg_inst (
        .clk(clk), .rst(rst), .urrst(rx_rst),
        .rxd_in(rxd_s), .sample(sample), .shift_en(shift_en), .clr(clr),
        .wls(wls), .pen(pen), .eps(eps), .sp(sp),
        .rx_dataP(rx_dataP), .rx_data(rx_data_c), .pe(pe_c)
    );

    // Salidas: se capturan al muestrear el stop y viajan juntas con rx_push
    always @(posedge clk) begin
        rx_push <= 1'b0;
        oe      <= 1'b0;
        if (rst || rx_rst) begin
            rx_data <= 8'd0;
            pe <= 1'b0;  fe <= 1'b0;  bi <= 1'b0;
        end else if (char_done) begin
            rx_data <= rx_data_c;
            pe      <= pe_c;
            fe      <= ~rxd_s;                       // stop debe valer 1
            bi      <= ~(|rx_dataP) & ~rxd_s;        // todo en 0, incluido el stop
            rx_push <= ~fifo_full;
            oe      <= fifo_full;                    // el caracter se pierde
        end
    end

    assign rx_activity = char_done;

    // RTS: se desactiva al llegar al trigger; se reactiva con FIFO vacio
    // (triggers 1, 4, 8) o al bajar del trigger (14)
    reg rts_stop;
    always @(posedge clk) begin
        if (rst || rx_rst)                         rts_stop <= 1'b0;
        else if (trig_reached)                     rts_stop <= 1'b1;
        else if (rxfiftl == 2'd3 || fifo_empty)    rts_stop <= 1'b0;
    end

    assign rts_n = (afe && rts_en) ? rts_stop : ~rts_en;

endmodule
