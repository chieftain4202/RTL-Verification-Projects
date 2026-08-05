`ifndef SPI_SEQ_ITEM_SV
`define SPI_SEQ_ITEM_SV


`include "uvm_macros.svh"
import uvm_pkg::*;

class spi_seq_item extends uvm_sequence_item;

    rand logic [7:0] master_tx_data;
    logic [7:0] mosi_data;
    logic [7:0] slave_rx_data;
    logic [7:0] master_rx_data;


    `uvm_object_utils_begin(spi_seq_item)
        `uvm_field_int(master_tx_data, UVM_ALL_ON)
        `uvm_field_int(mosi_data, UVM_ALL_ON)
        `uvm_field_int(slave_rx_data, UVM_ALL_ON)
        `uvm_field_int(master_rx_data, UVM_ALL_ON)
    `uvm_object_utils_end


    function new(string name = "spi_seq_item");
        super.new(name);
    endfunction  //new()

    function string convert2string();
        return $sformatf("master_tx = 0x%02h, mosi = 0x%02h, slave_rx = 0x%02h, master_rx = 0x%02h",
                         master_tx_data, mosi_data, slave_rx_data, master_rx_data);
    endfunction

endclass  //component 



`endif
