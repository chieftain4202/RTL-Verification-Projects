`ifndef DRIVER_SV
`define DRIVER_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "spi_seq_item.sv"

class spi_driver extends uvm_driver #(spi_seq_item);
    `uvm_component_utils(spi_driver)
    uvm_analysis_port #(spi_seq_item) ap_drv;
    virtual spi_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_drv = new("ap_drv", this);

        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "driver에서 uvm_config_db 에러 발생.");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        spi_init();
        wait (vif.rst == 0);
        `uvm_info(get_type_name(), "리셋 해제 확인. 트랜잭션 대기 중...", UVM_MEDIUM)

        forever begin
            spi_seq_item tx;
            seq_item_port.get_next_item(tx);
            drive_spi(tx);
            seq_item_port.item_done();
        end
    endtask


    task wait_sclks(int n);
        repeat (n) begin
            @(posedge vif.sclk);
        end
    endtask

    task wait_spi_ready();
        do begin
            @(vif.drv_cb);
        end while (vif.drv_cb.master_busy);
    endtask

    task spi_init();
        vif.drv_cb.spi_start       <= 1'b0;
        vif.drv_cb.master_tx_data  <= 8'h00;
        vif.drv_cb.slave_tx_data <= 8'h00;
    endtask

    task drive_spi(spi_seq_item tx);
        wait_spi_ready();

        vif.drv_cb.master_tx_data  <= tx.master_tx_data;
        vif.drv_cb.slave_tx_data <= 8'h00;
        @(vif.drv_cb);

        ap_drv.write(tx); // expected data 전달

        vif.drv_cb.spi_start <= 1'b1;
        @(vif.drv_cb);
        vif.drv_cb.spi_start <= 1'b0;

        do begin
            @(vif.drv_cb);
        end while (!vif.drv_cb.master_done);

        @(vif.drv_cb);
        `uvm_info(get_type_name(), $sformatf("spi drv 구동 완료: %s", tx.convert2string()), UVM_MEDIUM);
    endtask

endclass  //component 


`endif
