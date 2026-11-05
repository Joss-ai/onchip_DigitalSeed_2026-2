`timescale 1ns / 1ps

module Receiver_FIFO(
    input clk,
    input rst,
    input [7:0] din,    
    input [2:0] err_in,
    input push,
    input pop,
    input fifo_en,    
    input clr,
    input [1:0] rxfiftl,
    
    output [7:0] dout,
    output [2:0] err_top,
    output empty,
    output full,
    output [4:0] cout,
    output trig_reached,
    output any_err
);
    
    wire [4:0] Psal;
    wire [4:0] Pcar;
    
    // Habilitaciones seguras para escritura y lectura
    wire safe_wr_en = push && fifo_en && !full;
    wire rd_en      = pop  && fifo_en && !empty;
    
    // El contador se reinicia por hardware (rst), por software (clr / RXCLR) o si se desgraba el FIFO
    wire rst_counters = rst || clr || !fifo_en;
    
    // 1. Instancia del Contador para el Puntero de Salida (Lectura)
    Contador P_salida(
        .E(rd_en),
        .rst(rst_counters),
        .clk(clk),
        .puntero(Psal)
    );
    
    // 2. Instancia del Contador para el Puntero de Carga (Escritura)
    Contador P_carga(
        .E(safe_wr_en),
        .rst(rst_counters),
        .clk(clk),
        .puntero(Pcar)
    );
    
    // 3. Tu bloque RAM para los Datos (8 bits de ancho, 4 bits de dirección)
    RAM #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(4)
    ) Mem_Datos (
        .clk(clk),
        .wr_en(safe_wr_en),
        .wr_addr(Pcar[3:0]), 
        .din(din),
        .rd_en(rd_en),
        .rd_addr(Psal[3:0]), 
        .dout(dout)
    );
    
    // 4. Reutilización de tu bloque RAM para los Errores (3 bits de ancho, 4 de dirección)
    RAM #(
        .DATA_WIDTH(3),
        .ADDR_WIDTH(4)
    ) Mem_Errores (
        .clk(clk),
        .wr_en(safe_wr_en),
        .wr_addr(Pcar[3:0]), 
        .din(err_in),
        .rd_en(rd_en),
        .rd_addr(Psal[3:0]), 
        .dout(err_top)
    );
    
    // Estados lógicos del FIFO
    assign empty = (Pcar == Psal);
    assign full  = (Pcar[4] != Psal[4]) && (Pcar[3:0] == Psal[3:0]);
    
    // Nivel de ocupación actual (0 a 16)
    assign cout = $signed({1'b0, Pcar}) - $signed({1'b0, Psal});
    
    // Decodificación del Nivel de Disparo (Trigger Level) según rxfiftl[1:0]
    reg [4:0] trig_limit;
    always @(*) begin
        case (rxfiftl)
            2'b00: trig_limit = 5'd1;  // 1 byte
            2'b01: trig_limit = 5'd4;  // 4 bytes
            2'b10: trig_limit = 5'd8;  // 8 bytes
            2'b11: trig_limit = 5'd14; // 14 bytes
            default: trig_limit = 5'd1;
        endcase
    end
    
    assign trig_reached = (cout >= trig_limit);

    // Registro auxiliar para rastrear si hay errores activos en las celdas del FIFO (any_err / RXFIFOE)
    reg [15:0] slot_has_err;
    integer i;
    
    always @(posedge clk or posedge rst_counters) begin
        if (rst_counters) begin
            slot_has_err <= 16'b0;
        end else begin
            if (safe_wr_en) begin
                slot_has_err[Pcar[3:0]] <= (|err_in); // Guarda si esta posición trae error
            end
            if (rd_en) begin
                slot_has_err[Psal[3:0]] <= 1'b0;    // Limpia el error al leer la celda
            end
        end
    end
    
    // any_err se activa si hay al menos un error en el FIFO y no está vacío
    assign any_err = (|slot_has_err) && !empty;

    // ==========================================
    // ZONA DE VERIFICACIÓN FORMAL (ASSERTIONS)
    // ==========================================
    `ifdef FORMAL

        // 1. CONDICIÓN DE INICIALIZACIÓN (Obligatorio para evitar estados fantasma)
        // Forzamos al motor SMT a que en el primer ciclo (Time 0) el reset esté activo.
        initial begin
            assume (rst == 1'b1);
        end

        // 2. EXCLUSIÓN MUTUA BÁSICA
        // Una FIFO nunca debe reportar 'full' y 'empty' al mismo tiempo.
        always_comb begin
            assert (!(full && empty));
        end

        // 3. LÍMITES FÍSICOS DEL CONTADOR DE OCUPACIÓN
        // El contador cout jamás puede superar el tamaño máximo de la FIFO (16).
        always_comb begin
            assert (cout <= 5'd16);
        end

        // 4. RETENCIÓN DEL ESTADO 'FULL'
        // Si la FIFO ya estaba llena, intentamos escribir (safe_wr_en) y NO leemos (rd_en), 
        // debe mantenerse llena en el siguiente ciclo.
        always @(posedge clk) begin
            if (!rst) begin // Solo evaluamos si el circuito salió del reset
                if (full && safe_wr_en && !rd_en) begin
                    assert (full);
                end
            end
        end

        // 5. RETENCIÓN DEL ESTADO 'EMPTY'
        // Si la FIFO estaba vacía, leemos (rd_en) y NO escribimos (safe_wr_en), 
        // debe mantenerse vacía en el siguiente ciclo.
        always @(posedge clk) begin
            if (!rst) begin // Solo evaluamos si el circuito salió del reset
                if (empty && rd_en && !safe_wr_en) begin
                    assert (empty);
                end
            end
        end

    `endif
endmodule
