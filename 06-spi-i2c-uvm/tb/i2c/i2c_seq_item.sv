`ifndef I2C_SEQ_ITEM_SV
`define I2C_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class i2c_seq_item extends uvm_sequence_item;

    rand logic [6:0] slave_addr;
    rand logic [7:0] write_data;

    logic [7:0] addr_byte;
    logic [7:0] observed_addr_byte;
    logic [7:0] observed_write_data;
    logic [7:0] slave_rx_data;
    logic       addr_ack;
    logic       data_ack;

    constraint valid_slave_addr_c {
        slave_addr == 7'h38;
    }

    `uvm_object_utils_begin(i2c_seq_item)
        `uvm_field_int(slave_addr, UVM_ALL_ON)
        `uvm_field_int(write_data, UVM_ALL_ON)
        `uvm_field_int(addr_byte, UVM_ALL_ON)
        `uvm_field_int(observed_addr_byte, UVM_ALL_ON)
        `uvm_field_int(observed_write_data, UVM_ALL_ON)
        `uvm_field_int(slave_rx_data, UVM_ALL_ON)
        `uvm_field_int(addr_ack, UVM_ALL_ON)
        `uvm_field_int(data_ack, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "i2c_seq_item");
        super.new(name);
    endfunction

    function void post_randomize();
        addr_byte = {slave_addr, 1'b0};
    endfunction

    function string convert2string();
        return $sformatf("addr_byte = 0x%02h, write_data = 0x%02h, observed_addr = 0x%02h, observed_data = 0x%02h, slave_rx = 0x%02h, addr_ack = %0b, data_ack = %0b",
                         addr_byte, write_data, observed_addr_byte, observed_write_data,
                         slave_rx_data, addr_ack, data_ack);
    endfunction

endclass

`endif
