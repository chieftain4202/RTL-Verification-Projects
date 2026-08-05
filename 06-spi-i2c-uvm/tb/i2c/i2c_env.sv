`ifndef I2C_ENVIRONMENT_SV
`define I2C_ENVIRONMENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "i2c_seq_item.sv"

class i2c_env extends uvm_env;
    `uvm_component_utils(i2c_env)

    i2c_agent agt;
    i2c_scoreboard scb;
    i2c_coverage cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = i2c_agent::type_id::create("agt", this);
        scb = i2c_scoreboard::type_id::create("scb", this);
        cov = i2c_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.drv.ap_drv.connect(scb.exp_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction

endclass

`endif
