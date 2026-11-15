`timescale 1ns / 1ps
// =============================================================================
//  control_logic.sv  ---  Control Logic del UART (bloque 5 de UART_Signals.docx)
//
//  Qué hace (resumen):
//    1. Decodifica el bus de la CPU (addr, sel, rd, wr).
//    2. Guarda los registros de configuración y los reparte a los demás bloques.
//    3. Genera los pulsos de acceso (rbr_rd, thr_wr, fcr_wr, iir_rd, lsr_rd).
//    4. Arma el valor de lectura (rdata), incluido el LSR.
//    5. Inserta 2 estados de espera al escribir DLL/DLH (ready).
//
//  Compatibilidad con los módulos del equipo (ver UART_Verificacion_Formal_ControlLogic.md):
//    - Receiver_FIFO  : rbr_rd = pop (rd_en); rxclr entra como reset ASÍNCRONO
//                       -> por eso rxclr/txclr salen REGISTRADOS (sin glitches).
//    - RX_timming_Control : oe llega como PULSO -> se retiene hasta leer el LSR.
//    - uart_tx_ctrl   : utrst, urrst, wls, pen, eps, sp, stb, bc, afe, loop, osm_sel.
//
//  Decisiones propias (no vienen del docx) marcadas con (P):
//    P1. rst síncrono, activo en alto.
//    P2. ready baja en el MISMO ciclo de la petición (combinacional).
//    P3. rbr_rd, thr_wr, fcr_wr, iir_rd, lsr_rd y rdata son combinacionales.
//    P4. OE se retiene hasta leer el LSR (parámetro OE_STICKY).
//    P5. PWREMU_MGMT en 8 bits: bit0=FREE, bit5=URRST, bit6=UTRST.
//    P6. MSR, REVID1 y REVID2 se leen como 0.
//    P7. rxclr/txclr se registran (pulso de 1 ciclo, un ciclo después de la escritura).
//    P8. En el LSR, PE/FE/BI solo se muestran si DR=1 (el FIFO RX no limpia
//        err_top cuando está vacío).
// =============================================================================
module control_logic #(
    parameter OE_STICKY = 1      // 1 = OE se retiene hasta leer LSR (P4)
)(
    input  logic        clk,
    input  logic        rst,                 // (P1)

    // ---- Bus del periférico (lado CPU) --------------------------------------
    input  logic [5:2]  addr,                // offset / 4
    input  logic [7:0]  wdata,
    input  logic        wr,
    input  logic        rd,
    input  logic        sel,
    output logic [31:0] rdata,               // solo 8 bits útiles
    output logic        ready,               // 0 = la CPU debe esperar

    // ---- Estados que llegan de otros bloques (para armar el LSR) ------------
    input  logic        DR,
    input  logic        OE,
    input  logic        PE,
    input  logic        FE,
    input  logic        BI,
    input  logic        THRE,
    input  logic        TEMT,
    input  logic        RXFIFOE,

    // ---- Datos que llegan de otros bloques ----------------------------------
    input  logic [7:0]  rbr_data,
    input  logic [7:0]  iir_data,

    // ---- Pulsos de acceso ---------------------------------------------------
    output logic        rbr_rd,
    output logic        thr_wr,
    output logic        fcr_wr,
    output logic        iir_rd,
    output logic        lsr_rd,

    // ---- Configuración: LCR -------------------------------------------------
    output logic [1:0]  wls,
    output logic        stb,
    output logic        pen,
    output logic        eps,
    output logic        sp,
    output logic        bc,
    output logic        dlab,

    // ---- Configuración: FCR -------------------------------------------------
    output logic        fifo_en,
    output logic [1:0]  rxfiftl,
    output logic        dmamode1,
    output logic        rxclr,
    output logic        txclr,

    // ---- Configuración: MCR -------------------------------------------------
    output logic        afe,
    output logic        rts_en,
    output logic        loop,
    output logic        out1,
    output logic        out2,

    // ---- Divisor y modo de muestreo -----------------------------------------
    output logic [15:0] divisor,
    output logic        osm_sel,

    // ---- PWREMU_MGMT --------------------------------------------------------
    output logic        utrst,
    output logic        urrst,
    output logic        free,

    // ---- IER ----------------------------------------------------------------
    output logic        erbi,
    output logic        etbei,
    output logic        elsi,
    output logic        edssi
);

    // =========================================================================
    // 1. MAPA DE DIRECCIONES (addr[5:2] = offset / 4, tabla 3-1 de la guía de TI)
    // =========================================================================
    localparam logic [3:0] A_RBR_THR = 4'h0;   // 00h: RBR (lee) / THR (escribe) / DLL si DLAB=1
    localparam logic [3:0] A_IER     = 4'h1;   // 04h: IER / DLH si DLAB=1
    localparam logic [3:0] A_IIR_FCR = 4'h2;   // 08h: IIR (lee) / FCR (escribe)
    localparam logic [3:0] A_LCR     = 4'h3;   // 0Ch
    localparam logic [3:0] A_MCR     = 4'h4;   // 10h
    localparam logic [3:0] A_LSR     = 4'h5;   // 14h: solo lectura
    localparam logic [3:0] A_MSR     = 4'h6;   // 18h: (P6) se lee como 0
    localparam logic [3:0] A_SCR     = 4'h7;   // 1Ch
    localparam logic [3:0] A_DLL     = 4'h8;   // 20h
    localparam logic [3:0] A_DLH     = 4'h9;   // 24h
    localparam logic [3:0] A_REVID1  = 4'hA;   // 28h: (P6) se lee como 0
    localparam logic [3:0] A_REVID2  = 4'hB;   // 2Ch: (P6) se lee como 0
    localparam logic [3:0] A_PWREMU  = 4'hC;   // 30h
    localparam logic [3:0] A_MDR     = 4'hD;   // 34h

    // (P5) bit de wdata donde va cada campo de PWREMU_MGMT
    localparam integer PW_FREE  = 0;
    localparam integer PW_URRST = 5;
    localparam integer PW_UTRST = 6;

    // =========================================================================
    // 2. REGISTROS (todos valen 0 tras el reset)
    // =========================================================================
    logic [7:0] lcr_q;                       // [7]DLAB [6]BC [5]SP [4]EPS [3]PEN [2]STB [1:0]WLS
    logic       afe_q, loop_q, out2_q, out1_q, rts_q;   // MCR bits 5,4,3,2,1
    logic [3:0] ier_q;                       // [3]EDSSI [2]ELSI [1]ETBEI [0]ERBI
    logic [7:0] dll_q, dlh_q, scr_q;
    logic       fifo_en_q, dmamode1_q;
    logic [1:0] rxfiftl_q;
    logic       utrst_q, urrst_q, free_q;
    logic       osm_sel_q;
    logic       oe_lat;                      // (P4) OE retenido
    logic [1:0] wait_cnt;                    // estados de espera: 0, 1, 2
    logic       rxclr_q, txclr_q;            // (P7) pulsos registrados

    logic dlab_q;
    assign dlab_q = lcr_q[7];

    // =========================================================================
    // 3. DECODIFICACIÓN DEL ACCESO
    // =========================================================================
    logic bus_wr, bus_rd;
    assign bus_wr = sel & wr;                // escritura dirigida a este UART
    assign bus_rd = sel & rd;                // lectura dirigida a este UART

    logic sel_dll, sel_dlh;                  // DLL/DLH: dirección propia o compartida con DLAB=1
    assign sel_dll = (addr == A_DLL) | (dlab_q & (addr == A_RBR_THR));
    assign sel_dlh = (addr == A_DLH) | (dlab_q & (addr == A_IER));

    // =========================================================================
    // 4. ESTADOS DE ESPERA (P2): escribir DLL/DLH = 2 esperas
    //    ciclo 0: ready=0 | ciclo 1: ready=0 | ciclo 2: ready=1 (se guarda)
    // =========================================================================
    logic dl_wr_req, wr_en;
    assign dl_wr_req = bus_wr & (sel_dll | sel_dlh);
    assign ready     = ~dl_wr_req | (wait_cnt == 2'd2);
    assign wr_en     = bus_wr & ready;       // la escritura "se ejecuta" solo con ready=1

    always_ff @(posedge clk) begin
        if (rst)
            wait_cnt <= 2'd0;
        else if (dl_wr_req && wait_cnt != 2'd2)
            wait_cnt <= wait_cnt + 2'd1;
        else
            wait_cnt <= 2'd0;
    end

    // =========================================================================
    // 5. UNA SEÑAL DE ESCRITURA POR REGISTRO
    // =========================================================================
    logic wr_thr, wr_ier, wr_fcr, wr_lcr, wr_mcr, wr_scr, wr_dll, wr_dlh, wr_pwr, wr_mdr;
    assign wr_thr = wr_en & (addr == A_RBR_THR) & ~dlab_q;
    assign wr_ier = wr_en & (addr == A_IER)     & ~dlab_q;
    assign wr_fcr = wr_en & (addr == A_IIR_FCR);
    assign wr_lcr = wr_en & (addr == A_LCR);
    assign wr_mcr = wr_en & (addr == A_MCR);
    assign wr_scr = wr_en & (addr == A_SCR);
    assign wr_dll = wr_en & sel_dll;
    assign wr_dlh = wr_en & sel_dlh;
    assign wr_pwr = wr_en & (addr == A_PWREMU);
    assign wr_mdr = wr_en & (addr == A_MDR);

    // =========================================================================
    // 6. PULSOS DE ACCESO (P3)
    // =========================================================================
    assign thr_wr = wr_thr;
    assign fcr_wr = wr_fcr;
    assign rbr_rd = bus_rd & (addr == A_RBR_THR) & ~dlab_q;
    assign iir_rd = bus_rd & (addr == A_IIR_FCR);
    assign lsr_rd = bus_rd & (addr == A_LSR);

    // (P7) Pulsos de limpieza de FIFO, registrados: salen un ciclo después y sin glitches.
    // Solo si en esa escritura FIFOEN=1 (la guía: sin FIFOEN el resto del FCR no se programa).
    always_ff @(posedge clk) begin
        if (rst) begin
            rxclr_q <= 1'b0;
            txclr_q <= 1'b0;
        end else begin
            rxclr_q <= wr_fcr & wdata[0] & wdata[1];
            txclr_q <= wr_fcr & wdata[0] & wdata[2];
        end
    end
    assign rxclr = rxclr_q;
    assign txclr = txclr_q;

    // =========================================================================
    // 7. ESCRITURA DE REGISTROS (síncrona)
    // =========================================================================
    always_ff @(posedge clk) begin
        if (rst) begin
            lcr_q <= 8'h00;
            afe_q <= 1'b0; loop_q <= 1'b0; out2_q <= 1'b0; out1_q <= 1'b0; rts_q <= 1'b0;
            ier_q <= 4'h0;
            dll_q <= 8'h00; dlh_q <= 8'h00; scr_q <= 8'h00;
            fifo_en_q <= 1'b0; rxfiftl_q <= 2'b00; dmamode1_q <= 1'b0;
            utrst_q <= 1'b0; urrst_q <= 1'b0; free_q <= 1'b0;
            osm_sel_q <= 1'b0;
        end else begin
            if (wr_lcr) lcr_q <= wdata;
            if (wr_mcr) begin
                afe_q <= wdata[5]; loop_q <= wdata[4]; out2_q <= wdata[3];
                out1_q <= wdata[2]; rts_q <= wdata[1];
            end
            if (wr_ier) ier_q <= wdata[3:0];
            if (wr_dll) dll_q <= wdata;
            if (wr_dlh) dlh_q <= wdata;
            if (wr_scr) scr_q <= wdata;
            if (wr_fcr) begin
                fifo_en_q <= wdata[0];                 // FIFOEN se guarda siempre
                if (wdata[0]) begin                    // el resto, solo si FIFOEN=1
                    rxfiftl_q  <= wdata[7:6];
                    dmamode1_q <= wdata[3];
                end
            end
            if (wr_pwr) begin                          // (P5)
                free_q  <= wdata[PW_FREE];
                urrst_q <= wdata[PW_URRST];
                utrst_q <= wdata[PW_UTRST];
            end
            if (wr_mdr) osm_sel_q <= wdata[0];
        end
    end

    // =========================================================================
    // 8. BANDERA OE RETENIDA (P4): el receptor entrega OE como pulso de 1 ciclo
    // =========================================================================
    always_ff @(posedge clk) begin
        if (rst) oe_lat <= 1'b0;
        else     oe_lat <= OE | (oe_lat & ~lsr_rd);   // se activa con OE, se borra al leer LSR
    end

    logic oe_eff;
    assign oe_eff = (OE_STICKY != 0) ? (OE | oe_lat) : OE;

    // =========================================================================
    // 9. LECTURA (P3, combinacional)
    // =========================================================================
    logic [7:0] lsr_val;                     // (P8) PE/FE/BI solo valen si hay dato (DR=1)
    assign lsr_val = {RXFIFOE, TEMT, THRE, BI & DR, FE & DR, PE & DR, oe_eff, DR};

    logic [7:0] rdata_b;
    always_comb begin
        rdata_b = 8'h00;
        if (bus_rd) begin
            case (addr)
                A_RBR_THR: rdata_b = dlab_q ? dll_q : rbr_data;
                A_IER:     rdata_b = dlab_q ? dlh_q : {4'b0000, ier_q};
                A_IIR_FCR: rdata_b = iir_data;
                A_LCR:     rdata_b = lcr_q;
                A_MCR:     rdata_b = {2'b00, afe_q, loop_q, out2_q, out1_q, rts_q, 1'b0};
                A_LSR:     rdata_b = lsr_val;
                A_MSR:     rdata_b = 8'h00;                                     // (P6)
                A_SCR:     rdata_b = scr_q;
                A_DLL:     rdata_b = dll_q;
                A_DLH:     rdata_b = dlh_q;
                A_REVID1:  rdata_b = 8'h00;                                     // (P6)
                A_REVID2:  rdata_b = 8'h00;                                     // (P6)
                A_PWREMU:  rdata_b = {1'b0, utrst_q, urrst_q, 4'b1111, free_q}; // reservados = 1
                A_MDR:     rdata_b = {7'b0000000, osm_sel_q};
                default:   rdata_b = 8'h00;
            endcase
        end
    end
    assign rdata = {24'h000000, rdata_b};

    // =========================================================================
    // 10. SALIDAS DE CONFIGURACIÓN (cables desde los registros)
    // =========================================================================
    assign wls  = lcr_q[1:0];  assign stb = lcr_q[2];  assign pen = lcr_q[3];
    assign eps  = lcr_q[4];    assign sp  = lcr_q[5];  assign bc  = lcr_q[6];
    assign dlab = dlab_q;

    assign fifo_en = fifo_en_q;  assign rxfiftl = rxfiftl_q;  assign dmamode1 = dmamode1_q;

    assign afe = afe_q;  assign rts_en = rts_q;  assign loop = loop_q;
    assign out1 = out1_q; assign out2 = out2_q;

    assign divisor = {dlh_q, dll_q};
    assign osm_sel = osm_sel_q;

    assign utrst = utrst_q;  assign urrst = urrst_q;  assign free = free_q;

    assign erbi = ier_q[0];  assign etbei = ier_q[1];  assign elsi = ier_q[2];  assign edssi = ier_q[3];

`ifdef FORMAL
    // =========================================================================
    // VERIFICACIÓN FORMAL
    //   assume -> ENTRADAS (cómo se comporta el entorno)
    //   assert -> SALIDAS y ESTADOS (lo que promete este bloque)
    //   cover  -> comprobar que los casos importantes SÍ ocurren (evita pasar "en vacío")
    // =========================================================================

    // --- Preparación: el primer ciclo está en reset y $past es válido después ---
    logic f_past_valid = 1'b0;
    always_ff @(posedge clk) f_past_valid <= 1'b1;
    always @* if (!f_past_valid) assume (rst);

    // --- ASSUME (entradas) -------------------------------------------------------
    // A1: el bus nunca lee y escribe a la vez.
    always @* assume (!(rd && wr));

    // --- Modelos auxiliares (solo para formal) ----------------------------------
    // Escritura "ejecutada" (con ready=1), expresada solo con puertos de entrada.
    logic f_wr_ok;
    assign f_wr_ok = sel && wr && ready;
    // Acceso de escritura al divisor, expresado solo con puertos (independiente del RTL).
    logic f_dl_access;
    assign f_dl_access = sel && wr &&
        ((addr == A_DLL) || (addr == A_DLH) ||
         (dlab && ((addr == A_RBR_THR) || (addr == A_IER))));

    // =========================================================================
    // GRUPO 1: DECODIFICACIÓN Y PULSOS DE ACCESO
    // =========================================================================
    always @* if (f_past_valid) begin
        // Cada pulso ocurre EXACTAMENTE cuando hay un acceso válido a su dirección.
        assert (rbr_rd == (sel && rd && addr == A_RBR_THR && !dlab));
        assert (thr_wr == (sel && wr && addr == A_RBR_THR && !dlab));
        assert (fcr_wr == (sel && wr && addr == A_IIR_FCR));
        assert (iir_rd == (sel && rd && addr == A_IIR_FCR));
        assert (lsr_rd == (sel && rd && addr == A_LSR));
        // Regla del DLAB: con DLAB=1 la dirección 0 no genera pulsos de datos.
        if (dlab && addr == A_RBR_THR) assert (!rbr_rd && !thr_wr);
    end

    // A lo sumo un pulso de acceso por ciclo (usa A1).
    logic [2:0] f_npulsos;
    assign f_npulsos = rbr_rd + thr_wr + fcr_wr + iir_rd + lsr_rd;
    always @* if (f_past_valid) assert (f_npulsos <= 3'd1);

    // =========================================================================
    // GRUPO 2: ESTADOS DE ESPERA (ready)
    // =========================================================================
    always @* if (f_past_valid) begin
        assert (wait_cnt <= 2'd2);                          // el contador nunca pasa de 2
        assert (dl_wr_req == f_dl_access);                  // decodificación de DLL/DLH
        if (!f_dl_access)               assert (ready);     // otros accesos no esperan
        if (f_dl_access && wait_cnt < 2) assert (!ready);   // esperas 1 y 2
        if (f_dl_access && wait_cnt == 2) assert (ready);   // al tercer ciclo termina
    end

    always @(posedge clk) if (f_past_valid) begin
        if ($past(rst))
            assert (wait_cnt == 2'd0);
        else if ($past(f_dl_access) && $past(wait_cnt) != 2'd2)
            assert (wait_cnt == $past(wait_cnt) + 2'd1);    // cuenta 0 -> 1 -> 2
        else
            assert (wait_cnt == 2'd0);                      // terminó o se retiró la petición
    end

    // =========================================================================
    // GRUPO 3: REGISTROS (reset, escritura correcta y retención)
    //   Un registro solo cambia si hubo una escritura ejecutada a SU dirección.
    // =========================================================================
    always @(posedge clk) if (f_past_valid) begin
        // ---- LCR ----
        if ($past(rst))
            assert ({dlab, bc, sp, eps, pen, stb, wls} == 8'h00);
        else if ($past(f_wr_ok && addr == A_LCR))
            assert ({dlab, bc, sp, eps, pen, stb, wls} == $past(wdata));
        else
            assert ({dlab, bc, sp, eps, pen, stb, wls} == $past({dlab, bc, sp, eps, pen, stb, wls}));

        // ---- MCR (bits 5..1) ----
        if ($past(rst))
            assert ({afe, loop, out2, out1, rts_en} == 5'd0);
        else if ($past(f_wr_ok && addr == A_MCR))
            assert ({afe, loop, out2, out1, rts_en} == $past(wdata[5:1]));
        else
            assert ({afe, loop, out2, out1, rts_en} == $past({afe, loop, out2, out1, rts_en}));

        // ---- IER (solo con DLAB=0) ----
        if ($past(rst))
            assert ({edssi, elsi, etbei, erbi} == 4'd0);
        else if ($past(f_wr_ok && addr == A_IER && !dlab))
            assert ({edssi, elsi, etbei, erbi} == $past(wdata[3:0]));
        else
            assert ({edssi, elsi, etbei, erbi} == $past({edssi, elsi, etbei, erbi}));

        // ---- DLL (dirección propia, o 0h con DLAB=1) ----
        if ($past(rst))
            assert (divisor[7:0] == 8'h00);
        else if ($past(f_wr_ok && (addr == A_DLL || (addr == A_RBR_THR && dlab))))
            assert (divisor[7:0] == $past(wdata));
        else
            assert (divisor[7:0] == $past(divisor[7:0]));

        // ---- DLH (dirección propia, o 4h con DLAB=1) ----
        if ($past(rst))
            assert (divisor[15:8] == 8'h00);
        else if ($past(f_wr_ok && (addr == A_DLH || (addr == A_IER && dlab))))
            assert (divisor[15:8] == $past(wdata));
        else
            assert (divisor[15:8] == $past(divisor[15:8]));

        // ---- SCR ----
        if ($past(rst))
            assert (scr_q == 8'h00);
        else if ($past(f_wr_ok && addr == A_SCR))
            assert (scr_q == $past(wdata));
        else
            assert (scr_q == $past(scr_q));

        // ---- FCR: FIFOEN siempre; RXFIFTL y DMAMODE1 solo si FIFOEN=1 ----
        if ($past(rst))
            assert (!fifo_en && rxfiftl == 2'b00 && !dmamode1);
        else if ($past(f_wr_ok && addr == A_IIR_FCR)) begin
            assert (fifo_en == $past(wdata[0]));
            if ($past(wdata[0])) begin
                assert (rxfiftl  == $past(wdata[7:6]));
                assert (dmamode1 == $past(wdata[3]));
            end else begin
                assert (rxfiftl  == $past(rxfiftl));
                assert (dmamode1 == $past(dmamode1));
            end
        end else
            assert ({fifo_en, rxfiftl, dmamode1} == $past({fifo_en, rxfiftl, dmamode1}));

        // ---- PWREMU_MGMT (P5) ----
        if ($past(rst))
            assert (!utrst && !urrst && !free);
        else if ($past(f_wr_ok && addr == A_PWREMU))
            assert ({utrst, urrst, free} ==
                    {$past(wdata[PW_UTRST]), $past(wdata[PW_URRST]), $past(wdata[PW_FREE])});
        else
            assert ({utrst, urrst, free} == $past({utrst, urrst, free}));

        // ---- MDR ----
        if ($past(rst))
            assert (!osm_sel);
        else if ($past(f_wr_ok && addr == A_MDR))
            assert (osm_sel == $past(wdata[0]));
        else
            assert (osm_sel == $past(osm_sel));
    end

    // =========================================================================
    // GRUPO 4: PULSOS DE LIMPIEZA DE FIFO (rxclr, txclr)
    //   Salen UN ciclo después de escribir FCR, solo con FIFOEN=1, y no se quedan.
    // =========================================================================
    always @(posedge clk) if (f_past_valid) begin
        if ($past(rst)) begin
            assert (!rxclr && !txclr);
        end else begin
            assert (rxclr == $past(f_wr_ok && addr == A_IIR_FCR && wdata[0] && wdata[1]));
            assert (txclr == $past(f_wr_ok && addr == A_IIR_FCR && wdata[0] && wdata[2]));
        end
    end

    // =========================================================================
    // GRUPO 5: BANDERA OE RETENIDA (el sticky_flag bien hecho)
    //   OE llega como pulso; debe quedar activa hasta que se lea el LSR.
    // =========================================================================
    always @(posedge clk) if (f_past_valid && OE_STICKY != 0) begin
        if ($past(rst))                 assert (!oe_lat);
        else if ($past(OE))             assert (oe_lat);                 // un pulso nunca se pierde
        else if ($past(lsr_rd))         assert (!oe_lat);                // leer LSR la borra
        else                            assert (oe_lat == $past(oe_lat)); // si no, se mantiene
    end

    // =========================================================================
    // GRUPO 6: LECTURA (rdata)
    // =========================================================================
    always @* if (f_past_valid) begin
        assert (rdata[31:8] == 24'd0);                           // bits altos siempre 0
        if (!(sel && rd)) assert (rdata == 32'd0);               // sin lectura, rdata = 0
        if (sel && rd) begin
            case (addr)
                A_RBR_THR: assert (rdata[7:0] == (dlab ? divisor[7:0] : rbr_data));
                A_IER:     assert (rdata[7:0] == (dlab ? divisor[15:8]
                                                        : {4'b0000, edssi, elsi, etbei, erbi}));
                A_IIR_FCR: assert (rdata[7:0] == iir_data);
                A_LCR:     assert (rdata[7:0] == {dlab, bc, sp, eps, pen, stb, wls});
                A_MCR:     assert (rdata[7:0] == {2'b00, afe, loop, out2, out1, rts_en, 1'b0});
                A_LSR:     assert (rdata[7:0] == {RXFIFOE, TEMT, THRE, BI & DR, FE & DR, PE & DR,
                                                  (OE_STICKY != 0) ? (OE | oe_lat) : OE, DR});
                A_MSR:     assert (rdata[7:0] == 8'h00);
                A_SCR:     assert (rdata[7:0] == scr_q);
                A_DLL:     assert (rdata[7:0] == divisor[7:0]);
                A_DLH:     assert (rdata[7:0] == divisor[15:8]);
                A_REVID1:  assert (rdata[7:0] == 8'h00);
                A_REVID2:  assert (rdata[7:0] == 8'h00);
                A_PWREMU:  assert (rdata[7:0] == {1'b0, utrst, urrst, 4'b1111, free});
                A_MDR:     assert (rdata[7:0] == {7'b0000000, osm_sel});
                default:   assert (rdata[7:0] == 8'h00);         // direcciones Eh y Fh: sin registro
            endcase
        end
    end

    // =========================================================================
    // COVER: los escenarios importantes SÍ se pueden alcanzar
    // =========================================================================
    always @(posedge clk) begin
        cover (f_past_valid && thr_wr);                                   // se escribe THR
        cover (f_past_valid && rbr_rd);                                   // se lee RBR
        cover (f_past_valid && f_dl_access && ready);                     // termina una escritura al divisor
        cover (f_past_valid && f_dl_access && !ready && wait_cnt == 2'd1);// segunda espera
        cover (f_past_valid && rxclr && txclr);                           // ambos clear a la vez
        cover (f_past_valid && lsr_rd && oe_lat);                         // se lee LSR con OE retenido
        cover (f_past_valid && lsr_rd && PE && DR);                       // LSR con error de paridad
        cover (f_past_valid && wls == 2'b11 && pen && utrst && urrst);    // configuración típica activa
    end
`endif

endmodule
