`timescale 1ns / 1ps


module tb_uart_rx ();

    parameter BAUD = 9600;
    parameter BAUD_PERIOD = (104_160_000 / BAUD) * 10;  //104_160_000

    reg clk, rst, rx, a, b, e, f, g;
    wire tx, c, d;
    reg [7:0] test_data;
    reg [2:0] sw;
    integer i, j;


    Top_stopwatch dut (
        .clk      (clk),
        .reset    (rst),
        .btn_r    (),
        .btn_d    (),
        .btn_u    (),
        .btn_l    (),
        .sw       (sw),         //sw[0] up/down
        .uart_rx  (rx),
        .uart_tx  (tx),
        .fnd_digit(d),
        .fnd_data (c)
        
);
    

    always #5 clk = ~clk;


   task uart_sender();
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

    initial begin
        #0;
        clk = 0;
        rst = 1;
        rx = 1'b1;
        test_data = 8'h30;  //ascii '1'
        i = 0;
        j = 0;
        sw = 0; 
        repeat (5) @(posedge clk);
        rst = 0;
        for (j = 0; j < 10; j = j + 1) begin
            test_data = 8'h70 + j;
            uart_sender();
        end
        // hold time for uart_tx_out

        $stop;
    end
    

    /*initial begin
        #0;
        clk = 0;
        rst = 1;
        test_data = 8'h0;
        sw = 0;
        #50;
        rst = 0;
        #500;
        test_data = 8'h72;
        uart_sender();

        #10;
        test_data = 8'h00;
        uart_sender();
        #500;
        sw[1] = 1;
        #500;
        sw[2] = 1;
        #500;
        test_data = 8'h61;
        #500;
        test_data = 8'h61;
        #500;
        test_data = 8'h62;
        #500;
        $stop;

    end
*/
/*
       ascii_decoder dut(
    .uart_rx_ascii(test_data),
    .clk(clk),
    .rst(rst),
    .uart_rx_done(a),
    .o_asc_dcd(d)
);
    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        test_data = 8'h0;
        a = 0;
        #5;
        rst = 0;
        #5;
        test_data = 8'h72;
        #10;
        a = 1;
        #4;
        a = 0;
        #50;
        test_data = 8'h61;
        #50;
        a = 1;
        #10;
        a = 0;
        #50;
        test_data = 8'h64;
        #50;
        a = 1;
        #10;
        a = 0;
        #50;
        test_data = 8'h73;
        #50;
        a = 1;
        #10;
        a = 0;
        #50;
        test_data = 8'h63;
        #50;
        a = 1;
        #10;
        a = 0;
        #50;
        test_data = 8'h62;
        #50;
        a = 1;
        #10;
        a = 0;
        #500_00;
        $stop;
    end
    */
    /*
    btn_decoder dut(
    .i_btn_l(a),
    .i_btn_r(b),
    .i_btn_u(e),
    .i_btn_d(f),
    .i_btn_c(g),
    .o_btn_dcd(d)
);

    initial begin
        #0;
        rst = 0;
        clk = 0;
        a = 0;
        b = 0;
        e = 0;
        f = 0;
        g = 0;
        #10;
        a = 1;
        #10;
        a = 0;
        #10;
        b = 1;
        #10;
        b = 0;
        #10;
        e = 1;
        #10;
        e = 0;
        #10;
        f = 1;
        #15;
        f = 0;
        #10;
        g = 1;
        #20;
        g = 0;
        #15;
        $stop;
  end
*/


    /*
       uart_top dut (
           .clk(clk),
           .rst(rst),
           .uart_rx(rx),
           .uart_tx(tx)
       );

      ascii_decoder dut (
        .uart_rx_ascii(test_data),
        .clk(clk),
        .rst(rst),
        .uart_rx_done(b),
        .o_asc_dcd(c)
    );*/




    /*  initial begin
        #0;
        rst = 0;
        clk = 0;
        b = 0;
        test_data = 8'h0;
        #5;
        test_data = 8'h64;
        #5;
        b = 1;
        #10;
        b = 0;
        #15;
        $stop;



    end
*/
    /*always #5 clk = ~clk;
    
    task uart_sender();
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

    initial begin
        #0;
        clk = 0;
        rst = 1;
        rx = 1'b1;
        test_data = 8'h31;  //ascii '1'
        i = 0;
        j = 0;

        repeat (5) @(posedge clk);
        rst = 0;
        for (j = 0; j < 10; j = j + 1) begin
            test_data = 8'h30 + j;
            uart_sender();
        end

        // hold time for uart_tx_out
        for (j = 0; j < 12; j = j + 1) begin
            #(BAUD_PERIOD);
        end
        $stop;
    end
    */
endmodule
