`timescale 1ns / 1ps


module spi_master (
    input  logic       clk,
    input  logic       rst,
    input  logic       sbtn,
    input  logic [7:0] sw,
    input logic       miso,
    output logic       sclk,
    output logic       mosi,
    output logic       cs_n,
    output logic [7:0] fnd_data,
    output logic [3:0] fnd_digit

);

    logic [7:0] slave_tx_data;

    logic [7:0] master_rx_data;
    logic       master_done;
    logic       master_busy;
    logic [7:0] slave_rx_data;
    logic       slave_done;
    logic       slave_busy;

    logic       cpol;
    logic       cpha;
    //logic [7:0] clk_div;
    logic [7:0] master_tx_data;
    logic       master_start;

    logic       obtn;
    logic       osbtn;
    logic       sdone;
    logic [2:0] bit_cnt;
    logic [7:0] s_tx_data;
    logic [7:0] sw_data;

    fnd_controller u_fnd (
        .sum      (master_rx_data),
        .clk      (clk),
        .rst      (rst),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    SPI_master u_master (
        .clk    (clk),
        .rst    (rst),
        .cpol   (0),
        .cpha   (0),
        .clk_div(8'd4),
        .tx_data(sw_data),
        .start  (master_busy),
        .miso   (miso),
        .rx_data(master_rx_data),
        .done   (master_done),
        .busy   (master_busy),
        .sclk   (sclk),
        .mosi   (mosi),
        .cs_n   (cs_n),
        .t_idle (),
        .bit_cnt(bit_cnt)
    );

    sw_data u_sw_data (
        .sw      (sw),
        .hex_data(sw_data)
    );

    btn_debounce u_btn_debounce_start (
        .clk  (clk),
        .reset(rst),
        .i_btn(sbtn),
        .o_btn(osbtn)
    );
endmodule



module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);


    // clock divider for debounce shift register
    // 100MHZ -> 100khz
    // counter -> 100M/100K = 1000
    parameter CLK_DIV = 1000_000;
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg clk_100khz_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            clk_100khz_reg <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                clk_100khz_reg <= 1'b1;
            end else begin
                clk_100khz_reg <= 1'b0;
            end
        end
    end

    //series 8 tap F/F
    //1 reg [7:0] debounce_reg;
    reg [7:0] q_reg, q_next;
    wire debounce;

    //SL
    always @(posedge clk_100khz_reg, posedge reset) begin
        if (reset) begin
            //1 debounce_reg <= 0;
            q_reg <= 0;
        end else begin
            //shift register
            //1  debounce_reg <= {i_btn, debounce_reg[7:1]}
            q_reg <= q_next;
        end
    end

    //next CL
    always @(*) begin
        q_next = {i_btn, q_reg[7:1]};
    end

    //debounce, 8input AND
    assign debounce = &q_reg;

    reg edge_reg;
    //edge detection
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end
    assign o_btn = debounce & {~edge_reg};

endmodule




module sw_data (
    input  logic [7:0] sw,
    output logic [7:0] hex_data
);

assign hex_data = {sw};
/*
    always_comb begin
        if (sw <= 8'hff) begin
            hex_data = {sw};
        end else begin
            hex_data = 8'h00;
        end
    end
*/
endmodule


module SPI_master (
    input  logic       clk,
    input  logic       rst,
    input  logic       cpol,     // idel 0: Low, 1: high
    input  logic       cpha,     // first sampling, 0: first edge, 1:second edge
    input  logic [7:0] clk_div,
    input  logic [7:0] tx_data,
    input  logic       start,
    input  logic       miso,
    output logic [7:0] rx_data,
    output logic       done,
    output logic       busy,
    output logic       sclk,
    output logic       mosi,
    output logic       cs_n,
    output logic       t_idle,
    output logic [2:0] bit_cnt
);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e state;
    logic [7:0] div_cnt, tx_shift_reg, rx_shift_reg;
    //logic [2:0] bit_cnt;
    logic half_tick, step, sclk_r;


    assign sclk = sclk_r;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (div_cnt == clk_div) begin
                div_cnt   <= 0;
                half_tick <= 1'b1;
            end else begin
                div_cnt   <= div_cnt + 1;
                half_tick <= 1'b0;
            end
        end
    end


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            mosi         <= 1'b1;
            cs_n         <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            step         <= 1'b0;
            rx_data      <= 0;
            sclk_r       <= 1'b0;
            t_idle       <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    mosi   <= 1'b1;
                    cs_n   <= 1'b1;
                    sclk_r <= cpol;
                    t_idle <= 0;
                    if (!start) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt      <= 0;
                        step         <= 1'b0;
                        busy         <= 1'b1;
                        cs_n         <= 1'b0;
                        state        <= START;
                    end
                end

                START: begin
                    if (!cpha) begin
                        mosi         <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    end
                    state <= DATA;

                end

                DATA: begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r;
                        if (step == 0) begin  // 수신 구간
                            step <= 1'b1;
                            if (!cpha) begin
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end else begin
                                mosi         <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end

                        end else begin  // 송신 구간
                            step <= 1'b0;
                            if (!cpha) begin
                                if (bit_cnt < 7) begin
                                    mosi         <= tx_shift_reg[7];
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                    state        <= DATA;
                                end
                            end else begin
                                rx_shift_reg <= {rx_shift_reg[6:0], miso};
                            end
                            if (bit_cnt == 7) begin
                                state <= STOP;
                                if (!cpha) begin
                                    rx_data <= rx_shift_reg;
                                end else begin
                                    rx_data <= rx_shift_reg;
                                    rx_data <= {rx_shift_reg[6:0], miso};
                                end
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end

                    end
                end

                STOP: begin
                    sclk_r <= 1'b0;
                    cs_n   <= 1'b1;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                    mosi   <= 1'b1;
                    t_idle <= 1'b1;
                    state  <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end

    end



endmodule


`timescale 1ns / 1ps


