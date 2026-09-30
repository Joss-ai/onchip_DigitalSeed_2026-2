class test;
    environment e0;

    function new();
        e0 = new();
    endfunction

    // Punto de configuracion especifico de este test: aqui decidimos
    // cuantas transacciones queremos correr en esta corrida en particular.
    // task configure(int n = 20);
    //    e0.num_transactions = n;
    // endtask

    task run();
        e0.run();
    endtask
    
endclass