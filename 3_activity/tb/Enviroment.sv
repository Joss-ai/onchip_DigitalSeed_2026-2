class environment;

    // ---- Handles a los componentes (los crean tus compañeros) ----
    driver      d0;
    Monitor     m0;
    generator   g0;
    scoreboard  s0;

    // ---- Canales de comunicación entre componentes ----
    mailbox #(fifo_transaction) drv_mbx;   // Generator  -> Driver
    mailbox #(fifo_transaction) scb_mbx;   // Monitor    -> Scoreboard
    event   drv_done;  // Driver     -> Generator (sincronizacion)

    // ---- Interfaz virtual hacia el DUT ----
    virtual fifo_if vif;

    // Numero de transacciones a generar (configurable desde el Test)
    int num_transactions = 20;

    function new();
        // 1) Crear cada componente
        d0 = new();
        m0 = new();
        g0 = new();
        s0 = new();

        // 2) Crear los canales de comunicacion (objetos compartidos)
        drv_mbx = new();
        scb_mbx = new();

        // 3) Conectar Generator <-> Driver con el MISMO mailbox
        d0.drv_mbx = drv_mbx;
        g0.drv_mbx = drv_mbx;

        // 4) Conectar Driver <-> Generator con el MISMO evento
        d0.drv_done = drv_done;
        g0.drv_done = drv_done;

        // 5) Conectar Monitor <-> Scoreboard con el MISMO mailbox
        m0.scb_mbx = scb_mbx;
        s0.scb_mbx = scb_mbx;

        // 6) Pasar el numero de transacciones al generador
        g0.num = num_transactions;
    endfunction

    task run();
        d0.vif = vif;
        m0.vif = vif;

        fork
            g0.run();
            d0.run();
            m0.run();
            s0.run();
        join_any
    endtask
    
endclass