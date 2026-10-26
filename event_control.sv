module event_control (
    input  logic       clk,
    input  logic       rst,
    input  logic       bclk_tick,

    // Estado de recepción
    input  logic [4:0] rx_count,
    input  logic [1:0] wls,
    input  logic       rx_activity,
    input  logic       rbr_rd,
    input  logic       urrst,

    // Eventos de las FIFO
    input  logic       fifo_en,
    input  logic       dmamode1,
    input  logic       trig_reached,
    input  logic       tx_empty,
    input  logic       utrst,

    output logic       timeout_pending,
    output logic       urxevt,
    output logic       utxevt
);

    logic [6:0] timeout_count;
    logic [6:0] timeout_limit;

    logic utrst_d;
    logic trig_reached_d;
    logic tx_empty_d;

    // Cuatro tiempos de carácter, expresados en tiempos de bit.
    always_comb begin
        case (wls)
            2'b00: timeout_limit = 7'd32;
            2'b01: timeout_limit = 7'd36;
            2'b10: timeout_limit = 7'd40;
            2'b11: timeout_limit = 7'd44;
            default: timeout_limit = 7'd32;
        endcase
    end

    // Cuenta el tiempo mientras existan datos pendientes
    // y no se detecte nueva actividad de recepción.
    always_ff @(posedge clk) begin
        if (rst || urrst || (rx_count == 0) ||
            rx_activity || rbr_rd) begin
            timeout_count   <= 7'd0;
            timeout_pending <= 1'b0;
        end
        else if (bclk_tick) begin
            if (timeout_count >= timeout_limit - 1'b1) begin
                timeout_pending <= 1'b1;
            end
            else begin
                timeout_count <= timeout_count + 1'b1;
            end
        end
    end

    // Generación de eventos DMA mediante detección de flanco.
    always_ff @(posedge clk) begin
        if (rst) begin
            urxevt         <= 1'b0;
            utxevt         <= 1'b0;
            utrst_d        <= 1'b0;
            trig_reached_d <= 1'b0;
            tx_empty_d     <= 1'b0;
        end
        else begin
            utrst_d        <= utrst;
            trig_reached_d <= trig_reached;
            tx_empty_d     <= tx_empty;

            // Los eventos son pulsos de un ciclo.
            urxevt <= 1'b0;
            utxevt <= 1'b0;

            if (fifo_en && dmamode1 &&
                trig_reached && !trig_reached_d)
                urxevt <= 1'b1;

            if (fifo_en && dmamode1 &&
                tx_empty && !tx_empty_d)
                utxevt <= 1'b1;

            // El flanco ascendente de UTRST genera UTXEVT.
            if (utrst && !utrst_d)
                utxevt <= 1'b1;
        end
    end

endmodule
