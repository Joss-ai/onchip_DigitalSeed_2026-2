`timescale 1ns / 1ps

module FIFO_tb;

typedef enum {FIFO_WRITE, FIFO_READ} fifo_op_t;

class fifo_transaction;

    fifo_op_t op;

    bit       rst;
    bit       wr_en;
    bit       rd_en;
    bit [7:0] din;

    bit [7:0] dout;
    bit       empty;
    bit       full;

    function new();
        rst   = 1'b0;
        wr_en = 1'b0;
        rd_en = 1'b0;
        din   = 8'h00;
    endfunction

    function void print(string tag = "");
        $display(
            "T=%0t %s rst=%0d wr_en=%0d din=0x%02h rd_en=%0d dout=0x%02h empty=%0d full=%0d",
            $time,
            tag,
            rst,
            wr_en,
            din,
            rd_en,
            dout,
            empty,
            full
        );
    endfunction

endclass

interface fifo_if(input bit clk);

    logic rst;
    logic wr_en;
    logic [7:0] din;
    logic rd_en;

    logic [7:0] dout;
    logic empty;
    logic full;

    clocking mon_cb @(posedge clk);
        default input #1step output #0;

        input rst;
        input wr_en;
        input din;
        input rd_en;

        input dout;
        input empty;
        input full;
    endclocking

    clocking drv_cb @(posedge clk);
        default input #1step output #0;

        output wr_en;
        output din;
        output rd_en;

        input rst;
        input full;
        input empty;
    endclocking

endinterface

class generator;

    mailbox #(fifo_transaction) drv_mbx;
    event drv_done;

    int num = 20;

    task run();

        for (int i = 0; i < num; i++) begin

            fifo_transaction item = new();

            // ==========================================
            // RESET
            // ==========================================
            if (i < 3) begin

                item.rst   = 0;
                item.wr_en = 0;
                item.rd_en = 0;
                item.op    = FIFO_WRITE;

            end

            // ==========================================
            // ESCRITURAS
            // ==========================================
            else if (i < 9) begin

                item.rst   = 1;
                item.wr_en = 1;
                item.rd_en = 0;
                item.op    = FIFO_WRITE;

                item.din = $urandom_range(0,255);

            end

            // ==========================================
            // LECTURAS
            // ==========================================
            else if (i < 14) begin

                item.rst   = 1;
                item.wr_en = 0;
                item.rd_en = 1;
                item.op    = FIFO_READ;

            end

            // ==========================================
            // MIXTO
            // ==========================================
            else begin

                item.rst = 1;

                if ($urandom_range(0,1)) begin

                    item.op    = FIFO_WRITE;
                    item.wr_en = 1;
                    item.rd_en = 0;
                    item.din   = $urandom_range(0,255);

                end
                else begin

                    item.op    = FIFO_READ;
                    item.wr_en = 0;
                    item.rd_en = 1;

                end

            end

            item.print("[GENERATOR]");

            drv_mbx.put(item);

            // Esperar al driver
            @(drv_done);

        end

        $display(
            "T=%0t [GENERATOR] Finished %0d transactions",
            $time,
            num
        );

    endtask

endclass

class driver;

    virtual fifo_if vif;

    mailbox #(fifo_transaction) drv_mbx;
    event drv_done;

    function new();
    endfunction

    task run();

        fifo_transaction item;

        // Estado inicial
        vif.wr_en <= 0;
        vif.rd_en <= 0;
        vif.din   <= 0;

        forever begin

            drv_mbx.get(item);

            // Esperamos al siguiente ciclo
            @(vif.drv_cb);

            // ==========================================
            // RESET
            // ==========================================
            if (item.rst == 0) begin

                vif.wr_en <= 0;
                vif.rd_en <= 0;
                vif.din   <= 0;

            end

            // ==========================================
            // WRITE
            // ==========================================
            else if (item.op == FIFO_WRITE) begin

                if (!vif.drv_cb.full) begin

                    vif.wr_en <= 1;
                    vif.rd_en <= 0;
                    vif.din   <= item.din;

                end
                else begin

                    vif.wr_en <= 0;
                    vif.rd_en <= 0;

                end

            end

            // ==========================================
            // READ
            // ==========================================
            else if (item.op == FIFO_READ) begin

                if (!vif.drv_cb.empty) begin

                    vif.wr_en <= 0;
                    vif.rd_en <= 1;

                end
                else begin

                    vif.wr_en <= 0;
                    vif.rd_en <= 0;

                end

            end

            // Un ciclo activo
            @(vif.drv_cb);

            vif.wr_en <= 0;
            vif.rd_en <= 0;

            -> drv_done;

        end

    endtask

endclass

class monitor;

    virtual fifo_if vif;

    mailbox #(fifo_transaction) scb_mbx;

    function new();
    endfunction

    task run();

        if (vif == null)
            $fatal(1, "[MONITOR] vif no asignada");

        forever begin

            @(vif.mon_cb);

            fifo_transaction tr = new();

            tr.rst   = vif.mon_cb.rst;
            tr.wr_en = vif.mon_cb.wr_en;
            tr.din   = vif.mon_cb.din;
            tr.rd_en = vif.mon_cb.rd_en;

            tr.dout  = vif.mon_cb.dout;
            tr.empty = vif.mon_cb.empty;
            tr.full  = vif.mon_cb.full;

            // Solo enviar operaciones reales
            if (tr.rst == 1'b1 &&
                (tr.wr_en || tr.rd_en)) begin

                if (tr.wr_en)
                    tr.op = FIFO_WRITE;
                else
                    tr.op = FIFO_READ;

                tr.print("[MONITOR]");

                scb_mbx.put(tr);

            end

        end

    endtask

endclass

class scoreboard;

    mailbox #(fifo_transaction) scb_mbx;

    bit [7:0] fifo_model[$];

    function new();
    endfunction

    task run();

        fifo_transaction tr;

        forever begin

            scb_mbx.get(tr);

            // ==========================================
            // WRITE
            // ==========================================
            if (tr.op == FIFO_WRITE) begin

                if (!tr.full) begin

                    fifo_model.push_back(tr.din);

                    $display(
                        "T=%0t [SCOREBOARD] WRITE DATA=%02h MODEL_SIZE=%0d",
                        $time,
                        tr.din,
                        fifo_model.size()
                    );

                end

            end

            // ==========================================
            // READ
            // ==========================================
            else if (tr.op == FIFO_READ) begin

                if (tr.empty) begin

                    $display(
                        "T=%0t [SCOREBOARD] READ ignored: FIFO EMPTY",
                        $time
                    );

                end
                else if (fifo_model.size() == 0) begin

                    $error(
                        "T=%0t [SCOREBOARD] ERROR: DUT dice NOT EMPTY pero modelo está vacío",
                        $time
                    );

                end
                else begin

                    bit [7:0] expected;

                    expected = fifo_model.pop_front();

                    if (expected === tr.dout) begin

                        $display(
                            "T=%0t [SCOREBOARD] PASS Expected=%02h Received=%02h",
                            $time,
                            expected,
                            tr.dout
                        );

                    end
                    else begin

                        $error(
                            "T=%0t [SCOREBOARD] ERROR Expected=%02h Received=%02h",
                            $time,
                            expected,
                            tr.dout
                        );

                    end

                end

            end

        end

    endtask

endclass

endmodule