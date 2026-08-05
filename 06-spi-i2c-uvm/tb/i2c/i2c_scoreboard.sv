`ifndef I2C_SCOREBOARD_SV
`define I2C_SCOREBOARD_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "i2c_seq_item.sv"
`uvm_analysis_imp_decl(_exp)

class i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(i2c_scoreboard)

    uvm_analysis_imp #(i2c_seq_item, i2c_scoreboard) ap_imp;
    uvm_analysis_imp_exp #(i2c_seq_item, i2c_scoreboard) exp_imp;

    logic [7:0] expected_addr;
    logic [7:0] expected_data;
    i2c_seq_item expected_q[$];

    int success;
    int error;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp  = new("ap_imp", this);
        exp_imp = new("exp_imp", this);
    endfunction

    function void write_exp(i2c_seq_item tx);
        i2c_seq_item exp_tx;
        $cast(exp_tx, tx.clone());
        expected_q.push_back(exp_tx);
        expected_addr = tx.addr_byte;
        expected_data = tx.write_data;
        `uvm_info(get_type_name(), $sformatf("I2C expected set: addr = 0x%02h, data = 0x%02h",
                                             expected_addr, expected_data), UVM_MEDIUM)
    endfunction

    function void write(i2c_seq_item tx);
        bit fail;
        i2c_seq_item exp_tx;
        fail = 1'b0;

        if (expected_q.size() == 0) begin
            error++;
            `uvm_error(get_type_name(), "MONITOR transaction arrived, but expected queue is empty")
            return;
        end

        exp_tx = expected_q.pop_front();

        if (tx.observed_addr_byte !== exp_tx.addr_byte) begin
            fail = 1'b1;
            `uvm_error(get_type_name(), $sformatf("ADDR FAIL: observed = 0x%02h, expected = 0x%02h",
                                                  tx.observed_addr_byte, exp_tx.addr_byte))
        end

        if (tx.observed_write_data !== exp_tx.write_data) begin
            fail = 1'b1;
            `uvm_error(get_type_name(), $sformatf("DATA FAIL: observed = 0x%02h, expected = 0x%02h",
                                                  tx.observed_write_data, exp_tx.write_data))
        end

        if (tx.slave_rx_data !== exp_tx.write_data) begin
            fail = 1'b1;
            `uvm_error(get_type_name(), $sformatf("SLAVE RX FAIL: slave_rx = 0x%02h, expected = 0x%02h",
                                                  tx.slave_rx_data, exp_tx.write_data))
        end

        if (tx.addr_ack !== 1'b0 || tx.data_ack !== 1'b0) begin
            fail = 1'b1;
            `uvm_error(get_type_name(), $sformatf("ACK FAIL: addr_ack = %0b, data_ack = %0b",
                                                  tx.addr_ack, tx.data_ack))
        end

        if (fail) begin
            error++;
        end else begin
            success++;
            `uvm_info(get_type_name(), $sformatf("PASS: %s", tx.convert2string()), UVM_LOW)
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        string result;
        if (expected_q.size() != 0) begin
            error += expected_q.size();
            `uvm_error(get_type_name(), $sformatf("Expected queue still has %0d unchecked transaction(s)",
                                                  expected_q.size()))
        end
        result = (error == 0) ? "** PASS **" : "** FAIL **";
        `uvm_info(get_type_name(), "******** summary report *********", UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Result : %s", result), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Pass num : %0d", success), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Errors num : %0d", error), UVM_MEDIUM)
        `uvm_info(get_type_name(), "*****************************", UVM_MEDIUM)
    endfunction

endclass

`endif
