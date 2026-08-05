`ifndef AXI_I2C_COVERAGE_SV
`define AXI_I2C_COVERAGE_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_i2c_seq_item.sv"

class axi_i2c_coverage extends uvm_subscriber #(axi_i2c_seq_item);
    `uvm_component_utils(axi_i2c_coverage)

    axi_i2c_seq_item tx;

    covergroup axi_i2c_cg;

        cp_write_expected: coverpoint tx.write_data_expected {
            bins all_values[] = {[8'h00 : 8'hFF]};
        }

        cp_read_expected: coverpoint tx.read_data_expected {
            bins all_values[] = {[8'h00 : 8'hFF]};
        }

        cp_slave_rx: coverpoint tx.slave_rx_data {
            bins all_values[] = {[8'h00 : 8'hFF]};
        }

        cp_master_rx: coverpoint tx.master_rx_data {
            bins all_values[] = {[8'h00 : 8'hFF]};
        }

        cx_write_path: cross cp_write_expected, cp_slave_rx;
        cx_read_path: cross cp_read_expected, cp_master_rx;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_i2c_cg = new();
    endfunction  //new()

    function void write (axi_i2c_seq_item t);
        tx = t;
        axi_i2c_cg.sample();
    endfunction


    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "\n\n===== Coverage Summary =====", UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  Overall: %.1f%%", axi_i2c_cg.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  write_expected: %.1f%%", axi_i2c_cg.cp_write_expected.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  read_expected: %.1f%%", axi_i2c_cg.cp_read_expected.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  slave_rx: %.1f%%", axi_i2c_cg.cp_slave_rx.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  master_rx: %.1f%%", axi_i2c_cg.cp_master_rx.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), "===== Coverage Summary =====\n\n", UVM_LOW);

    endfunction
endclass  //component 

class spi_coverage extends axi_i2c_coverage;
    `uvm_component_utils(spi_coverage)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass



`endif
