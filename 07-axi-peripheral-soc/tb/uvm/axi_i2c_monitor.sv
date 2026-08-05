`ifndef AXI_I2C_MONITOR_SV
`define AXI_I2C_MONITOR_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_i2c_seq_item.sv"

class axi_i2c_monitor extends uvm_monitor;
    `uvm_component_utils(axi_i2c_monitor)

    uvm_analysis_port #(axi_i2c_seq_item) ap;
    virtual axi_i2c_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual axi_i2c_if)::get(this, "", "vif", vif)) begin
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

    task wait_i2c_done_pulses(int pulse_count);
        int seen_count;

        seen_count = 0;
        while (seen_count < pulse_count) begin
            @(vif.mon_cb);
            if (vif.mon_cb.i2c_master_done) begin
                seen_count++;
                vif.dbg_mon_done_count <= seen_count[3:0];
            end
        end
    endtask

    task decode_transaction();
        axi_i2c_seq_item tx;
        logic [7:0] write_data_expected;
        logic [7:0] read_data_expected;

        write_data_expected = '0;
        read_data_expected  = '0;
        vif.dbg_mon_active       <= 1'b0;
        vif.dbg_mon_sample_pulse <= 1'b0;
        vif.dbg_mon_done_count   <= 4'd0;

        do begin
            @(vif.mon_cb);
        end while (!(vif.mon_cb.axi_awvalid && vif.mon_cb.axi_awready &&
                     vif.mon_cb.axi_wvalid && vif.mon_cb.axi_wready));

        vif.dbg_mon_active         <= 1'b1;
        write_data_expected = vif.mon_cb.axi_wdata[7:0];
        read_data_expected  = vif.mon_cb.slave_tx_data;
        vif.dbg_mon_write_expected <= write_data_expected;
        vif.dbg_mon_read_expected  <= read_data_expected;

        wait_i2c_done_pulses(8);
        @(vif.mon_cb);

        tx = axi_i2c_seq_item::type_id::create("mon_tx");
        tx.write_data_expected = write_data_expected;
        tx.read_data_expected  = read_data_expected;
        tx.slave_rx_data = vif.mon_cb.slave_rx_data;
        tx.master_rx_data = vif.mon_cb.master_rx_data;
        vif.dbg_mon_slave_rx      <= tx.slave_rx_data;
        vif.dbg_mon_master_rx     <= tx.master_rx_data;
        vif.dbg_mon_sample_pulse  <= 1'b1;

        `uvm_info(
            get_type_name(),
            $sformatf(
                "axi_i2c mon write_exp=0x%02h, read_exp=0x%02h, slave_rx=0x%02h, master_rx=0x%02h",
                tx.write_data_expected,
                tx.read_data_expected,
                tx.slave_rx_data,
                tx.master_rx_data
            ),
            UVM_MEDIUM
        )
        ap.write(tx);
        @(vif.mon_cb);
        vif.dbg_mon_sample_pulse <= 1'b0;
        vif.dbg_mon_active       <= 1'b0;

    endtask

endclass  //component 

class spi_monitor extends axi_i2c_monitor;
    `uvm_component_utils(spi_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass


`endif