module fnd_controller (
    input  [7:0] sum,
    input        clk,
    input        rst,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);
    localparam int unsigned SCAN_DIV = 100_000;

    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_mux_4X1_out;
    logic [$clog2(SCAN_DIV)-1:0] scan_cnt;
    logic [1:0] addr;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            scan_cnt <= '0;
            addr     <= 2'b00;
        end else begin
            if (scan_cnt == SCAN_DIV - 1) begin
                scan_cnt <= '0;
                addr     <= addr + 2'b01;
            end else begin
                scan_cnt <= scan_cnt + 1'b1;
            end
        end
    end

    digit_splitter U_DIGIT_SPL (
        .in_data   (sum),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux_4X1 U_MUX_4X1 (
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000),
        .sel       (addr),
        .mux_out   (w_mux_4X1_out)
    );

    decoder_2X4 U_DECODER_2X4 (
        .digit_sel(addr),
        .fnd_digit(fnd_digit)
    );

    bcd U_BCD (
        .bcd     (w_mux_4X1_out),
        .fnd_data(fnd_data)
    );

endmodule



//to select to fnd digit display
module decoder_2X4 (
    input [1:0] digit_sel,
    output reg [3:0] fnd_digit
);
    always @(digit_sel) begin
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;
        endcase
    end
endmodule

module mux_4X1 (
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    input [1:0] sel,
    output reg [3:0] mux_out
);

    always @(*) begin
        case (sel)
            2'b00: mux_out = digit_1;
            2'b01: mux_out = digit_10;
            2'b10: mux_out = digit_100;
            2'b11: mux_out = digit_1000;
        endcase
    end

endmodule

module digit_splitter (
    input  [7:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000

);

    assign digit_1 = in_data % 10;
    assign digit_10 = (in_data / 10) % 10;
    assign digit_100 = (in_data / 100) % 10;
    assign digit_1000 = (in_data / 1000) % 10;

endmodule

module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data  //always output always Reg
);

    always @(bcd) begin
        case (bcd)
            4'd0: fnd_data = 8'hC0;
            4'd1: fnd_data = 8'hf9;
            4'd2: fnd_data = 8'ha4;
            4'd3: fnd_data = 8'hb0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hf8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            default: fnd_data = 8'hFF;
        endcase
    end

endmodule
