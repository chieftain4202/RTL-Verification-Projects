`timescale 1ns / 1ps


module SPI_slave (
    input  logic       clk,
    input  logic       sclk,
    input  logic       rst,
    input  logic       mosi,
    input  logic [7:0] tx_data,
    //input  logic [2:0] bit_cnt,
    input  logic       cs_n,
    input  logic       t_idle,
    output logic [7:0] rx_data,
    output logic       sdone,
    output logic       miso
);

    logic edge_d;
    logic [2:0] bit_cnt;
    logic e_rise, e_fall;
    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic cs_n_d;
    logic cs_fall;
    logic [7:0] echo_data;
    logic       echo_valid;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_d <= 0;
            cs_n_d <= 1'b1;
        end else begin
            edge_d <= sclk;
            cs_n_d <= cs_n;
        end
    end

    assign e_rise = ~edge_d & sclk;
    assign e_fall = ~sclk & edge_d;
    assign cs_fall = cs_n_d & ~cs_n;
    //assign tx_data = tx_shift_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            echo_data    <= 0;
            echo_valid   <= 1'b0;
            rx_data      <= 0;
            sdone        <= 1'b0;
            miso         <= 1'b0;
        end else begin
            sdone <= 0;

            if (cs_fall) begin
                rx_shift_reg <= 0;
                if (echo_valid) begin
                    tx_shift_reg <= echo_data;
                    miso <= echo_data[7];
                end else begin
                    tx_shift_reg <= tx_data;
                    miso <= tx_data[7];
                end
            end

            if (!cs_n) begin
                if (e_fall) begin
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    miso <= tx_shift_reg[6];

                end else begin
                    if (e_rise) begin
                        if (bit_cnt == 7) begin
                            rx_data <= {rx_shift_reg[6:0], mosi};
                            echo_data <= {rx_shift_reg[6:0], mosi};
                            echo_valid <= 1'b1;
                            sdone <= 1'b1;
                            bit_cnt <= 0;
                        end else  begin 
                            bit_cnt <= bit_cnt + 1;
                            end
                    rx_shift_reg <= {rx_shift_reg[6:0], mosi};
                    end
                end
            end

        end
    end

endmodule
