`timescale 1ns / 1ps

module i2c_slave_block (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done,
    input  logic       scl,
    inout  wire        sda
);
    logic sda_i, sda_o;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0; // 3-State Buffer (1이면 개방, 0이면 당김)

    i2c_slave #(
        .SLAVE_ADDR(7'h55)
    ) U_I2C_SLAVE (
        .clk(clk),
        .rst(rst),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .done(done),
        .scl(scl),
        .sda_i(sda_i),
        .sda_o(sda_o)
    );
endmodule

module edge_detect (
    input  logic clk,
    input  logic rst,
    input  logic sclk,
    output logic r_edge,
    output logic f_edge,
    output logic sync_out
);
    logic ff1, ff2, ff3;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            ff1 <= 0;
            ff2 <= 0;
            ff3 <= 0;
        end else begin
            ff1 <= sclk;
            ff2 <= ff1;
            ff3 <= ff2;
        end
    end

    assign r_edge   = (ff2 == 1 && ff3 == 0) ? 1'b1 : 1'b0;
    assign f_edge   = (ff2 == 0 && ff3 == 1) ? 1'b1 : 1'b0;
    assign sync_out = ff2;
endmodule

module i2c_slave #(
    parameter [6:0] SLAVE_ADDR = 7'h55
) (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       done,
    input  logic       scl,
    input  logic       sda_i,
    output logic       sda_o
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        WAIT_ADDR,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state;

    i2c_state state;

    logic scl_r, scl_f, scl_sync;
    logic sda_r, sda_f, sda_sync;

    edge_detect U_SCL_DET (
        .clk(clk),
        .rst(rst),
        .sclk(scl),
        .r_edge(scl_r),
        .f_edge(scl_f),
        .sync_out(scl_sync)
    );
    edge_detect U_SDA_DET (
        .clk(clk),
        .rst(rst),
        .sclk(sda_i),
        .r_edge(sda_r),
        .f_edge(sda_f),
        .sync_out(sda_sync)
    );

    logic start_cond, stop_cond;
    assign start_cond = (scl_sync == 1'b1) && sda_f;
    assign stop_cond  = (scl_sync == 1'b1) && sda_r;

    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [3:0] bit_cnt;
    logic       is_read;//0: Master Write(Slave 수신), 1: Master Read(Slave 송신)
    logic is_addr_ack;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            sda_o        <= 1'b1;
            rx_shift_reg <= 8'd0;
            tx_shift_reg <= 8'd0;
            bit_cnt      <= 4'd0;
            is_read      <= 1'b0;
            rx_data      <= 8'd0;
            done         <= 1'b0;
            is_addr_ack  <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start_cond) begin
                state   <= START;
                sda_o   <= 1'b1;
                bit_cnt <= 4'd0;
            end else if (stop_cond) begin
                state <= STOP;
                sda_o <= 1'b1;
            end else begin
                case (state)
                    IDLE: sda_o <= 1'b1;  //high상태.

                    START: begin
                        if (scl_f) begin
                            state   <= WAIT_ADDR;
                            bit_cnt <= 0;
                        end
                    end

                    WAIT_ADDR: begin
                        if (scl_r) begin
                            rx_shift_reg <= {
                                rx_shift_reg[6:0], sda_sync
                            };  // 상승 에지에서 sda값을 읽어 RX 레지스터 사용
                            bit_cnt <= bit_cnt + 1;
                        end else if (scl_f) begin
                            if (bit_cnt == 4'd8) begin
                                if (rx_shift_reg[7:1] == SLAVE_ADDR) begin  //addr 비교
                                    state       <= DATA_ACK;
                                    is_addr_ack <= 1'b1;
                                    is_read     <= rx_shift_reg[0];
                                    sda_o       <= 1'b0;  // ACK 전송
                                end else begin
                                    state <= IDLE;
                                    sda_o <= 1'b1;  //
                                end
                            end
                        end
                    end

                    DATA: begin
                        if (scl_r) begin
                            if (!is_read)
                                rx_shift_reg <= {
                                    rx_shift_reg[6:0], sda_sync
                                };  // 수신 시 RX 사용
                            bit_cnt <= bit_cnt + 1;
                        end else if (scl_f) begin
                            if (bit_cnt == 4'd8) begin
                                state       <= DATA_ACK;
                                is_addr_ack <= 1'b0;
                                if (!is_read) begin
                                    sda_o   <= 1'b0; // ACK
                                    rx_data <= rx_shift_reg;
                                    done    <= 1'b1;
                                end else begin
                                    sda_o <= 1'b1;  // 마스터 ACK 대기
                                end
                            end else if (is_read) begin
                                // 송신 시 TX 레지스터 시프트
                                sda_o        <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                        end
                    end

                    DATA_ACK: begin
                        if (scl_r) begin
                            if (!is_addr_ack && is_read && sda_sync == 1'b0)
                                done <= 1'b1;
                        end else if (scl_f) begin
                            // 마스터가 Read 모드에서 NACK(sda_sync == 1)을 보냈다면 송신 중단 및 버스 릴리즈
                            if (!is_addr_ack && is_read && sda_sync == 1'b1) begin
                                state       <= IDLE;
                                sda_o       <= 1'b1;
                                is_addr_ack <= 1'b0;
                            end else begin
                                bit_cnt <= 4'd0;
                                state   <= DATA;
                                if (is_read) begin
                                    sda_o        <= tx_data[7];
                                    tx_shift_reg <= {tx_data[6:0], 1'b0};
                                end else begin
                                    sda_o <= 1'b1;  // 수신 대기
                                end
                                is_addr_ack <= 1'b0;
                            end
                        end
                    end
                    STOP: state <= IDLE;
                endcase
            end
        end
    end
endmodule
