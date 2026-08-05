`timescale 1ns / 1ps


module SPI_slave (
    input  logic       clk,
    input  logic       sclk,
    input  logic       rst,
    input  logic       mosi,
    input  logic [7:0] tx_data,
    input  logic [2:0] bit_cnt,
    input  logic       cs_n,
    input  logic       t_idle,
    output logic [7:0] rx_data,
    output logic       sdone,
    output logic       miso
);

    logic edge_d;
    logic e_rise, e_fall;
    logic [7:0] tx_shift_reg, rx_shift_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_d <= 0;
        end else begin
            edge_d <= sclk;
        end
    end

    assign e_rise = ~edge_d & sclk;
    assign e_fall = ~sclk & edge_d;
    //assign tx_data = tx_shift_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
        end else begin
            sdone <= 0;
            if (!cs_n) begin
                tx_shift_reg <= rx_shift_reg;
                sdone <= 1;
                rx_data <= rx_shift_reg;
                if (bit_cnt == 0) begin
                    miso <= tx_shift_reg[7];

                end
            end

            if (e_fall) begin
                // tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                miso <= rx_shift_reg[7];

            end else begin
                if (e_rise) begin
                    rx_shift_reg <= {rx_shift_reg[6:0], mosi};
                end
            end

        end
    end

endmodule
