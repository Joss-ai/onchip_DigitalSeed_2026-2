`timescale 1ns/1ps
`default_nettype none

module tb_uart_tx_ctrl;

  logic       clk = 1'b0, rst = 1'b1;
  logic       bclk_tick = 1'b0;
  logic       osm_sel = 1'b0;
  logic [7:0] tx_data = 8'h00;
  logic       tx_empty = 1'b1;
  logic [1:0] wls = 2'b11;
  logic       pen = 1'b0, eps = 1'b0, sp = 1'b0, stb = 1'b0, bc = 1'b0;
  logic       utrst = 1'b1, cts_n = 1'b0, afe = 1'b0, loop = 1'b0;
  wire        txd, tx_pop, tsr_empty, tx_serial_loop, tx_busy;

  uart_tx_ctrl dut (.*);

  always #5 clk = ~clk;

  int errors = 0;
  task automatic fail(string msg);
    errors++;
    $display("[%0t] ERROR: %s", $time, msg);
  endtask

  int tick_div  = 1;
  bit tick_rand = 1'b0;
  int tdiv_cnt  = 0;
  always @(posedge clk) begin
    if (tick_rand) begin
      bclk_tick <= ($urandom_range(0, 2) == 0);
    end else if (tdiv_cnt >= tick_div - 1) begin
      tdiv_cnt  <= 0;
      bclk_tick <= 1'b1;
    end else begin
      tdiv_cnt  <= tdiv_cnt + 1;
      bclk_tick <= 1'b0;
    end
  end

  logic [7:0] fifo[$];
  logic [7:0] push_req[$];
  int         pops = 0;
  always @(posedge clk) begin
    if (tx_pop) begin
      if (fifo.size() == 0) fail("tx_pop con el FIFO vacío");
      else begin
        if (tx_data !== fifo[0]) fail("tx_data no es la cabeza del FIFO");
        void'(fifo.pop_front());
      end
      pops++;
    end
    while (push_req.size() > 0) fifo.push_back(push_req.pop_front());
    tx_empty <= (fifo.size() == 0);
    tx_data  <= (fifo.size() == 0) ? 8'($urandom) : fifo[0];
  end

  task automatic push(input logic [7:0] b);
    push_req.push_back(b);
  endtask

  typedef struct packed {
    logic [7:0] data;
    logic [1:0] wls;
    logic       pen, eps, sp, stb, osm;
  } frame_t;
  frame_t expq[$];

  always @(posedge clk)
    if (tx_pop) begin
      frame_t f;
      f.data = tx_data; f.wls = wls; f.pen = pen; f.eps = eps;
      f.sp   = sp;      f.stb = stb; f.osm = osm_sel;
      expq.push_back(f);
    end

  function automatic void build_wave(input frame_t f, ref bit w[$]);
    int n   = f.osm ? 13 : 16;
    int nd  = 5 + int'(f.wls);
    int nst = !f.stb ? n : (f.wls == 2'b00 ? (f.osm ? 19 : 24) : 2 * n);
    bit p;
    logic [7:0] m = 8'hFF >> (3 - f.wls);
    w.delete();
    repeat (n) w.push_back(1'b0);
    for (int i = 0; i < nd; i++) repeat (n) w.push_back(f.data[i]);
    if (f.pen) begin
      if (f.sp) p = !f.eps;
      else      p = (^(f.data & m)) ^ !f.eps;
      repeat (n) w.push_back(p);
    end
    repeat (nst) w.push_back(1'b1);
  endfunction

  bit  mon_on   = 1'b1;
  bit  in_frame = 1'b0;
  bit  wave[$];
  int  widx = 0;
  int  frames_ok = 0, back2back = 0, last_end_tick = -100, tick_no = 0;
  frame_t curf;

  always @(posedge clk) begin
    if (!loop && txd !== tx_serial_loop) fail("txd != tx_serial_loop sin loopback");
    if (loop && txd !== 1'b1)            fail("txd != 1 en loopback");
    if (rst || !utrst || !mon_on) begin
      in_frame <= 1'b0;
    end else if (bclk_tick) begin
      tick_no <= tick_no + 1;
      if (!in_frame) begin
        if (tx_serial_loop == 1'b0) begin
          if (expq.size() == 0) fail("start bit sin tx_pop previo");
          else begin
            curf = expq.pop_front();
            build_wave(curf, wave);
            widx     <= 1;
            in_frame <= 1'b1;
            if (tick_no == last_end_tick + 1) back2back++;
          end
        end
      end else begin
        if (tx_serial_loop !== wave[widx])
          fail($sformatf("dato 0x%02h: tick %0d de la trama vale %0b, esperado %0b",
                         curf.data, widx, tx_serial_loop, wave[widx]));
        if (widx == wave.size() - 1) begin
          in_frame      <= 1'b0;
          frames_ok++;
          last_end_tick <= tick_no;
        end
        widx <= widx + 1;
      end
    end

    if (mon_on && utrst && tsr_empty && in_frame) fail("tsr_empty=1 en mitad de una trama");
  end

  task automatic set_cfg(input int w, input int par_mode, input int s, input int o);
    @(negedge clk);
    wls = 2'(w); stb = 1'(s); osm_sel = 1'(o);
    case (par_mode)
      0: begin pen = 0; eps = 0; sp = 0; end
      1: begin pen = 1; eps = 0; sp = 0; end
      2: begin pen = 1; eps = 1; sp = 0; end
      3: begin pen = 1; eps = 0; sp = 1; end
      default: begin pen = 1; eps = 1; sp = 1; end
    endcase
  endtask

  task automatic wait_idle(input int timeout = 200000);
    int t = 0;

    while (!(fifo.size() == 0 && push_req.size() == 0 && tx_empty && tsr_empty && !in_frame)) begin
      @(posedge clk); t++;
      if (t > timeout) begin fail("timeout esperando IDLE"); return; end
    end
    repeat (3) @(posedge clk);
    if (expq.size() != 0) fail($sformatf("quedaron %0d tramas sin ver en la línea", expq.size()));
  endtask

  int cfg_seen[2][4][5][2];

  task automatic t_sweep();
    $display("-- T1: barrido de las 80 configuraciones (3 bytes seguidos cada una)");
    for (int o = 0; o < 2; o++)
      for (int w = 0; w < 4; w++)
        for (int p = 0; p < 5; p++)
          for (int s = 0; s < 2; s++) begin
            set_cfg(w, p, s, o);
            tick_div  = $urandom_range(1, 3);
            tick_rand = ($urandom_range(0, 4) == 0);
            push(8'($urandom)); push(8'($urandom)); push(8'($urandom));
            wait_idle();
            cfg_seen[o][w][p][s]++;
          end
    tick_rand = 1'b0; tick_div = 1;
  endtask

  task automatic t_corners();
    $display("-- T2: valores extremos 00 FF 55 AA 80 01 en 8E2 y 5O1.5");
    set_cfg(3, 2, 1, 0);
    push(8'h00); push(8'hFF); push(8'h55); push(8'hAA); push(8'h80); push(8'h01);
    wait_idle();
    set_cfg(0, 1, 1, 1);
    push(8'h00); push(8'hFF); push(8'h55); push(8'hAA); push(8'h80); push(8'h01);
    wait_idle();
  endtask

  bit chaos_on = 1'b0;
  always @(negedge clk)
    if (chaos_on) begin
      wls = 2'($urandom); pen = 1'($urandom); eps = 1'($urandom);
      sp  = 1'($urandom); stb = 1'($urandom); osm_sel = 1'($urandom);
    end

  task automatic t_lcr_chaos();
    $display("-- T3: el LCR cambia en cada ciclo; cada trama debe usar el LCR del tx_pop");
    for (int i = 0; i < 40; i++) push(8'($urandom));
    chaos_on = 1'b1;
    wait_idle();
    chaos_on = 1'b0;
  endtask

  task automatic t_loopback();
    $display("-- T4: loopback: la trama va por tx_serial_loop y txd se queda en 1");
    set_cfg(3, 0, 0, 0);
    @(negedge clk) loop = 1'b1;
    push(8'h3C); push(8'hA5);
    wait_idle();
    @(negedge clk) loop = 1'b0;
  endtask

  task automatic t_break();
    int t;
    $display("-- T5: break a mitad de trama: la línea a 0, la FSM sigue y termina");
    set_cfg(3, 0, 0, 0);
    push(8'h5A);
    wait (tx_pop); @(negedge clk);
    repeat (16 * 3) @(posedge clk);
    @(negedge clk) begin mon_on = 1'b0; bc = 1'b1; end
    for (t = 0; t < 40; t++) begin
      @(posedge clk);
      if (txd !== 1'b0 || tx_serial_loop !== 1'b0) fail("break no fuerza la línea a 0");
    end
    if (tsr_empty) fail("la FSM se detuvo durante el break");
    @(negedge clk) bc = 1'b0;
    while (!tsr_empty) @(posedge clk);
    expq.delete();
    @(negedge clk) mon_on = 1'b1;
    if (txd !== 1'b1) fail("línea no vuelve a 1 tras break");
  endtask

  task automatic t_autocts();
    int p0;
    $display("-- T6: auto-CTS: con CTS#=1 no arranca nada; si sube a mitad, la trama termina");
    set_cfg(3, 0, 0, 0);
    @(negedge clk) begin afe = 1'b1; cts_n = 1'b1; end
    repeat (4) @(posedge clk);
    p0 = pops;
    push(8'h11); push(8'h22); push(8'h33);
    repeat (2000) @(posedge clk);
    if (pops != p0) fail("hubo tx_pop con CTS# bloqueando");
    if (!tsr_empty) fail("el TSR arrancó con CTS# bloqueando");
    @(negedge clk) cts_n = 1'b0;
    wait (tx_pop); @(negedge clk);
    repeat (16 * 4) @(posedge clk);
    @(negedge clk) cts_n = 1'b1;
    while (!tsr_empty) @(posedge clk);
    p0 = pops;
    repeat (1500) @(posedge clk);
    if (pops != p0) fail("arrancó otro carácter con CTS# bloqueando");
    if (fifo.size() != 2) fail($sformatf("FIFO debería tener 2 bytes, tiene %0d", fifo.size()));
    @(negedge clk) cts_n = 1'b0;
    wait_idle();
    @(negedge clk) afe = 1'b0;
  endtask

  task automatic t_utrst();
    $display("-- T7: UTRST=0 a mitad de trama: IDLE, txd=1, sin pops; luego sigue con el resto");
    set_cfg(3, 2, 0, 0);
    push(8'hC3); push(8'h7E);
    wait (tx_pop); @(negedge clk);
    repeat (16 * 5) @(posedge clk);
    @(negedge clk) utrst = 1'b0;
    repeat (2) @(posedge clk);
    if (!tsr_empty || txd !== 1'b1) fail("UTRST=0 no devuelve a IDLE con txd=1");
    repeat (300) @(posedge clk);
    if (!tsr_empty || tx_pop) fail("actividad con UTRST=0");
    void'(expq.pop_front());
    @(negedge clk) utrst = 1'b1;
    wait_idle();
  endtask

  initial begin
    if ($test$plusargs("trace")) begin
      $dumpfile("uart_tx.vcd");
      $dumpvars(0, tb_uart_tx_ctrl);
    end
    repeat (5) @(posedge clk);
    @(negedge clk) rst = 1'b0;
    repeat (5) @(posedge clk);

    t_sweep();
    t_corners();
    t_lcr_chaos();
    t_loopback();
    t_break();
    t_autocts();
    t_utrst();

    begin
      int missing = 0;
      foreach (cfg_seen[o, w, p, s]) if (cfg_seen[o][w][p][s] == 0) missing++;
      $display("");
      $display("=============== RESUMEN ===============");
      $display(" tramas verificadas tick a tick : %0d", frames_ok);
      $display(" tramas consecutivas sin idle   : %0d", back2back);
      $display(" tx_pop totales                 : %0d", pops);
      $display(" configuraciones sin cubrir     : %0d de 80", missing);
      $display(" errores                        : %0d", errors);
      $display("=======================================");
      if (errors == 0 && missing == 0 && back2back > 0) $display("PASS");
      else                                             $display("FAIL");
    end
    $finish;
  end

  initial begin
    #50ms;
    $display("FAIL: timeout global");
    $finish;
  end
endmodule

`default_nettype wire
