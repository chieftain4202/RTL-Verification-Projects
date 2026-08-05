interface axi_i2c_if #(
    parameter int AXI_ADDR_WIDTH = 4,
    parameter int AXI_DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst
);

    logic [AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic [2:0]                axi_awprot;
    logic                      axi_awvalid;
    logic                      axi_awready;
    logic [AXI_DATA_WIDTH-1:0] axi_wdata;
    logic [(AXI_DATA_WIDTH/8)-1:0] axi_wstrb;
    logic                      axi_wvalid;
    logic                      axi_wready;
    logic [1:0]                axi_bresp;
    logic                      axi_bvalid;
    logic                      axi_bready;
    logic [AXI_ADDR_WIDTH-1:0] axi_araddr;
    logic [2:0]                axi_arprot;
    logic                      axi_arvalid;
    logic                      axi_arready;
    logic [AXI_DATA_WIDTH-1:0] axi_rdata;
    logic [1:0]                axi_rresp;
    logic                      axi_rvalid;
    logic                      axi_rready;

    logic                      i2c_scl;
    logic                      i2c_slave_done;
    logic                      i2c_master_done;
    logic                      i2c_master_busy;
    logic [7:0]                slave_tx_data;
    logic [7:0]                slave_rx_data;
    logic [7:0]                master_rx_data;

    // Waveform-friendly debug markers.
    logic                      dbg_drv_active;
    logic                      dbg_drv_axi_write_pulse;
    logic [7:0]                dbg_drv_write_data;
    logic [7:0]                dbg_drv_read_data;
    logic [3:0]                dbg_drv_done_count;

    logic                      dbg_mon_active;
    logic                      dbg_mon_sample_pulse;
    logic [7:0]                dbg_mon_write_expected;
    logic [7:0]                dbg_mon_read_expected;
    logic [7:0]                dbg_mon_slave_rx;
    logic [7:0]                dbg_mon_master_rx;
    logic [3:0]                dbg_mon_done_count;


    clocking drv_cb @(posedge clk);
        default input #1step output #0;
        input  axi_awready;
        input  axi_wready;
        input  axi_bresp;
        input  axi_bvalid;
        input  axi_arready;
        input  axi_rdata;
        input  axi_rresp;
        input  axi_rvalid;
        input  i2c_master_done;
        input  i2c_master_busy;
        output axi_awaddr;
        output axi_awprot;
        output axi_awvalid;
        output axi_wdata;
        output axi_wstrb;
        output axi_wvalid;
        output axi_bready;
        output axi_araddr;
        output axi_arprot;
        output axi_arvalid;
        output axi_rready;
        output slave_tx_data;
    endclocking


    clocking mon_cb @(posedge clk);
        default input #1step output #0;
        input axi_awaddr;
        input axi_awprot;
        input axi_awvalid;
        input axi_awready;
        input axi_wdata;
        input axi_wstrb;
        input axi_wvalid;
        input axi_wready;
        input axi_bresp;
        input axi_bvalid;
        input axi_bready;
        input axi_araddr;
        input axi_arprot;
        input axi_arvalid;
        input axi_arready;
        input axi_rdata;
        input axi_rresp;
        input axi_rvalid;
        input axi_rready;
        input i2c_scl;
        input i2c_slave_done;
        input i2c_master_done;
        input i2c_master_busy;
        input slave_tx_data;
        input slave_rx_data;
        input master_rx_data;
    endclocking


    modport mod_drv(clocking drv_cb, input clk, input rst);
    modport mod_mon(clocking mon_cb, input clk, input rst);
    
endinterface  //
