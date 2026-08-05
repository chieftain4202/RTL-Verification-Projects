`include "uvm_macros.svh"
import uvm_pkg::*;

`include "spi_interface.sv"
`include "spi_seq_item.sv"
`include "spi_sequencer.sv"
`include "spi_drive.sv"
`include "spi_monitor.sv"
`include "spi_agent.sv"
`include "spi_scoreboard.sv"
`include "spi_coverage.sv"
`include "spi_env.sv"
`include "spi_test.sv"

module tb_spi ();
    logic clk;
    logic rst;

    always #5 clk = ~clk;

    spi_if vif (
        clk,
        rst
    );

    SPI_master dut_master (
        .clk    (clk),
        .rst    (rst),
        .cpol   (1'b0),
        .cpha   (1'b0),
        .clk_div(8'd4),
        .tx_data(vif.master_tx_data),
        .start  (vif.spi_start),
        .miso   (vif.miso),
        .rx_data(vif.master_rx_data),
        .done   (vif.master_done),
        .busy   (vif.master_busy),
        .sclk   (vif.sclk),
        .mosi   (vif.mosi),
        .cs_n   (vif.cs_n),
        .t_idle (vif.t_idle),
        .bit_cnt(vif.bit_cnt)
    );

    SPI_slave dut_slave (
        .clk    (clk),
        .sclk   (vif.sclk),
        .rst    (rst),
        .mosi   (vif.mosi),
        .tx_data(vif.slave_tx_data),
        .bit_cnt(vif.bit_cnt),
        .cs_n   (vif.cs_n),
        .t_idle (vif.t_idle),
        .rx_data(vif.slave_rx_data),
        .sdone  (vif.slave_done),
        .miso   (vif.miso)
    );

    initial begin
        clk = 0;
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    initial begin
        uvm_config_db#(virtual spi_if)::set(null, "*", "vif", vif);
        run_test("spi_base_test");
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_spi, "+all");
    end

endmodule
