`ifndef I2C_COVERAGE_SV
`define I2C_COVERAGE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "i2c_seq_item.sv"

class i2c_coverage extends uvm_subscriber #(i2c_seq_item);
    `uvm_component_utils(i2c_coverage)

    i2c_seq_item tx;

    covergroup i2c_cg;
        cp_addr: coverpoint tx.observed_addr_byte {
            bins fnd_slave_write = {8'h70};
            bins other = default;
        }

        cp_write_data: coverpoint tx.observed_write_data {
            bins zero = {8'h00};
            bins low = {[8'h01 : 8'h3f]};
            bins mid = {[8'h40 : 8'hbf]};
            bins high = {[8'hc0 : 8'hfe]};
            bins full = {8'hff};
        }

        cp_addr_ack: coverpoint tx.addr_ack {
            bins ack = {1'b0};
            bins nack = {1'b1};
        }

        cp_data_ack: coverpoint tx.data_ack {
            bins ack = {1'b0};
            bins nack = {1'b1};
        }

        cx_addr_data: cross cp_addr, cp_write_data;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        i2c_cg = new();
    endfunction

    function void write(i2c_seq_item t);
        tx = t;
        i2c_cg.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "\n\n===== Coverage Summary =====", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Overall: %.1f%%", i2c_cg.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  addr: %.1f%%", i2c_cg.cp_addr.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  write_data: %.1f%%", i2c_cg.cp_write_data.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), "===== Coverage Summary =====\n\n", UVM_LOW)
    endfunction

endclass

`endif
