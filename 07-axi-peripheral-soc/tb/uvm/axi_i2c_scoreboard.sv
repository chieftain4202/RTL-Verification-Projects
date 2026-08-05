`ifndef AXI_I2C_SCOREBOARD_SV
`define AXI_I2C_SCOREBOARD_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_i2c_seq_item.sv"
`uvm_analysis_imp_decl(_exp)

class axi_i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_i2c_scoreboard)

    uvm_analysis_imp #(axi_i2c_seq_item, axi_i2c_scoreboard) ap_imp;
    uvm_analysis_imp_exp #(axi_i2c_seq_item, axi_i2c_scoreboard) exp_imp;

    logic [7:0] expected_write_data;
    logic [7:0] expected_read_data;
    int         pass_count;
    int         error_count;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
        exp_imp = new("exp_imp", this);
    endfunction

    function void write_exp(axi_i2c_seq_item tx);
        expected_write_data = tx.write_data_expected;
        expected_read_data  = tx.read_data_expected;
        `uvm_info(
            get_type_name(),
            $sformatf(
                "AXI_I2C expected set: write=0x%02h, read=0x%02h",
                expected_write_data,
                expected_read_data
            ),
            UVM_MEDIUM
        )
    endfunction

    function void write(axi_i2c_seq_item tx);
        if (expected_write_data !== tx.slave_rx_data) begin
            error_count++;
            `uvm_error(
                get_type_name(),
                $sformatf(
                    "WRITE PATH FAIL: actual slave_rx=0x%02h, expected write=0x%02h",
                    tx.slave_rx_data,
                    expected_write_data
                )
            );
        end else begin
            pass_count++;
            `uvm_info(
                get_type_name(),
                $sformatf(
                    "WRITE PATH PASS: actual slave_rx=0x%02h, expected write=0x%02h",
                    tx.slave_rx_data,
                    expected_write_data
                ),
                UVM_LOW
            );
        end

        if (expected_read_data !== tx.master_rx_data) begin
            error_count++;
            `uvm_error(
                get_type_name(),
                $sformatf(
                    "READ PATH FAIL: actual master_rx=0x%02h, expected read=0x%02h",
                    tx.master_rx_data,
                    expected_read_data
                )
            );
        end else begin
            pass_count++;
            `uvm_info(
                get_type_name(),
                $sformatf(
                    "READ PATH PASS: actual master_rx=0x%02h, expected read=0x%02h",
                    tx.master_rx_data,
                    expected_read_data
                ),
                UVM_LOW
            );
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        string result = (error_count == 0) ? "** PASS **" : "** FAIL **";
        `uvm_info(get_type_name(), "******** summary report *********", UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Result : %s", result), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Pass num : %0d", pass_count), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Errors num : %0d", error_count), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("*****************************"), UVM_MEDIUM)
    endfunction
endclass  //component 

class spi_scoreboard extends axi_i2c_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass



`endif
