`timescale 1ns / 1ps


module tb_uart_watch ();

    parameter BAUD = 9600;
    parameter BAUD_PERIOD = (104_160_000 / BAUD) * 10;  //104_160_000

    reg clk, rst, rx;
    wire tx;
    reg [7:0] test_data;
    integer i, j;

    Top_stopwatch dut (
        .clk(clk),
        .reset(rst),
        .btn_r(),
        .btn_d(),
        .btn_u(),
        .btn_l(),
        .sw(),         //sw[0] up/down
        .uart_rx(rx),
        .uart_tx(tx),
        .fnd_digit(),
        .fnd_data()
    );

    always #5 clk = ~clk;

 /* task uart_sender();
        begin
            //uart text pattern
            //start
            rx = 0;
            #(BAUD_PERIOD);
            //data
            for (i = 0; i < 8; i = i + 1) begin
                rx = test_data[i];
                #(BAUD_PERIOD);
            end
            //stop
            rx = 1'b1;
            #(BAUD_PERIOD);
        end
    endtask
*/
    initial begin
        #0;
        clk = 0;
        rst = 1;
        rx = 1'b1;
        test_data = 8'h31;  //ascii '1'
        i = 0;
        j = 0;

 /*       repeat (5) @(posedge clk);
        rst = 0;
        for (j = 0; j < 10; j = j + 1) begin
            test_data = 8'h30 + j;
            uart_sender();
        end

        // hold time for uart_tx_out
        for (j = 0; j < 12; j = j + 1) begin
            #(BAUD_PERIOD);
        end*/
        $stop;
    end
endmodule
