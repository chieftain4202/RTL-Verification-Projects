`ifndef I2C_DRIVER_SV
`define I2C_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "i2c_seq_item.sv"

class i2c_driver extends uvm_driver #(i2c_seq_item);
    `uvm_component_utils(i2c_driver)

    uvm_analysis_port #(i2c_seq_item) ap_drv;
    virtual i2c_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_drv = new("ap_drv", this);
        if (!uvm_config_db#(virtual i2c_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "driver에서 uvm_config_db 에러 발생.");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        i2c_init();
        wait (vif.rst == 0);
        `uvm_info(get_type_name(), "리셋 해제 확인. I2C 트랜잭션 대기 중...", UVM_MEDIUM)

        forever begin
            i2c_seq_item tx;
            seq_item_port.get_next_item(tx);
            drive_i2c(tx);
            seq_item_port.item_done();
        end
    endtask

    task i2c_init();
        vif.drv_cb.cmd_start     <= 1'b0;
        vif.drv_cb.cmd_write     <= 1'b0;
        vif.drv_cb.cmd_read      <= 1'b0;
        vif.drv_cb.cmd_stop      <= 1'b0;
        vif.drv_cb.master_tx_data <= 8'h00;
        vif.drv_cb.ack_in        <= 1'b1;
        vif.drv_cb.slave_tx_data <= 8'h00;
    endtask

    task wait_i2c_ready();
        do begin
            @(vif.drv_cb);
        end while (vif.drv_cb.master_busy);
    endtask

    task wait_master_done();
        do begin
            @(vif.drv_cb);
        end while (!vif.drv_cb.master_done);
        @(vif.drv_cb);
    endtask

    task pulse_start();
        vif.drv_cb.cmd_start <= 1'b1;
        repeat (2) @(vif.drv_cb);
        vif.drv_cb.cmd_start <= 1'b0;
        wait_master_done();
    endtask

    task pulse_write(bit [7:0] tx_data);
        vif.drv_cb.master_tx_data <= tx_data;
        vif.drv_cb.cmd_write      <= 1'b1;
        repeat (2) @(vif.drv_cb);
        vif.drv_cb.cmd_write      <= 1'b0;
        wait_master_done();
    endtask

    task pulse_stop();
        vif.drv_cb.cmd_stop <= 1'b1;
        repeat (2) @(vif.drv_cb);
        vif.drv_cb.cmd_stop <= 1'b0;
        wait_master_done();
    endtask

    task drive_i2c(i2c_seq_item tx);
        wait_i2c_ready();

        tx.addr_byte = {tx.slave_addr, 1'b0};
        vif.drv_cb.slave_tx_data <= 8'h00;
        ap_drv.write(tx);

        pulse_start();
        pulse_write(tx.addr_byte);
        pulse_write(tx.write_data);
        pulse_stop();

        `uvm_info(get_type_name(), $sformatf("i2c drv 구동 완료: %s", tx.convert2string()), UVM_MEDIUM)
    endtask

endclass

`endif
