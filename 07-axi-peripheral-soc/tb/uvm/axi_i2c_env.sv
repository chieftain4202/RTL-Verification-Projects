`ifndef AXI_I2C_ENV_SV
`define AXI_I2C_ENV_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_i2c_seq_item.sv"

class axi_i2c_env extends uvm_env;
    `uvm_component_utils(axi_i2c_env)

    axi_i2c_agent agt;
    axi_i2c_scoreboard scb;
    axi_i2c_coverage cov;



    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = axi_i2c_agent::type_id::create("agt", this);
        scb = axi_i2c_scoreboard::type_id::create("scb", this);
        cov = axi_i2c_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.drv.ap_drv.connect(scb.exp_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

endclass  

class spi_env extends axi_i2c_env;
    `uvm_component_utils(spi_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass





`endif
