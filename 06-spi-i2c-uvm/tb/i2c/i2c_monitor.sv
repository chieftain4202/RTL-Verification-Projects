`ifndef I2C_MONITOR_SV
`define I2C_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "i2c_seq_item.sv"

class i2c_monitor extends uvm_monitor;
    `uvm_component_utils(i2c_monitor)

    uvm_analysis_port #(i2c_seq_item) ap;
    virtual i2c_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "monitor에서 uvm_config_db 에러 발생.");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        wait (vif.rst == 0);
        `uvm_info(get_type_name(), "I2C 모니터링 시작 ...", UVM_MEDIUM)
        forever begin
            decode_transaction();
        end
    endtask

    task wait_start_condition();
        forever begin
            @(negedge vif.sda);
            if (vif.scl === 1'b1) begin
                break;
            end
        end
    endtask

    task wait_stop_condition();
        forever begin
            @(posedge vif.sda);
            if (vif.scl === 1'b1) begin
                break;
            end
        end
    endtask

    task sample_byte(output bit [7:0] byte_data, output bit ack);
        byte_data = 8'h00;
        for (int i = 7; i >= 0; i--) begin
            @(posedge vif.scl);
            byte_data[i] = vif.sda;
        end
        @(posedge vif.scl);
        ack = vif.sda;
    endtask

    task decode_transaction();
        i2c_seq_item tx;
        bit [7:0] addr_byte;
        bit [7:0] write_data;
        bit [7:0] slave_rx_snapshot;
        bit       addr_ack;
        bit       data_ack;

        wait_start_condition();
        sample_byte(addr_byte, addr_ack);
        sample_byte(write_data, data_ack);
        slave_rx_snapshot = vif.slave_rx_data;
        wait_stop_condition();

        tx                     = i2c_seq_item::type_id::create("mon_tx");
        tx.addr_byte           = 8'h70;
        tx.observed_addr_byte  = addr_byte;
        tx.observed_write_data = write_data;
        tx.slave_rx_data       = slave_rx_snapshot;
        tx.addr_ack            = addr_ack;
        tx.data_ack            = data_ack;
        tx.write_data          = write_data;
        tx.slave_addr          = addr_byte[7:1];

        `uvm_info(get_type_name(), $sformatf("I2C MON RX | addr_byte=0x%02h slave_addr=0x%02h rw=%0b addr_ack=%0b write_data=0x%02h data_ack=%0b slave_rx_data=0x%02h",
                                             addr_byte, addr_byte[7:1], addr_byte[0],
                                             addr_ack, write_data, data_ack,
                                             slave_rx_snapshot), UVM_LOW)
        ap.write(tx);
    endtask

endclass

`endif
