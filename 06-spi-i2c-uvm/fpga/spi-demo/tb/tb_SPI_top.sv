`timescale 1ns / 1ps

module tb_SPI_top ();

    logic       clk;
    logic       rst;
    logic       cpol;
    logic       cpha;
    logic [7:0] clk_div;
    logic [7:0] master_tx_data;
    logic       master_start;
    logic [7:0] slave_tx_data;
    logic [7:0] master_rx_data;
    logic       master_done;
    logic       master_busy;
    logic [7:0] slave_rx_data;
    logic       slave_done;
    logic       slave_busy;
    logic       fnd_digit;
    logic       fnd_data;
    logic       ibtn;
    logic       sbtn;
    logic [3:0] sw;


    SPI_top dut (.*);

    always #5 clk = ~clk;

    task spi_set_mode(logic [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);

    endtask  //spi_set_od

    task spi_send_data(logic [7:0] data);
        master_tx_data = data;
        master_start   = 1'b1;
        @(posedge clk);
        master_start = 1'b0;
        @(posedge clk);
        wait (master_done);
        @(posedge clk);
    endtask  //spi_send_data(logic [7:0] data)

    initial begin
        clk = 0;
        rst = 1;
        ibtn = 0;
        sbtn = 0;
        sw[0] = 0;
        sw[1] = 0;
        sw[2] = 0;
        sw[3] = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        clk_div = 4;

        sw[0] = 0;
        sw[1] = 0;
        sw[2] = 1;
        sw[3] = 0;

        ibtn = 1;
        #9000;
        ibtn = 0;
        #100;
        sbtn = 1;
        #9000;
        sbtn = 0;

        ibtn = 1;
        #9000;
        ibtn = 0;

        sw[0] = 0;
        sw[1] = 0;
        sw[2] = 1;
        sw[3] = 1;
        
        sbtn = 1;
        #9000;
        sbtn = 0;

        #100;
        $finish;
        // spi_set_mode(0);
        // spi_send_data(8'h04);
/*
        spi_send_data(8'hbb);

        spi_send_data(8'hcc);
        
        spi_send_data(8'hdd);
*/
    end

endmodule
