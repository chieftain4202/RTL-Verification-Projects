`ifndef AXI_I2C_SEQ_ITEM_SV
`define AXI_I2C_SEQ_ITEM_SV


`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_i2c_seq_item extends uvm_sequence_item;

    rand logic [7:0] write_data_expected;
    rand logic [7:0] read_data_expected;
    logic [7:0]      slave_rx_data;
    logic [7:0]      master_rx_data;

    `uvm_object_utils_begin(axi_i2c_seq_item)
        `uvm_field_int(write_data_expected, UVM_ALL_ON)
        `uvm_field_int(read_data_expected, UVM_ALL_ON)
        `uvm_field_int(slave_rx_data, UVM_ALL_ON)
        `uvm_field_int(master_rx_data, UVM_ALL_ON)
    `uvm_object_utils_end


    function new(string name = "axi_i2c_seq_item");
        super.new(name);
    endfunction  //new()

    function string convert2string();
        return $sformatf(
            "write_data_expected=0x%02h, read_data_expected=0x%02h, slave_rx_data=0x%02h, master_rx_data=0x%02h",
            write_data_expected,
            read_data_expected,
            slave_rx_data,
            master_rx_data
        );
    endfunction

endclass  //component 

// Compatibility shim so the remaining spi_* TB files can be migrated incrementally.
class spi_seq_item extends axi_i2c_seq_item;
    `uvm_object_utils(spi_seq_item)

    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction
endclass


`endif
