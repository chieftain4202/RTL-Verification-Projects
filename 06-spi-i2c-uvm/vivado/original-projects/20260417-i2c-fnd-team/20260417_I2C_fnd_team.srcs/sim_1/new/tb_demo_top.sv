`timescale 1ns / 1ps


module tb_demo_top ();

    logic       clk;
    logic       rst;
    logic [7:0] sw;
    logic       btn_start;
    logic       btn_stop;
    logic       btn_addr;
    logic       btn_write;
    logic [3:0] fnd_digit;
    logic [7:0] fnd_data;
    logic       mscl;
    wire        msda;
    logic       sscl;
    wire        ssda;

    assign sscl = mscl;
    assign ssda = msda;

    I2c_demo_top dut (.*);


    always #5 clk = ~clk;

    initial begin
        rst = 1;
        clk = 0;
        #100;
        sw[7:0] = 0;
        btn_addr = 0;
        btn_write = 0;
        btn_stop = 0;
        btn_start = 0;
        rst = 0;
        @(posedge clk);
        sw[3] = 1;
        btn_start = 1;
        #10000;
        btn_start = 0;
        #5000;
        btn_addr = 1;
        #10000;
        btn_addr = 0;
        #10000;
        btn_write = 1;
        #10000;
        btn_write = 0;
        #1000000;
        btn_write = 1;
        #10000;
        btn_write = 0;



        #1000;
        #1000;
        $finish;

    end



endmodule
