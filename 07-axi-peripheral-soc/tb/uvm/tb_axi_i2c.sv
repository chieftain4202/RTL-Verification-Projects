`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi_i2c_interface.sv"
`include "axi_i2c_seq_item.sv"
`include "axi_i2c_sequencer.sv"
`include "axi_i2c_drive.sv"
`include "axi_i2c_monitor.sv"
`include "axi_i2c_agent.sv"
`include "axi_i2c_scoreboard.sv"
`include "axi_i2c_coverage.sv"
`include "axi_i2c_env.sv"
`include "axi_i2c_test.sv"

module tb_AXI_I2C ();
    logic clk;
    logic rst;

    always #5 clk = ~clk;

    axi_i2c_if axi_i2c_vif (
        clk,
        rst
    );
    wire              scl;
    tri1              sda;
    wire [       3:0] fnd_digit;
    wire [       7:0] fnd_data;
    logic             slave_done;
    logic [       7:0] slave_rx_data;

    wire              s00_axi_aclk;
    wire              s00_axi_aresetn;
    wire [     4-1:0] s00_axi_awaddr;
    wire [       2:0] s00_axi_awprot;
    wire              s00_axi_awvalid;
    wire              s00_axi_awready;
    wire [    32-1:0] s00_axi_wdata;
    wire [(32/8)-1:0] s00_axi_wstrb;
    wire              s00_axi_wvalid;
    wire              s00_axi_wready;
    wire [       1:0] s00_axi_bresp;
    wire              s00_axi_bvalid;
    wire              s00_axi_bready;
    wire [     4-1:0] s00_axi_araddr;
    wire [       2:0] s00_axi_arprot;
    wire              s00_axi_arvalid;
    wire              s00_axi_arready;
    wire [    32-1:0] s00_axi_rdata;
    wire [       1:0] s00_axi_rresp;
    wire              s00_axi_rvalid;
    wire              s00_axi_rready;


    assign s00_axi_aclk    = clk;
    assign s00_axi_aresetn = ~rst;

    assign s00_axi_awaddr  = axi_i2c_vif.axi_awaddr;
    assign s00_axi_awprot  = axi_i2c_vif.axi_awprot;
    assign s00_axi_awvalid = axi_i2c_vif.axi_awvalid;
    assign s00_axi_wdata   = axi_i2c_vif.axi_wdata;
    assign s00_axi_wstrb   = axi_i2c_vif.axi_wstrb;
    assign s00_axi_wvalid  = axi_i2c_vif.axi_wvalid;
    assign s00_axi_bready  = axi_i2c_vif.axi_bready;
    assign s00_axi_araddr  = axi_i2c_vif.axi_araddr;
    assign s00_axi_arprot  = axi_i2c_vif.axi_arprot;
    assign s00_axi_arvalid = axi_i2c_vif.axi_arvalid;
    assign s00_axi_rready  = axi_i2c_vif.axi_rready;

    assign axi_i2c_vif.axi_awready = s00_axi_awready;
    assign axi_i2c_vif.axi_wready  = s00_axi_wready;
    assign axi_i2c_vif.axi_bresp   = s00_axi_bresp;
    assign axi_i2c_vif.axi_bvalid  = s00_axi_bvalid;
    assign axi_i2c_vif.axi_arready = s00_axi_arready;
    assign axi_i2c_vif.axi_rdata   = s00_axi_rdata;
    assign axi_i2c_vif.axi_rresp   = s00_axi_rresp;
    assign axi_i2c_vif.axi_rvalid  = s00_axi_rvalid;

    assign axi_i2c_vif.i2c_scl         = scl;
    assign axi_i2c_vif.i2c_master_done = dut.masteri2c.done;
    assign axi_i2c_vif.i2c_master_busy = dut.masteri2c.busy;
    assign axi_i2c_vif.master_rx_data  = dut.masteri2c.m_rx_data;
    assign axi_i2c_vif.i2c_slave_done  = slave_done;
    assign axi_i2c_vif.slave_rx_data   = slave_rx_data;

    i2c_write_read_master_v1_0 dut (

        .scl      (scl),
        .sda      (sda),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data),

        .s00_axi_aclk   (s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr (s00_axi_awaddr),
        .s00_axi_awprot (s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata  (s00_axi_wdata),
        .s00_axi_wstrb  (s00_axi_wstrb),
        .s00_axi_wvalid (s00_axi_wvalid),
        .s00_axi_wready (s00_axi_wready),
        .s00_axi_bresp  (s00_axi_bresp),
        .s00_axi_bvalid (s00_axi_bvalid),
        .s00_axi_bready (s00_axi_bready),
        .s00_axi_araddr (s00_axi_araddr),
        .s00_axi_arprot (s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata  (s00_axi_rdata),
        .s00_axi_rresp  (s00_axi_rresp),
        .s00_axi_rvalid (s00_axi_rvalid),
        .s00_axi_rready (s00_axi_rready)
    );
    i2c_slave_block u_i2c_slave (
        .clk    (clk),
        .rst    (rst),
        .tx_data(axi_i2c_vif.slave_tx_data),
        .rx_data(slave_rx_data),
        .done   (slave_done),
        .scl    (scl),
        .sda    (sda)
    );

    initial begin
        clk = 0;
        rst = 1;
        axi_i2c_vif.slave_tx_data = 8'h00;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    initial begin
        uvm_config_db#(virtual axi_i2c_if)::set(null, "*", "vif", axi_i2c_vif);
        run_test();
    end

    initial begin
        $fsdbDumpfile("novas.fsdb");
        $fsdbDumpvars(0, tb_AXI_I2C, "+all");
    end

endmodule
