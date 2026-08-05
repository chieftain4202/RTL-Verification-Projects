`ifndef AXI_I2C_SEQUENCE_SV
`define AXI_I2C_SEQUENCE_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_i2c_seq_item.sv"


class axi_i2c_base_seq extends uvm_sequence #(axi_i2c_seq_item);
    `uvm_object_utils(axi_i2c_base_seq)

    int unsigned start_value = 0;
    int unsigned end_value   = 255;
    bit          invert_read_data = 1'b1;

    function new(string name = "axi_i2c_base_seq");
        super.new(name);
    endfunction  //new()

    function automatic logic [7:0] calc_read_data(logic [7:0] write_data);
        return invert_read_data ? ~write_data : write_data;
    endfunction

    task send_item(logic [7:0] write_data);
        axi_i2c_seq_item item;

        item = axi_i2c_seq_item::type_id::create("item");
        start_item(item);
        item.write_data_expected = write_data;
        item.read_data_expected  = calc_read_data(write_data);
        finish_item(item);

        `uvm_info(
            get_type_name(),
            $sformatf(
                "axi_i2c sequence item: write_data_expected=0x%02h, read_data_expected=0x%02h",
                item.write_data_expected,
                item.read_data_expected
            ),
            UVM_MEDIUM
        )
    endtask

    virtual task body();
        for (int unsigned i = start_value; i <= end_value; i++) begin
            send_item(i[7:0]);
        end
    endtask

endclass

class spi_base_seq extends axi_i2c_base_seq;
    `uvm_object_utils(spi_base_seq)

    function new(string name = "spi_base_seq");
        super.new(name);
    endfunction

endclass
`endif 
