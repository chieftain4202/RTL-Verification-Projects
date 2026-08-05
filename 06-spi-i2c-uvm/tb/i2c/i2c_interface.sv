interface i2c_if (
    input logic clk,
    input logic rst
);

    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] master_tx_data;
    logic       ack_in;
    logic [7:0] master_rx_data;
    logic       master_done;
    logic       master_ack_out;
    logic       master_busy;

    logic       scl;
    tri1        sda;

    logic [7:0] slave_tx_data;
    logic [7:0] slave_rx_data;

    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        input  master_done;
        input  master_ack_out;
        input  master_busy;
        input  slave_rx_data;
        output cmd_start;
        output cmd_write;
        output cmd_read;
        output cmd_stop;
        output master_tx_data;
        output ack_in;
        output slave_tx_data;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input cmd_start;
        input cmd_write;
        input cmd_read;
        input cmd_stop;
        input master_tx_data;
        input ack_in;
        input master_rx_data;
        input master_done;
        input master_ack_out;
        input master_busy;
        input scl;
        input sda;
        input slave_tx_data;
        input slave_rx_data;
    endclocking

    modport mod_drv(clocking drv_cb, input clk, input rst);
    modport mod_mon(clocking mon_cb, input clk, input rst);
endinterface
