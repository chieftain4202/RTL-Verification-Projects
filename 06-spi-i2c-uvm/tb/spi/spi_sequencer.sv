`ifndef SPI_SEQUENCE_SV
`define SPI_SEQUENCE_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "spi_seq_item.sv"



class spi_base_seq extends uvm_sequence #(spi_seq_item);
    `uvm_object_utils(spi_base_seq)
    int num_loop = 0;

    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction  //new()

    task do_write(bit [7:0] master_data);
        spi_seq_item item;
        item = spi_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
             master_tx_data == master_data;
            })
            `uvm_fatal(get_type_name(), "do_write() Randomize() fail!")
        finish_item(item);
        `uvm_info(get_type_name(), $sformatf("do write spi 전송 요청: master_tx_data = 0x%02h", master_data), UVM_MEDIUM)
    endtask

    virtual task body();
    for (int i = 0; i < num_loop; i++) begin
        do_write($urandom_range(0, 255));
    end
endtask

endclass
`endif 
