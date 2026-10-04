`timescale 1ns/10ps 
module Encoder_tb; 

    // Inputs and outputs 
        reg [6:0] Comp_tb;            // Comparators outputs 
        reg Samp_tb;                  // Sampling signal 
        reg clk_tb;                   // Clock 
        wire [2:0] Dout_tb;           // Digital ADC 
        output wire eoc_tb;           // End of conversion 


    // Instance of the Encoder module 
    Encoder uut (
        .Comp(Comp_tb), 
        .Samp(Samp_tb), 
        .clk(clk_tb), 
        .Dout(Dout_tb), 
        .eoc(eoc_tb) 
    );

    // Clock generation
        initial clk_tb = 0;     
        always #5 clk_tb = ~ clk_tb; // Clock period = 10 ns 

    // Stimulus block     
    initial begin
        $dumpfile("Waveforms.vcd"); // VCD file for waveform visualization 
        $dumpvars(0, Encoder_tb);    // Dump all variables in the testbench   

        // Test Comp_tb values         
        #10 Samp_tb = 0; Comp_tb = 7'b0000000; // Dout => 3'b001 
        #10 Samp_tb = 0; Comp_tb = 7'b0000001; // Dout => 3'b000 
        #10 Samp_tb = 0; Comp_tb = 7'b0000011; // Dout => 3'b010 
        #10 Samp_tb = 0; Comp_tb = 7'b0000111; // Dout => 3'b011 
        #10 Samp_tb = 0; Comp_tb = 7'b0001111; // Dout => 3'b100 
        #10 Samp_tb = 0; Comp_tb = 7'b0011111; // Dout => 3'b101 
        #10 Samp_tb = 0; Comp_tb = 7'b0111111; // Dout => 3'b110 
        #10 Samp_tb = 0; Comp_tb = 7'b1111111; // Dout => 3'b111
        #10 Samp_tb = 0; Comp_tb = 7'b1111101; // Adicional
        #10 Samp_tb = 0; Comp_tb = 7'b1110001; // Adicional             
        #10 Samp_tb = 1; Comp_tb = 7'b0000011;          
        #10 Samp_tb = 0; Comp_tb = 7'b0000011;                     
        
        // End simulation         
        #10 $finish;     
    end

    // Monitor outputs     
        initial begin         
            $monitor("Time: %0t | Samp: %b | Comp: %b | Dout: %b | eoc: %b",                   
            $time, Samp_tb, Comp_tb, Dout_tb, eoc_tb);     
        end  
endmodule 