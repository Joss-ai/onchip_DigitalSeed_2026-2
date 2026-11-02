`timescale 1ns / 1ps

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
