`timescale 1ns / 1ps

module Transmitter_FIFO(
    input clk, 
    input rst,
    input [7:0] din,
    input push,
    input pop,
    input fifo_en,
    output [7:0] dout,
    output empty,
    output full,
    output [4:0] cout
);

    // Declaración de señales internas utilizadas en las instancias
    wire [4:0] Psal;
    wire [4:0] Pcar;
    wire rd_en;
    wire safe_wr_en;
    wire rst_counters;

    // Lógica extra de control para habilitaciones y reset
    assign rst_counters = rst || !fifo_en;                    // Reinicia los contadores por reset externo o si el FIFO se deshabilita
    assign safe_wr_en   = fifo_en && push && !full;            // Escritura segura: habilitado, con orden de push y sin estar lleno
    assign rd_en        = fifo_en && pop  && !empty;           // Lectura segura: habilitado, con orden de pop y sin estar vacío

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

    // 3. Instancia de la Memoria RAM de datos
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

    // Estados lógicos del FIFO
    assign empty = (Pcar == Psal);
    assign full  = (Pcar[4] != Psal[4]) && (Pcar[3:0] == Psal[3:0]);

    // Nivel de ocupación actual (0 a 16)
    assign cout = Pcar - Psal;

endmodule
