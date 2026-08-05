`ifndef COVERAGE_SV
`define COVERAGE_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "spi_seq_item.sv"

class spi_coverage extends uvm_subscriber #(spi_seq_item);
    `uvm_component_utils(spi_coverage)
    spi_seq_item tx;

    covergroup spi_cg;

        cp_mosi_data: coverpoint tx.mosi_data {
            bins addr_low       = {[8'h00 : 8'h3C]};
            bins addr_mid_low   = {[8'h40 : 8'h7C]};
            bins addr_mid_high = {[8'h80 : 8'hBC]};
            bins addr_high = {[8'hC0 : 8'hFC]};

        }

        cp_mosi: coverpoint tx.master_tx_data {
            bins zero = {8'h00};
            bins low = {[8'h01 : 8'h3f]};
            bins mid = {[8'h40 : 8'hbf]};
            bins high = {[8'hc0 : 8'hfe]};
            bins full = {8'hff};
        }

        cx_mosi_tx_bus: cross cp_mosi, cp_mosi_data;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        spi_cg = new();
    endfunction  //new()

    function void write (spi_seq_item t);
        tx = t;
        spi_cg.sample();
    endfunction


    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "\n\n===== Coverage Summary =====", UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  Overall: %.1f%%", spi_cg.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  mosi_data: %.1f%%", spi_cg.cp_mosi_data.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("  master_tx_data: %.1f%%", spi_cg.cp_mosi.get_coverage()), UVM_LOW);
        `uvm_info(get_type_name(), "===== Coverage Summary =====\n\n", UVM_LOW);

    endfunction
endclass  //component 



`endif
