`timescale 1ns / 1ps

module demo_slave (
    input  logic       clk,
    input  logic       rst,
    input  logic       sscl,
    inout  wire        ssda,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);

    logic [7:0] slave_rx_data;
    logic [7:0] slave_tx_data;

    assign slave_tx_data = 8'h00;

    ds_i2c_slave u_i2c_slave (
        .clk    (clk),
        .rst    (rst),
        .tx_data(slave_tx_data),
        .rx_data(slave_rx_data),
        .scl    (sscl),
        .sda    (ssda)
    );

    ds_fnd_controller u_fnd (
        .sum      (slave_rx_data),
        .clk      (clk),
        .rst      (rst),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

endmodule

module ds_i2c_slave (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    input  logic       scl,
    inout  wire        sda
);

    typedef enum logic [2:0] {
        IDLE,
        ADDR,
        DATA_ACK,
        W_DATA,
        R_DATA,
        STOP
    } i2c_state_e;

    logic sda_o;
    logic sda_i;
    logic sda_r;
    logic edge_scl;
    logic edge_sda;
    logic scl_rise;
    logic scl_fall;
    logic sda_rise;
    logic [3:0] bit_cnt;
    logic [1:0] step;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [7:0] rx_data_reg;
    localparam logic [6:0] FND_SLAVE_ADDR = 7'b011_1000;
    i2c_state_e state;

    assign sda_i   = sda;
    assign sda     = sda_o ? 1'bz : 1'b0;
    assign sda_o   = sda_r;
    assign rx_data = rx_data_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_scl <= 1'b0;
        end else begin
            edge_scl <= scl;
        end
    end

    assign scl_rise = ~edge_scl & scl;
    assign scl_fall = ~scl & edge_scl;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_sda <= 1'b0;
        end else begin
            edge_sda <= sda;
        end
    end

    assign sda_rise = ~edge_sda & sda_i & scl;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            sda_r        <= 1'b1;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            rx_data_reg   <= 8'd0;
            bit_cnt      <= 4'd0;
            step         <= 2'd0;
        end else begin
            case (state)
                IDLE: begin
                    sda_r <= 1'b1;
                    if (scl_fall) begin
                        state        <= ADDR;
                        step         <= 2'd0;
                        bit_cnt      <= 4'd0;
                        tx_shift_reg <= tx_data;
                    end
                end

                ADDR: begin
                    if (scl_rise) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                    end
                    if (scl_fall) begin
                        bit_cnt <= bit_cnt + 4'd1;
                        if (bit_cnt == 4'd7) begin
                            bit_cnt <= 4'd0;
                            if (rx_shift_reg[7:1] == FND_SLAVE_ADDR) begin
                                sda_r <= 1'b0;
                                state <= DATA_ACK;
                            end else begin
                                sda_r <= 1'b1;
                                state <= IDLE;
                            end
                        end
                    end
                end

                DATA_ACK: begin
                    if (scl_fall) begin
                        sda_r <= 1'b1;
                        if (rx_shift_reg[0]) begin
                            state <= W_DATA;
                        end else begin
                            state <= R_DATA;
                        end
                    end
                end

                W_DATA: begin
                    if (scl_rise) begin
                        sda_r        <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        bit_cnt      <= bit_cnt + 4'd1;
                        if (bit_cnt == 4'd7) begin
                            bit_cnt <= 4'd0;
                            state   <= DATA_ACK;
                        end
                    end
                end

                R_DATA: begin
                    if (scl_rise) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                    end
                    if (scl_fall) begin
                        bit_cnt <= bit_cnt + 4'd1;
                        if (bit_cnt == 4'd7) begin
                            rx_data_reg <= rx_shift_reg;
                            sda_r       <= 1'b0;
                            state       <= DATA_ACK;
                            bit_cnt     <= 4'd0;
                        end
                    end
                end

                STOP: begin
                    step <= 2'd0;
                    case (step)
                        2'd0: begin
                            if (scl_rise) begin
                                step <= 2'd1;
                            end
                        end
                        2'd1: begin
                            if (sda_rise) begin
                                state <= IDLE;
                                step  <= 2'd0;
                            end
                        end
                    endcase
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

module ds_fnd_controller (
    input  logic [7:0] sum,
    input  logic       clk,
    input  logic       rst,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);
    logic [3:0] digit_1;
    logic [3:0] digit_10;
    logic [3:0] digit_100;
    logic [3:0] digit_1000;
    logic [3:0] mux_out;
    logic [1:0] digit_sel;
    logic       refresh_tick;

    ds_digit_splitter u_digit_splitter (
        .in_data   (sum),
        .digit_1   (digit_1),
        .digit_10  (digit_10),
        .digit_100 (digit_100),
        .digit_1000(digit_1000)
    );

    ds_mux_4x1 u_mux (
        .digit_1   (digit_1),
        .digit_10  (digit_10),
        .digit_100 (digit_100),
        .digit_1000(digit_1000),
        .sel       (digit_sel),
        .mux_out   (mux_out)
    );

    ds_decoder_2x4 u_decoder (
        .digit_sel(digit_sel),
        .fnd_digit(fnd_digit)
    );

    ds_bcd u_bcd (
        .bcd     (mux_out),
        .fnd_data(fnd_data)
    );

    ds_clk_div u_refresh_div (
        .clk    (clk),
        .reset  (rst),
        .o_1khz (refresh_tick)
    );

    ds_counter_4 u_counter (
        .clk      (refresh_tick),
        .reset    (rst),
        .digit_sel(digit_sel)
    );
endmodule

module ds_digit_splitter (
    input  logic [7:0] in_data,
    output logic [3:0] digit_1,
    output logic [3:0] digit_10,
    output logic [3:0] digit_100,
    output logic [3:0] digit_1000
);
    always_comb begin
        digit_1    = in_data % 10;
        digit_10   = (in_data / 10) % 10;
        digit_100  = (in_data / 100) % 10;
        digit_1000 = (in_data / 1000) % 10;
    end
endmodule

module ds_mux_4x1 (
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_1000,
    input  logic [1:0] sel,
    output logic [3:0] mux_out
);
    always_comb begin
        case (sel)
            2'b00: mux_out = digit_1;
            2'b01: mux_out = digit_10;
            2'b10: mux_out = digit_100;
            2'b11: mux_out = digit_1000;
        endcase
    end
endmodule

module ds_decoder_2x4 (
    input  logic [1:0] digit_sel,
    output logic [3:0] fnd_digit
);
    always_comb begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;
        endcase
    end
endmodule

module ds_bcd (
    input  logic [3:0] bcd,
    output logic [7:0] fnd_data
);
    always_comb begin
        case (bcd)
            4'd0: fnd_data = 8'hC0;
            4'd1: fnd_data = 8'hF9;
            4'd2: fnd_data = 8'hA4;
            4'd3: fnd_data = 8'hB0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hF8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            default: fnd_data = 8'hFF;
        endcase
    end
endmodule

module ds_clk_div (
    input  logic clk,
    input  logic reset,
    output logic o_1khz
);
    logic [$clog2(100_000):0] counter_r;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= '0;
            o_1khz   <= 1'b0;
        end else begin
            if (counter_r == 17'd99_999) begin
                counter_r <= '0;
                o_1khz   <= 1'b1;
            end else begin
                counter_r <= counter_r + 1'b1;
                o_1khz   <= 1'b0;
            end
        end
    end
endmodule

module ds_counter_4 (
    input  logic       clk,
    input  logic       reset,
    output logic [1:0] digit_sel
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            digit_sel <= 2'd0;
        end else begin
            digit_sel <= digit_sel + 2'd1;
        end
    end
endmodule
