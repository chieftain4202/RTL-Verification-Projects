`timescale 1ns / 1ps


module tb_clock_stop ();

    reg clk, reset, btn_r, btn_l, btn_d, mode;
    reg a, b;
    reg [3:0] sw;

    Top_stopwatch dut (
    .clk  (clk),
    .reset(reset),
    .btn_r(btn_r),
    .btn_l(btn_l),
    .btn_d(btn_d),
    .mode (mode),
    .sw   (sw[3:0])
    );



  /*  control_unit dutT (
        .clk       (clk),
        .reset     (reset),
        .i_mode    (sw),
        .i_run_stop(a),
        .i_clear   (b),
        .sw_1      (sw[1]),
        .sw_2      (sw[2])
    );

*/

   /* stopwatch_datapath dut (
        .clk     (clk),
        .reset   (reset),
        .mode    (sw[0]),
        .clear   (a),
        .run_stop(b)

    );
*/

/*  tick_counter_s dut(
    .clk(clk),
    .reset(reset),
    .i_tick(),
    .mode(sw[0]),
    .clear(a),
    .run_stop(b)
);
*/  
/*
    mux_2 dut (
        .mux_in_stop(b),
        .mux_in_clock(a),
        .mode(sw[1])
    );
*/



    always #5 clk = ~clk;

    initial begin
        #0;
        reset = 1;
        clk = 0;
        btn_l = 0;
        btn_r = 0;
        btn_d = 0;
        mode = 0;
        sw[3:0] = 0;
        #10;
        reset = 0;
        #100;
        btn_r = 1;
        #90000000;
        btn_r = 0;
        #60000;
        
       /* #60000;
        sw[1] = 1;
        #600_000_000;
        sw[1] = 0;
        #60000;
        sw[2] = 1;
        #60000;*/
        #10;
        $stop;
    end

endmodule
