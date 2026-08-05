`ifndef MONITOR_SV
`define MONITOR_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "spi_seq_item.sv"

class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    uvm_analysis_port #(spi_seq_item) ap;
    virtual spi_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "monitor에서 uvm_config_db 에러 발생.");
        end
    endfunction



    virtual task run_phase(uvm_phase phase);
        wait (vif.rst == 0);
        `uvm_info(get_type_name(), " 모니터링 시작 ...", UVM_MEDIUM)
        forever begin
            decode_transaction();
        end
    endtask

    task wait_sclks(int n);
        repeat (n) begin
            @(posedge vif.sclk);
        end
    endtask

    task decode_transaction();
        spi_seq_item tx;
        bit [7:0] mosi_buf;

        mosi_buf = 0;

        do begin
            @(vif.mon_cb);
        end while (vif.mon_cb.cs_n !== 1'b0);

        for (int i = 7; i >= 0; i--) begin
            @(posedge vif.sclk);
            mosi_buf[i] = vif.mosi;
        end

        do begin
            @(vif.mon_cb);
        end while (vif.mon_cb.cs_n !== 1'b1);

        tx              = spi_seq_item::type_id::create("mon_tx");
        tx.mosi_data    = mosi_buf;
        tx.master_tx_data = vif.mon_cb.master_tx_data;
        tx.slave_rx_data = vif.mon_cb.slave_rx_data;
        tx.master_rx_data = vif.mon_cb.master_rx_data;

        `uvm_info(get_type_name(), $sformatf("spi mon mosi: 0x%02h, slave_rx: 0x%02h",
                                             mosi_buf, vif.mon_cb.slave_rx_data), UVM_MEDIUM)
        ap.write(tx);

    endtask

endclass  //component 


`endif
