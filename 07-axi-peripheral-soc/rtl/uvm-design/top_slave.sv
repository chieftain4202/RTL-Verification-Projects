`timescale 1ns / 1ps

module top_slave (
    input  logic       clk,
    input  logic       rst,
    input  logic       scl,
    inout  wire        sda,
    input  logic [7:0] s_sw,
    output logic [7:0] fnd_seg,
    output logic [3:0] fnd_sel
);

    logic [7:0] s_rx_data;

    // 슬레이브 블록 인스턴스 (주소 0x55 고정)
    i2c_slave_block U_SLAVE (
        .clk(clk),
        .rst(rst),
        .tx_data(s_sw),
        .rx_data(s_rx_data),
        .done(),
        .scl(scl),
        .sda(sda)
    );

    // FND 컨트롤러 인스턴스
    fnd_controller U_FND (
        .clk(clk),
        .rst(rst),
        .data_in(s_rx_data),
        .fnd_seg(fnd_seg),
        .fnd_sel(fnd_sel)
    );

endmodule
