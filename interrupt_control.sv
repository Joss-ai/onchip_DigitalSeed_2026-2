module interrupt_control (
    input  logic       clk,
    input  logic       rst,
    input  logic       erbi,
    input  logic       etbei,
    input  logic       elsi,
    input  logic       edssi,

    // Eventos recibidos de otros bloques
    input  logic       line_err,
    input  logic       rx_data_avail,
    input  logic       trig_reached,
    input  logic       tx_empty,
    input  logic       timeout_pending,
    input  logic       modem_status_change,

    input  logic [4:0] rx_count,
    input  logic       fifo_en,

    // Limpieza de eventos
    input  logic       lsr_rd,
    input  logic       thr_wr,
    input  logic       iir_rd,

    output logic       irq,
    output logic [7:0] iir
);

    localparam logic [2:0] ID_MODEM = 3'b000;
    localparam logic [2:0] ID_TX    = 3'b001;
    localparam logic [2:0] ID_RX    = 3'b010;
    localparam logic [2:0] ID_LINE  = 3'b011;
    localparam logic [2:0] ID_TO    = 3'b110;

    logic line_pending;
    logic tx_pending;
    logic rx_condition;
    logic timeout_condition;

    logic [2:0] intid;
    logic ipend;

    // Conserva los eventos hasta que se limpien.
    always_ff @(posedge clk) begin
        if (rst) begin
            line_pending <= 1'b0;
            tx_pending   <= 1'b0;
        end
        else begin
            if (lsr_rd)
                line_pending <= 1'b0;
            else if (line_err)
                line_pending <= 1'b1;

            if (thr_wr || iir_rd)
                tx_pending <= 1'b0;
            else if (tx_empty)
                tx_pending <= 1'b1;
        end
    end

    // Selección de la condición de recepción.
    always_comb begin
        if (fifo_en)
            rx_condition = trig_reached;
        else
            rx_condition = rx_data_avail;

        timeout_condition =
            timeout_pending && (rx_count != 0);
    end

    // Árbitro de prioridades.
    always_comb begin
        irq   = 1'b0;
        ipend = 1'b1;
        intid = ID_MODEM;

        if (elsi && line_pending) begin
            irq   = 1'b1;
            ipend = 1'b0;
            intid = ID_LINE;
        end
        else if (erbi && rx_condition) begin
            irq   = 1'b1;
            ipend = 1'b0;
            intid = ID_RX;
        end
        else if (erbi && timeout_condition) begin
            irq   = 1'b1;
            ipend = 1'b0;
            intid = ID_TO;
        end
        else if (etbei && tx_pending) begin
            irq   = 1'b1;
            ipend = 1'b0;
            intid = ID_TX;
        end
        else if (edssi && modem_status_change) begin
            irq   = 1'b1;
            ipend = 1'b0;
            intid = ID_MODEM;
        end
    end

    // Construcción del registro de identificación.
    always_comb begin
        iir = {fifo_en, fifo_en, 2'b00, intid, ipend};
    end

endmodule
