`ifndef I2C_SEQUENCE_SV
`define I2C_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "i2c_seq_item.sv"

class i2c_base_seq extends uvm_sequence #(i2c_seq_item);
    `uvm_object_utils(i2c_base_seq)
    int num_loop = 0;

    function new(string name = "i2c_base_seq");
        super.new(name);
    endfunction

    task do_write(bit [7:0] data);
        i2c_seq_item item;
        item = i2c_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                write_data == data;
            }) begin
            `uvm_fatal(get_type_name(), "do_write() Randomize() fail!")
        end
        finish_item(item);
        `uvm_info(get_type_name(), $sformatf("do write i2c 전송 요청: addr = 0x%02h, data = 0x%02h",
                                             item.addr_byte, item.write_data), UVM_MEDIUM)
    endtask

    virtual task body();
        for (int i = 0; i < num_loop; i++) begin
            do_write($urandom_range(0, 255));
        end
    endtask

endclass

`endif
