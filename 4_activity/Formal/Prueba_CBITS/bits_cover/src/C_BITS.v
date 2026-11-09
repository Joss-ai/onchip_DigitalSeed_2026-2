`timescale 1ns / 1ps

module C_BITS( //cuenta los bits recibidos 
    input        clk,
    input        rst,
    input        urrst,       // reset del receptor (PWREMU_MGMT)
    input        clr,         // desde la FSM: reinicia la cuenta (al entrar a DATA)
    input        bit_en,      // desde la FSM: un bit de datos fue recibido
    input  [1:0] wls,         // longitud de palabra
    input        pen,         // Dice si ahy o no bit de paridad
    output reg   Done         // ya se recibieron todos los bits del caracter
    );

    wire [3:0] n_bits = {2'b00, wls} + 4'd5 + pen;   // 6 a 9 bits dato+paridad
    reg  [3:0] count;

    always @(posedge clk) begin
        if (rst || urrst || clr)       // logica de reinicio
            count <= 4'd0;
        else if (bit_en)               // aumenta cuando la FSM lo ordena
            count <= count + 4'd1;

        if (count == n_bits)           // si ya llegaron todos los bits, avisa
            Done <= 1'b1;
        else
            Done <= 1'b0;
    end

`ifdef FORMAL
    reg f_past_valid = 1'b0;
    always @(posedge clk) f_past_valid <= 1'b1;
    always @* if (!f_past_valid) assume (rst);

    // Entorno: wls y pen estables
    always @(posedge clk) if (f_past_valid) assume ($stable(wls) && $stable(pen));

    // Entorno: la FSM no ordena bit_en cuando ya se contaron todos los bits
    always @* if (count == n_bits) assume (!bit_en);

    always @* assert (n_bits >= 4'd5 && n_bits <= 4'd9);
    always @* if (f_past_valid) assert (count <= n_bits);

    always @(posedge clk) if (f_past_valid) begin
        if (Done) assert ($past(count) == $past(n_bits));
        if ($past(count) == $past(n_bits)) assert (Done);
        if ($past(rst) || $past(urrst) || $past(clr)) assert (count == 4'd0);
        else if ($past(bit_en)) assert (count == $past(count) + 4'd1);
        else                    assert (count == $past(count));
    end

    always @(posedge clk) begin
        cover (f_past_valid && Done && wls == 2'd0 && !pen);
        cover (f_past_valid && Done && wls == 2'd3 &&  pen);
    end
`endif

endmodule
