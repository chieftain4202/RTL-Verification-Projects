`ifndef AXI_I2C_AGENT_SV
`define AXI_I2C_AGENT_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_i2c_seq_item.sv"

typedef uvm_sequencer#(axi_i2c_seq_item) axi_i2c_sequencer;

class axi_i2c_agent extends uvm_agent;
    `uvm_component_utils(axi_i2c_agent)

    axi_i2c_driver drv;
    axi_i2c_monitor mon;
    axi_i2c_sequencer sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = axi_i2c_driver::type_id::create("drv", this);
        mon = axi_i2c_monitor::type_id::create("mon", this);
        sqr = axi_i2c_sequencer::type_id::create("sqr", this);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass  //component 

class spi_agent extends axi_i2c_agent;
    `uvm_component_utils(spi_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass


`endif
