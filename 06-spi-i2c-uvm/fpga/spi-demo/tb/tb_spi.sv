`timescale 1ns / 1ps

module tb_spi_master ();

    logic       clk;
    logic       rst;
    logic [7:0] clk_div;
    logic [7:0] tx_data;
    logic       cpol;
    logic       cpha;
    logic       start;
    logic       miso;
    logic [7:0] rx_data;
    logic       done;
    logic       busy;
    logic       sclk;
    logic       mosi;
    logic       cs_n;
    logic       t_idle;
    logic [2:0] bit_cnt;
    logic [7:0] slave_tx_data;
    logic [7:0] slave_rx_data;
    logic       slave_done;
    logic [7:0] first_rx_data;
    logic [7:0] echo_rx_data;

    always #5 clk = ~clk;

    assign slave_tx_data = 8'h00;

    SPI_master dut (
        .clk    (clk),
        .rst    (rst),
        .clk_div(clk_div),
        .tx_data(tx_data),
        .cpol   (cpol),
        .cpha   (cpha),
        .start  (start),
        .miso   (miso),
        .rx_data(rx_data),
        .done   (done),
        .busy   (busy),
        .sclk   (sclk),
        .mosi   (mosi),
        .cs_n   (cs_n),
        .t_idle (t_idle),
        .bit_cnt(bit_cnt)
    );

    SPI_slave u_slave (
        .clk    (clk),
        .sclk   (sclk),
        .rst    (rst),
        .mosi   (mosi),
        .tx_data(slave_tx_data),
        .bit_cnt(bit_cnt),
        .cs_n   (cs_n),
        .t_idle (t_idle),
        .rx_data(slave_rx_data),
        .sdone  (slave_done),
        .miso   (miso)
    );

    task spi_set_mode(logic [1:0] mode);
        {cpol, cpha} = mode;
        @(posedge clk);
        
    endtask //spi_set_od

    task spi_send_data(logic [7:0] data, output logic [7:0] received_data);
        tx_data = data;
        start   = 1'b1;
        @(posedge clk);
        start = 1'b0;
        @(posedge clk);
        wait (done);
        received_data = rx_data;
        @(posedge clk);
    endtask  //spi_send_data(logic [7:0] data)




    initial begin
        clk = 0;
        rst = 1;
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        clk_div = 4;  // SCLK = 10Mhz : (100mhz / 10mhz * 2) - 1
        //miso    = 1'b0;
        @(posedge clk);

        spi_set_mode(0);
        spi_send_data(8'ha5, first_rx_data);
        @(posedge clk);

        if (slave_rx_data !== 8'ha5) begin
            $error("SLAVE RX FAIL: expected=0x%02h actual=0x%02h", 8'ha5, slave_rx_data);
        end
        
        spi_send_data(8'h00, echo_rx_data);
        if (echo_rx_data !== 8'ha5) begin
            $error("ECHO FAIL: expected=0x%02h actual=0x%02h", 8'ha5, echo_rx_data);
        end else begin
            $display("ECHO PASS: master_tx=0x%02h master_rx=0x%02h", 8'ha5, echo_rx_data);
        end



        @(posedge clk);
        #20;
        $finish;
    end
endmodule
