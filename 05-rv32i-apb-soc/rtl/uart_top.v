`timescale 1ns / 1ps

module uart_top (
    input clk,
    input rst,
    input uart_rx,
    output uart_tx,


    output [7:0] uart_rx_data,
    output uart_rx_done

);

    wire w_b_tick, w_c_tick, w_rx_done;
    wire [7:0] w_rx_data;

    

    
    assign uart_rx_data = w_rx_data;
    assign uart_rx_done = w_rx_done;
    // btn_debounce U_BD_TX_START (
    //     .clk  (clk),
    //     .reset(rst),
    //     .i_btn(btn_down),
    //     .o_btn(w_tx_start)
    // );
endmodule

module uart_rx (
    input clk,
    input rst,
    input rx,
    input b_tick,
    output [7:0] rx_data,
    output rx_done
);

    localparam IDLE = 2'd0, START = 2'd1;
    localparam DATA = 2'd2, STOP = 2'd3;
    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_next, bit_cnt_reg;
    reg done_reg, done_next;
    reg [7:0] buf_reg, buf_next;

    assign rx_data = buf_reg;
    assign rx_done = done_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= 2'd0;
            b_tick_cnt_reg <= 5'd0;
            bit_cnt_reg    <= 3'd0;
            done_reg       <= 1'b0;
            buf_reg        <= 8'd0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end

    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;

        case (c_state)
            IDLE: begin
                done_next = 1'b0;
                b_tick_cnt_next = 5'd0;
                bit_cnt_next = 3'd0;
                if (b_tick & !rx) begin
                    n_state  = START;
                    buf_next = 8'd0;
                end
            end
            START: begin
                if (b_tick)
                    if (b_tick_cnt_reg == 7) begin
                        b_tick_cnt_next = 5'd0;
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        b_tick_cnt_next = 5'd0;
                        buf_next = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            buf_next = {rx, buf_reg[7:1]};
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick)
                    if (b_tick_cnt_reg == 15) begin
                        n_state   = IDLE;
                        done_next = 1'b1;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
        endcase
    end

endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,
    input  [7:0] tx_data,
    output       tx_busy,
    output       tx_done,
    output       uart_tx
);

    localparam [1:0] IDLE = 3'd0, START = 3'd1, DATA = 3'd2, STOP = 3'd3;

    reg [1:0] c_state, next_state;
    reg tx_reg, tx_next;  //for OUTPUT SL

    reg [3:0] bit_cnt_reg, bit_cnt_next;
    //busy, done
    reg tx_busy_reg, tx_busy_next, tx_done_reg, tx_done_next;
    //data_in_buf
    reg [7:0] data_in_buf_reg, data_in_buf_next;
    //16tick counter
    reg [3:0] bt_cnt16_reg, bt_cnt16_next;




    assign uart_tx = tx_reg;
    assign tx_busy = tx_busy_reg;
    assign tx_done = tx_done_reg;

    // SL
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 4'b0;
            tx_busy_reg     <= 1'b0;
            tx_done_reg     <= 1'b0;
            data_in_buf_reg <= 8'b0;
            bt_cnt16_reg    <= 4'b0;
        end else begin
            c_state         <= next_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            tx_busy_reg     <= tx_busy_next;
            tx_done_reg     <= tx_done_next;
            data_in_buf_reg <= data_in_buf_next;
            bt_cnt16_reg    <= bt_cnt16_next;
        end
    end

    //16tick done
    always @(*) begin
        bt_cnt16_next = bt_cnt16_reg;
        if (c_state == IDLE) begin
            bt_cnt16_next = 1'b0;
        end else begin
            if (b_tick == 1) begin
                if ((bt_cnt16_reg == 4'd15)) begin
                    bt_cnt16_next = 1'b0;
                end else begin
                    bt_cnt16_next = bt_cnt16_reg + 4'b1;
                end
            end
        end
    end

    // next_state CL
    always @(*) begin
        next_state = c_state;
        case (c_state)
            IDLE: if (tx_start) next_state = START;
            START: if ((b_tick) && (bt_cnt16_reg == 4'd15)) next_state = DATA;
            DATA:
            if ((b_tick) && (bt_cnt16_reg == 4'd15) && (bit_cnt_reg == 3'd7))
                next_state = STOP;
            STOP: if (bt_cnt16_reg == 4'd15) next_state = IDLE;
            default: next_state = c_state;
        endcase
    end

    // next_reg CL
    always @(*) begin
        tx_next = tx_reg;
        bit_cnt_next = bit_cnt_reg;
        tx_busy_next = tx_busy_reg;
        tx_done_next = tx_done_reg;
        data_in_buf_next = data_in_buf_reg;
        //tx_next, bit_cnt
        case (c_state)
            IDLE: begin
                tx_next          = 1'b1;
                bit_cnt_next     = 1'b0;
                tx_busy_next     = 1'b0;
                tx_done_next     = 1'b0;
                data_in_buf_next = tx_data;
            end
            START: begin
                tx_next = 1'b0;
                tx_busy_next = 1'b1;
            end
            DATA: begin
                tx_next = data_in_buf_reg[0];
                if (((b_tick) &&(bt_cnt16_reg == 4'd15)) && (bit_cnt_reg < 3'd7)) begin
                    bit_cnt_next = bit_cnt_reg + 1;
                    data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                end
            end
            STOP: begin
                tx_next = 1'b1;
                bit_cnt_next = 1'b0;
                if ((b_tick) && (bt_cnt16_reg == 4'd15)) begin
                    tx_done_next = 1'b1;
                end
            end
        endcase
    end
endmodule


module tick_counter_15 (
    input clk,
    input rst,
    input tick,
    output reg o_tick_c
);
    reg [4:0] counter_r, counter_n;

    // assign tick_c = tick_c_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 5'd0;
        end else begin
            counter_r <= counter_n;
        end
    end

    always @(*) begin
        counter_n = counter_r;
        o_tick_c  = 0;
        if (tick) begin
            counter_r = counter_r + 1;
        end
        if (counter_r == 16) begin
            o_tick_c  = 1;
            counter_r = 0;
        end else begin
            o_tick_c = 0;
        end

    end

endmodule



module baud_tick (
    input      clk,
    input      rst,
    output reg o_b_tick

);

    parameter BAUDRATE = 25000000;
    parameter F_COUNT = 100_000_000 / BAUDRATE;
    reg [$clog2(F_COUNT)-1 : 0] count_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            o_b_tick <= 1'b0;
            count_r  <= 0;
        end else begin
            o_b_tick <= 1'b0;
            count_r  <= count_r + 1;
            if (count_r == (F_COUNT - 1)) begin
                o_b_tick <= 1'b1;
                count_r  <= 0;
            end else begin
                o_b_tick <= 1'b0;
            end
        end
    end

endmodule
