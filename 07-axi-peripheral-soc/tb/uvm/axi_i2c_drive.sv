`ifndef AXI_I2C_DRIVER_SV
`define AXI_I2C_DRIVER_SV


`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi_i2c_seq_item.sv"

class axi_i2c_driver extends uvm_driver #(axi_i2c_seq_item);
    `uvm_component_utils(axi_i2c_driver)

    localparam logic [3:0] REG0_ADDR = 4'h0;

    uvm_analysis_port #(axi_i2c_seq_item) ap_drv;
    virtual axi_i2c_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction  //new()


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_drv = new("ap_drv", this);

        if (!uvm_config_db#(virtual axi_i2c_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "driver에서 uvm_config_db 에러 발생.");
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_i2c_init();
        wait (vif.rst == 0);
        `uvm_info(get_type_name(), "리셋 해제 확인. 트랜잭션 대기 중...", UVM_MEDIUM)

        forever begin
            axi_i2c_seq_item tx;
            seq_item_port.get_next_item(tx);
            drive_axi_i2c(tx);
            seq_item_port.item_done();
        end
    endtask


    task wait_clks(int n);
        repeat (n) begin
            @(posedge vif.clk);
        end
    endtask

    task wait_i2c_not_busy();
        do begin
            @(vif.drv_cb);
        end while (vif.drv_cb.i2c_master_busy);
    endtask

    task wait_i2c_done_pulses(int pulse_count);
        int seen_count;

        seen_count = 0;
        while (seen_count < pulse_count) begin
            @(vif.drv_cb);
            if (vif.drv_cb.i2c_master_done) begin
                seen_count++;
                vif.dbg_drv_done_count <= seen_count[3:0];
            end
        end
    endtask

    task axi_i2c_init();
        vif.drv_cb.axi_awaddr  <= '0;
        vif.drv_cb.axi_awprot  <= '0;
        vif.drv_cb.axi_awvalid <= 1'b0;
        vif.drv_cb.axi_wdata   <= '0;
        vif.drv_cb.axi_wstrb   <= '0;
        vif.drv_cb.axi_wvalid  <= 1'b0;
        vif.drv_cb.axi_bready  <= 1'b0;
        vif.drv_cb.axi_araddr  <= '0;
        vif.drv_cb.axi_arprot  <= '0;
        vif.drv_cb.axi_arvalid <= 1'b0;
        vif.drv_cb.axi_rready  <= 1'b0;
        vif.drv_cb.slave_tx_data <= 8'h00;
        vif.dbg_drv_active          <= 1'b0;
        vif.dbg_drv_axi_write_pulse <= 1'b0;
        vif.dbg_drv_write_data      <= 8'h00;
        vif.dbg_drv_read_data       <= 8'h00;
        vif.dbg_drv_done_count      <= 4'd0;
    endtask

    task axi_write(input logic [3:0] addr, input logic [31:0] data);
        @(vif.drv_cb);
        vif.dbg_drv_axi_write_pulse <= 1'b1;
        vif.drv_cb.axi_awaddr  <= addr;
        vif.drv_cb.axi_awprot  <= 3'b000;
        vif.drv_cb.axi_awvalid <= 1'b1;
        vif.drv_cb.axi_wdata   <= data;
        vif.drv_cb.axi_wstrb   <= 4'b1111;
        vif.drv_cb.axi_wvalid  <= 1'b1;

        do begin
            @(vif.drv_cb);
        end while (!(vif.drv_cb.axi_awready && vif.drv_cb.axi_wready));

        vif.dbg_drv_axi_write_pulse <= 1'b0;
        vif.drv_cb.axi_awvalid <= 1'b0;
        vif.drv_cb.axi_wvalid  <= 1'b0;
        vif.drv_cb.axi_bready  <= 1'b1;

        do begin
            @(vif.drv_cb);
        end while (!vif.drv_cb.axi_bvalid);

        vif.drv_cb.axi_bready <= 1'b0;
    endtask

    task drive_axi_i2c(axi_i2c_seq_item tx);
        logic [31:0] axi_wr_data;

        axi_wr_data = '0;
        axi_wr_data[7:0] = tx.write_data_expected;

        // Current assumption:
        // tx.write_data_expected : DUT가 slave로 써야 하는 데이터
        // tx.read_data_expected  : slave가 DUT에 돌려줄 응답 데이터
        vif.dbg_drv_active     <= 1'b1;
        vif.dbg_drv_done_count <= 4'd0;
        vif.dbg_drv_write_data <= tx.write_data_expected;
        vif.dbg_drv_read_data  <= tx.read_data_expected;
        vif.drv_cb.slave_tx_data <= tx.read_data_expected;

        wait_i2c_not_busy();
        axi_write(REG0_ADDR, axi_wr_data);
        ap_drv.write(tx);
        // One full master_top transaction generates 8 command-done pulses:
        // write start/addr/data/stop + read start/addr/data/stop.
        wait_i2c_done_pulses(8);
        wait_clks(2);
        vif.dbg_drv_active <= 1'b0;

        `uvm_info(
            get_type_name(),
            $sformatf(
                "axi_i2c drv write 완료: reg0=0x%02h, slave_tx_data=0x%02h",
                tx.write_data_expected,
                tx.read_data_expected
            ),
            UVM_MEDIUM
        );
    endtask

endclass  //component 

class spi_driver extends axi_i2c_driver;
    `uvm_component_utils(spi_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass


`endif
