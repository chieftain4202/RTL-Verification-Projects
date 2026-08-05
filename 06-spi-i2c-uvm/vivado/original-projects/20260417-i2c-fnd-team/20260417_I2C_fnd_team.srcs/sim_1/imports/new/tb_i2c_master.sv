`timescale 1ns / 1ps

module tb_i2c_master ();
    logic       clk;
    logic       rst;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] M_tx_data;
    logic [7:0] S_tx_data;
    logic       ack_in;
    logic [7:0] M_rx_data;
    logic [7:0] S_rx_data;
    logic       done;
    logic       ack_out;
    logic       busy;
    logic       scl;
    wire        sda;
    logic [8:0] sw;
    logic       btn_addr;
    logic [7:0] fnd_data;
    logic [3:0] fnd_digit;



    localparam SLA = 8'h12;
    /*
    I2C_Master dut (
        .*,
        .scl(scl),
        .sda(sda)
    );
*/

    fnd_top dut (
        .clk      (clk),
        .rst      (rst),
        .sw       (sw),
        .btn_start(cmd_start),
        .btn_addr (btn_addr),
        .btn_write(cmd_write),
        .btn_read (cmd_read),
        .btn_stop (cmd_stop),
        .mscl     (scl),
        .sscl     (scl),
        .msda     (sda),
        .ssda     (sda),
        .fnd_data (fnd_data),
        .fnd_digit(fnd_digit)
    );

    always #5 clk = ~clk;
    assign S_tx_data = 8'b11101110;
    pullup(sda);

    task i2c_start();
        // start
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        cmd_start = 1'b0;
        wait (done);
        @(posedge clk);
    endtask

    task i2c_addr(byte addr);
        // tx_data = address(8'h12) + rw
        M_tx_data = addr;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_write(byte data);
        M_tx_data = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_read();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b1;
        cmd_stop  = 1'b0;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    task i2c_stop();
        // stop
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read  = 1'b0;
        cmd_stop  = 1'b1;
        @(posedge clk);
        wait (done);
        @(posedge clk);
    endtask

    initial begin
        clk       = 0;
        rst       = 1;
        cmd_start = 0;
        cmd_write = 0;
        cmd_read  = 0;
        cmd_stop  = 0;
        M_tx_data = 8'h00;
        sw        = 9'h005;
        btn_addr  = 0;
        repeat (3) @(posedge clk);
        rst = 0;

        repeat (20) @(posedge clk);
        cmd_start = 1'b1;
        repeat (1000) @(posedge clk);
        cmd_start = 1'b0;

        wait (dut.u_i2c_demo.display_valid);
        @(posedge clk);
        repeat (200) @(posedge clk);
        $finish;

    end

endmodule
