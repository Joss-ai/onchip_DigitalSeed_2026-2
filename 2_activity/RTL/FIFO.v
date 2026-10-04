// ==========================================
// MÓDULO PRINCIPAL: FIFO
// ==========================================
module FIFO(
    input wr_en,
    input [7:0] din,
    input rd_en,
    input clk,
    input rst,
    output [7:0] dout,
    output empty,
    output full
);
    
    wire [4:0] Psal;
    wire [4:0] Pcar;
    wire safe_wr_en = wr_en && !full;
    
    Contador P_salida(
        .E(rd_en),
        .rst(rst),
        .clk(clk),
        .puntero(Psal)
    );
    
    Contador P_carga(
        .E(safe_wr_en),
        .rst(rst),
        .clk(clk),
        .puntero(Pcar)
    );
    
    RAM Circular(
        .clk(clk),
        .wr_en(safe_wr_en),
        .wr_addr(Pcar[3:0]), 
        .din(din),
        .rd_en(rd_en),
        .rd_addr(Psal[3:0]), 
        .dout(dout)
    );
    
    assign empty = (Pcar == Psal);
    assign full = (Pcar[4] != Psal[4]) && (Pcar[3:0] == Psal[3:0]);
    
endmodule


// ==========================================
// MÓDULO: RAM (Escritura síncrona por enable, Lectura combinacional pura)
// ==========================================
module RAM #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4  
)(
    input wire clk,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [DATA_WIDTH-1:0] din,
    input wire rd_en,
    input wire [ADDR_WIDTH-1:0] rd_addr,
    output wire [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    // La memoria en sí escribe al flanco del reloj si wr_en está activo
    always @(posedge clk) begin
        if (wr_en) begin
            ram[wr_addr] <= din;
        end
    end

    // Lectura 100% combinacional guiada por el puntero de salida
    assign dout = ram[rd_addr];

endmodule


// ==========================================
// MÓDULO: FFD (Flip-Flop D de 5 bits)
// ==========================================
module FFD(
    input [4:0] D,       
    output reg [4:0] Q,  
    input E,             
    input rst,           
    input clk            
);

    always @(posedge clk) begin
        if (!rst) begin
            Q <= 5'b00000;
        end else if (E) begin
            Q <= D;        
        end
    end

endmodule


// ==========================================
// MÓDULO: CONTADOR
// ==========================================
module Contador(
    input E,
    input rst,
    input clk,
    output [4:0] puntero
);
    
    wire [4:0] in;
    wire [4:0] out;  
    
    assign in = out + 1'b1;
    
    FFD FF_contador (
        .D(in),
        .Q(out),
        .E(E),
        .rst(rst),
        .clk(clk)
    );
    
    assign puntero = out;  

endmodule