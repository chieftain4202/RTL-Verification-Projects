`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "spi_seq_item.sv"
`uvm_analysis_imp_decl(_exp)

class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_seq_item, spi_scoreboard) ap_imp;
    uvm_analysis_imp_exp #(spi_seq_item, spi_scoreboard) exp_imp;

    logic [7:0] expected;
    int success;
    int error;
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
        exp_imp = new("exp_imp", this);
    endfunction

    function void write_exp(spi_seq_item tx);
        expected = tx.master_tx_data;
        `uvm_info(get_type_name(), $sformatf("SPI Expected MOSI set: 0x%02h", expected), UVM_MEDIUM)
    endfunction

    function void write(spi_seq_item tx);

        if (expected !== tx.mosi_data) begin
            error++;
            `uvm_error(get_type_name(), $sformatf ("FAIL!!! SPI MOSI : 0x%02h, Expected : 0x%02h", tx.mosi_data, expected));
        end else begin
            success ++;
            `uvm_info(get_type_name(), $sformatf ("PASS!!! SPI MOSI : 0x%02h, Expected : 0x%02h", tx.mosi_data, expected), UVM_LOW);
        end

    endfunction

    virtual function void report_phase(uvm_phase phase);
        string result = (error == 0) ? "** PASS **" : "** FAIL **";
        `uvm_info(get_type_name(), "******** summary report *********", UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Result : %s", result), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Pass num : %0d", success), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Errors num : %0d", error), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("*****************************"), UVM_MEDIUM)
    endfunction
endclass  //component 



`endif
