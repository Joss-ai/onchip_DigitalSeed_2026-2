module Encoder (Samp,
    clk,
    eoc,
    Comp,
    Dout);
 input Samp;
 input clk;
 output eoc;
 input [6:0] Comp;
 output [2:0] Dout;

 wire net1;
 wire net2;
 wire net3;
 wire net4;
 wire net5;
 wire net6;
 wire net7;
 wire net9;
 wire net10;
 wire net11;
 wire net8;
 wire _00_;
 wire _01_;
 wire _02_;
 wire _03_;
 wire _04_;
 wire _05_;
 wire _06_;
 wire _07_;
 wire _08_;
 wire _09_;
 wire _10_;
 wire _11_;
 wire _12_;
 wire _13_;
 wire net12;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 sky130_fd_sc_hd__decap_12 FILLER_0_15 ();
 sky130_fd_sc_hd__fill_1 FILLER_0_27 ();
 sky130_fd_sc_hd__fill_2 FILLER_0_29 ();
 sky130_fd_sc_hd__decap_12 FILLER_0_3 ();
 sky130_fd_sc_hd__decap_12 FILLER_0_39 ();
 sky130_fd_sc_hd__decap_4 FILLER_0_51 ();
 sky130_fd_sc_hd__fill_1 FILLER_0_55 ();
 sky130_fd_sc_hd__decap_4 FILLER_0_57 ();
 sky130_fd_sc_hd__decap_12 FILLER_1_15 ();
 sky130_fd_sc_hd__decap_4 FILLER_1_27 ();
 sky130_fd_sc_hd__decap_12 FILLER_1_3 ();
 sky130_fd_sc_hd__decap_12 FILLER_1_36 ();
 sky130_fd_sc_hd__decap_4 FILLER_1_51 ();
 sky130_fd_sc_hd__fill_1 FILLER_1_55 ();
 sky130_fd_sc_hd__decap_4 FILLER_1_57 ();
 sky130_fd_sc_hd__decap_4 FILLER_1_77 ();
 sky130_fd_sc_hd__decap_12 FILLER_2_15 ();
 sky130_fd_sc_hd__fill_1 FILLER_2_27 ();
 sky130_fd_sc_hd__decap_12 FILLER_2_29 ();
 sky130_fd_sc_hd__decap_12 FILLER_2_3 ();
 sky130_fd_sc_hd__decap_12 FILLER_2_41 ();
 sky130_fd_sc_hd__decap_6 FILLER_2_53 ();
 sky130_fd_sc_hd__fill_2 FILLER_2_75 ();
 sky130_fd_sc_hd__decap_12 FILLER_3_15 ();
 sky130_fd_sc_hd__decap_12 FILLER_3_27 ();
 sky130_fd_sc_hd__decap_12 FILLER_3_3 ();
 sky130_fd_sc_hd__decap_12 FILLER_3_39 ();
 sky130_fd_sc_hd__decap_4 FILLER_3_51 ();
 sky130_fd_sc_hd__fill_1 FILLER_3_55 ();
 sky130_fd_sc_hd__decap_12 FILLER_3_57 ();
 sky130_fd_sc_hd__decap_8 FILLER_3_69 ();
 sky130_fd_sc_hd__fill_1 FILLER_4_15 ();
 sky130_fd_sc_hd__decap_8 FILLER_4_19 ();
 sky130_fd_sc_hd__fill_1 FILLER_4_27 ();
 sky130_fd_sc_hd__decap_12 FILLER_4_3 ();
 sky130_fd_sc_hd__decap_12 FILLER_4_34 ();
 sky130_fd_sc_hd__decap_12 FILLER_4_46 ();
 sky130_fd_sc_hd__fill_2 FILLER_4_58 ();
 sky130_fd_sc_hd__fill_1 FILLER_4_80 ();
 sky130_fd_sc_hd__fill_2 FILLER_5_11 ();
 sky130_fd_sc_hd__decap_6 FILLER_5_22 ();
 sky130_fd_sc_hd__decap_8 FILLER_5_3 ();
 sky130_fd_sc_hd__decap_12 FILLER_5_32 ();
 sky130_fd_sc_hd__decap_12 FILLER_5_44 ();
 sky130_fd_sc_hd__fill_1 FILLER_5_57 ();
 sky130_fd_sc_hd__decap_3 FILLER_5_74 ();
 sky130_fd_sc_hd__fill_1 FILLER_6_11 ();
 sky130_fd_sc_hd__decap_6 FILLER_6_22 ();
 sky130_fd_sc_hd__decap_12 FILLER_6_33 ();
 sky130_fd_sc_hd__decap_12 FILLER_6_45 ();
 sky130_fd_sc_hd__decap_3 FILLER_6_57 ();
 sky130_fd_sc_hd__decap_4 FILLER_6_76 ();
 sky130_fd_sc_hd__fill_1 FILLER_6_80 ();
 sky130_fd_sc_hd__decap_8 FILLER_7_11 ();
 sky130_fd_sc_hd__fill_2 FILLER_7_19 ();
 sky130_fd_sc_hd__decap_12 FILLER_7_34 ();
 sky130_fd_sc_hd__decap_8 FILLER_7_46 ();
 sky130_fd_sc_hd__fill_2 FILLER_7_54 ();
 sky130_fd_sc_hd__decap_12 FILLER_7_57 ();
 sky130_fd_sc_hd__decap_8 FILLER_7_69 ();
 sky130_fd_sc_hd__decap_12 FILLER_8_15 ();
 sky130_fd_sc_hd__fill_1 FILLER_8_27 ();
 sky130_fd_sc_hd__decap_12 FILLER_8_3 ();
 sky130_fd_sc_hd__decap_12 FILLER_8_36 ();
 sky130_fd_sc_hd__decap_12 FILLER_8_48 ();
 sky130_fd_sc_hd__decap_12 FILLER_8_60 ();
 sky130_fd_sc_hd__decap_8 FILLER_8_72 ();
 sky130_fd_sc_hd__fill_1 FILLER_8_80 ();
 sky130_fd_sc_hd__decap_12 FILLER_9_15 ();
 sky130_fd_sc_hd__fill_1 FILLER_9_27 ();
 sky130_fd_sc_hd__fill_2 FILLER_9_29 ();
 sky130_fd_sc_hd__decap_12 FILLER_9_3 ();
 sky130_fd_sc_hd__decap_12 FILLER_9_39 ();
 sky130_fd_sc_hd__decap_4 FILLER_9_51 ();
 sky130_fd_sc_hd__fill_1 FILLER_9_55 ();
 sky130_fd_sc_hd__fill_2 FILLER_9_57 ();
 sky130_fd_sc_hd__fill_2 FILLER_9_79 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_0_Left_10 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_0_Right_0 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_1_Left_11 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_1_Right_1 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_2_Left_12 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_2_Right_2 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_3_Left_13 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_3_Right_3 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_4_Left_14 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_4_Right_4 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_5_Left_15 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_5_Right_5 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_6_Left_16 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_6_Right_6 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_7_Left_17 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_7_Right_7 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_8_Left_18 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_8_Right_8 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_9_Left_19 ();
 sky130_fd_sc_hd__decap_3 PHY_EDGE_ROW_9_Right_9 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_0_20 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_0_21 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_1_22 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_2_23 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_3_24 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_4_25 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_5_26 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_6_27 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_7_28 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_8_29 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_9_30 ();
 sky130_fd_sc_hd__tapvpwrvgnd_1 TAP_TAPCELL_ROW_9_31 ();
 sky130_fd_sc_hd__inv_1 _14_ (.A(net8),
    .Y(_00_));
 sky130_fd_sc_hd__nor2b_1 _15_ (.A(net8),
    .B_N(net1),
    .Y(_04_));
 sky130_fd_sc_hd__nand4_1 _16_ (.A(net2),
    .B(net3),
    .C(net4),
    .D(_04_),
    .Y(_05_));
 sky130_fd_sc_hd__xnor2_1 _17_ (.A(net7),
    .B(net6),
    .Y(_06_));
 sky130_fd_sc_hd__nand2_1 _18_ (.A(net5),
    .B(_06_),
    .Y(_07_));
 sky130_fd_sc_hd__xnor2_1 _19_ (.A(net2),
    .B(net3),
    .Y(_08_));
 sky130_fd_sc_hd__nor4_1 _20_ (.A(net4),
    .B(net7),
    .C(net6),
    .D(net5),
    .Y(_09_));
 sky130_fd_sc_hd__nand3_1 _21_ (.A(_04_),
    .B(_08_),
    .C(_09_),
    .Y(_10_));
 sky130_fd_sc_hd__o21ai_0 _22_ (.A1(_05_),
    .A2(_07_),
    .B1(_10_),
    .Y(_01_));
 sky130_fd_sc_hd__nand2_1 _23_ (.A(net6),
    .B(net5),
    .Y(_11_));
 sky130_fd_sc_hd__nand3_1 _24_ (.A(net2),
    .B(_04_),
    .C(_09_),
    .Y(_12_));
 sky130_fd_sc_hd__o21ai_0 _25_ (.A1(_05_),
    .A2(_11_),
    .B1(_12_),
    .Y(_02_));
 sky130_fd_sc_hd__o21ai_0 _26_ (.A1(net7),
    .A2(net6),
    .B1(_11_),
    .Y(_13_));
 sky130_fd_sc_hd__nor2b_1 _27_ (.A(_05_),
    .B_N(_13_),
    .Y(_03_));
 sky130_fd_sc_hd__dfxtp_1 _28_ (.CLK(clknet_1_0__leaf_clk),
    .D(_00_),
    .Q(net12));
 sky130_fd_sc_hd__dfxtp_1 _29_ (.CLK(clknet_1_0__leaf_clk),
    .D(_03_),
    .Q(net11));
 sky130_fd_sc_hd__dfxtp_1 _30_ (.CLK(clknet_1_1__leaf_clk),
    .D(_01_),
    .Q(net9));
 sky130_fd_sc_hd__dfxtp_1 _31_ (.CLK(clknet_1_1__leaf_clk),
    .D(_02_),
    .Q(net10));
 sky130_fd_sc_hd__clkbuf_16 clkbuf_0_clk (.A(clk),
    .X(clknet_0_clk));
 sky130_fd_sc_hd__clkbuf_16 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .X(clknet_1_0__leaf_clk));
 sky130_fd_sc_hd__clkbuf_16 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .X(clknet_1_1__leaf_clk));
 sky130_fd_sc_hd__buf_2 input1 (.A(Comp[0]),
    .X(net1));
 sky130_fd_sc_hd__buf_2 input2 (.A(Comp[1]),
    .X(net2));
 sky130_fd_sc_hd__buf_2 input3 (.A(Comp[2]),
    .X(net3));
 sky130_fd_sc_hd__buf_2 input4 (.A(Comp[3]),
    .X(net4));
 sky130_fd_sc_hd__buf_2 input5 (.A(Comp[4]),
    .X(net5));
 sky130_fd_sc_hd__buf_2 input6 (.A(Comp[5]),
    .X(net6));
 sky130_fd_sc_hd__buf_2 input7 (.A(Comp[6]),
    .X(net7));
 sky130_fd_sc_hd__buf_2 input8 (.A(Samp),
    .X(net8));
 sky130_fd_sc_hd__buf_2 output10 (.A(net10),
    .X(Dout[1]));
 sky130_fd_sc_hd__buf_2 output11 (.A(net11),
    .X(Dout[2]));
 sky130_fd_sc_hd__buf_2 output12 (.A(net12),
    .X(eoc));
 sky130_fd_sc_hd__buf_2 output9 (.A(net9),
    .X(Dout[0]));
endmodule
