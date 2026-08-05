interface spi_if (
    input logic clk,
    input logic rst
);

    logic       spi_start;       // SPI start pulse
    logic       sclk;     // SPI sclk
    logic       mosi;       // SPI mosi
    logic [7:0] master_tx_data;  // SPI master tx_data
    logic       slave_done;  // SPI slave done pulse
    logic       master_done;       // SPI master done pulse
    logic       master_busy;       // SPI master busy

    logic       miso;
    logic       cs_n;
    logic       t_idle;
    logic [2:0] bit_cnt;
    logic [7:0] slave_tx_data;
    logic [7:0] slave_rx_data;
    logic [7:0] master_rx_data;


    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        input  sclk;
        input  master_done;
        input  master_busy;
        input  cs_n;
        output spi_start;
        output master_tx_data;
        output slave_tx_data;

    endclocking


    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input sclk;
        input master_tx_data;
        input slave_done;
        input mosi;
        input master_done;
        input master_busy;
        input miso;
        input cs_n;
        input t_idle;
        input bit_cnt;
        input slave_tx_data;
        input slave_rx_data;
        input master_rx_data;

    endclocking


    modport mod_drv(clocking drv_cb, input clk, input rst);
    modport mod_mon(clocking mon_cb, input clk, input rst);
endinterface  //
