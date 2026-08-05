`include "uvm_macros.svh"
import uvm_pkg::*;

`include "i2c_interface.sv"
`include "i2c_seq_item.sv"
`include "i2c_sequencer.sv"
`include "i2c_drive.sv"
`include "i2c_monitor.sv"
`include "i2c_agent.sv"
`include "i2c_scoreboard.sv"
`include "i2c_coverage.sv"
`include "i2c_env.sv"
`include "i2c_test.sv"

module tb_i2c ();
    logic clk;
    logic rst;

    always #5 clk = ~clk;

    i2c_if vif (
        clk,
        rst
    );

    I2C_Master dut_master (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(vif.cmd_start),
        .cmd_write(vif.cmd_write),
        .cmd_read (vif.cmd_read),
        .cmd_stop (vif.cmd_stop),
        .M_tx_data(vif.master_tx_data),
        .ack_in   (vif.ack_in),
        .M_rx_data(vif.master_rx_data),
        .done     (vif.master_done),
        .ack_out  (vif.master_ack_out),
        .busy     (vif.master_busy),
        .scl      (vif.scl),
        .sda      (vif.sda)
    );

    i2c_slave dut_slave (
        .clk    (clk),
        .rst    (rst),
        .tx_data(vif.slave_tx_data),
        .rx_data(vif.slave_rx_data),
        .scl    (vif.scl),
        .sda    (vif.sda)
    );

    initial begin
        clk = 0;
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    initial begin
        uvm_config_db#(virtual i2c_if)::set(null, "*", "vif", vif);
        run_test("i2c_base_test");
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_i2c, "+all");
    end

endmodule
