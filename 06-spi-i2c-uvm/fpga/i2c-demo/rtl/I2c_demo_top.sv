`timescale 1ns / 1ps

module I2c_demo_top (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] sw,
    input  logic       btn_start,
    input  logic       btn_stop,
    input  logic       btn_addr,
    input  logic       btn_write,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data,
    output logic       mscl,
    inout logic       msda,
    input logic       sscl,
    inout logic       ssda


);

    logic start, stop, write, read, addr;

    logic [7:0] counter;
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
    logic       master_ack_out;
    logic       busy;
    logic       scl;
    logic [7:0] sw_hex_data;
    wire        sda;




    assign ack_in = 1'b1;

    sw_data u_sw_data (
        .sw      (sw),
        .hex_data(sw_hex_data)
    );

    btn_debounce u_btn_debounce_start (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_start),
        .o_btn(start)
    );

    btn_debounce u_btn_debounce_stop (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_stop),
        .o_btn(stop)
    );

    btn_debounce u_btn_debounce_write (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_write),
        .o_btn(write)
    );

    btn_debounce u_btn_debounce_addr (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_addr),
        .o_btn(addr)
    );

    fnd_controller u_fnd (
        .sum      (S_rx_data),
        .btn      (),
        .clk      (clk),
        .rst      (rst),
        .ibtn     (btn_addr),
        .done     (done),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );


    i2c_slave U_I2c_Slave (
        .clk    (clk),
        .rst    (rst),
        .tx_data(S_tx_data),
        .rx_data(S_rx_data),
        .scl    (sscl),
        .sda    (ssda)

    );


    I2C_Master U_I2C_Master (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(start),
        .cmd_write(write),
        .cmd_read (read),
        .cmd_stop (stop),
        .M_tx_data(M_tx_data),
        .ack_in   (ack_in),
        .M_rx_data(M_rx_data),
        .done     (done),
        .ack_out  (master_ack_out),
        .busy     (busy),
        .scl      (mscl),
        .sda      (msda)
    );

    typedef enum logic [2:0] {
        IDLE  = 0,
        START,
        ADDR,
        WRITE,
        STOP

    } i2c_state_e;

    localparam SLA_W = {7'h12, 1'b0};
    i2c_state_e state;


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            counter   <= 0;
            state     <= IDLE;
            cmd_start <= 0;
            cmd_write <= 0;
            cmd_read  <= 0;
            cmd_stop  <= 0;
            M_tx_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_start <= 0;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    if (start) begin
                        state <= START;
                    end
                end

                START: begin
                    cmd_start <= 1;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    if (done) begin
                        state <= ADDR;
                    end
                end

                ADDR: begin
                    cmd_start <= 0;
                    cmd_write <= 1;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    M_tx_data <= 8'b01110000;
                    if (done) begin
                        state <= WRITE;
                    end
                end

                WRITE: begin
                    cmd_start <= 0;
                    cmd_write <= 1;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    M_tx_data <= sw_hex_data;
                    if (write) begin
                        state <= STOP;
                    end
                end

                STOP: begin
                    cmd_start <= 0;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 1;
                    if (done) begin
                        state   <= IDLE;
                        counter <= counter + 1;
                    end
                end

            endcase
        end
    end
endmodule
