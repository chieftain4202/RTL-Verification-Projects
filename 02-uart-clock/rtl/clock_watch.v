`timescale 1ns / 1ps

module Top_stopwatch (
    input        clk,
    input        reset,
    input        btn_r,
    input        btn_d,
    input        btn_u,
    input        btn_l,
    input        sw,         // up/down mode for stopwatch
    input        uart_rx,
    output       uart_tx,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour

);

    wire [13:0] w_counter;
    wire w_run_stop, w_clear, w_mode;
    wire o_btn_run_stop, o_btn_run_clear;
    wire o_btn_up, o_btn_down, o_btn_left, o_btn_right;
    wire w_up, w_down, w_left, w_right;
    wire [23:0] w_stopwatch_time;
    wire [23:0] w_clock_time;
    wire [23:0] w_mux_out;

    wire [7:0] w_rx_data;
    wire w_rx_done;
    wire [2:0] w_btn_con;
    wire [2:0] w_asc_dcd;
    wire w_hour_up, w_hour_down, w_min_up, w_min_down, w_sec_up, w_sec_down;
    wire [3:0] w_sw;
/*
   
    btn_debounce U_BD_RIGHT (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );

    btn_debounce U_BD_LEFT (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_run_clear)
    );

    btn_debounce U_BD_UP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_u),
        .o_btn(o_btn_up)
    );

    btn_debounce U_BD_DOWN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(o_btn_down)
    );

    btn_debounce U_BD_RESET (
        .clk  (clk),
        .reset(reset),
        .i_btn(),
        .o_btn(o_btn_left)
    );
*/
    control_unit U_CONTROL_UNIT (
        .clk        (clk),
        .reset      (reset),
        .i_mode     (w_sw[0]),
        .sw_1       (w_sw[1]),
        .sw_2       (w_sw[2]),
        .i_rx_data  (w_asc_dcd),
        .i_btn_dcd  (w_btn_con),
        .o_mode     (w_mode),
        .o_run_stop (w_run_stop),
        .o_clear    (w_clear),
        .o_hour_up  (w_hour_up),
        .o_hour_down(w_hour_down),
        .o_min_up   (w_min_up),
        .o_min_down (w_min_down),
        .o_sec_up   (w_sec_up),
        .o_sec_down (w_sec_down)


    );


    mux_2 U_MUX_2 (
        .mux_in_stop(w_stopwatch_time),
        .mux_in_clock(w_clock_time),
        .mode(w_sw[1]),
        .mux_out(w_mux_out)
    );

    clock_datapath U_CLOCK_DATAPATH (
        .clk(clk),
        .reset(reset),
        .hour_up(w_hour_up),
        .hour_down(w_hour_down),
        .min_up(w_min_up),
        .min_down(w_min_down),
        .sec_up(w_sec_up),
        .sec_down(w_sec_down),
        .msec(w_clock_time[6:0]),
        .sec(w_clock_time[12:7]),
        .min(w_clock_time[18:13]),
        .hour(w_clock_time[23:19])
    );
    

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (sw),
        .clear   (w_clear),
        .run_stop(w_run_stop),
        .msec    (w_stopwatch_time[6:0]),    //7bit
        .sec     (w_stopwatch_time[12:7]),   //6bit  
        .min     (w_stopwatch_time[18:13]),  //6bit      
        .hour    (w_stopwatch_time[23:19])   //6bit
    );

    assign msec = w_stopwatch_time[6:0];
    assign sec  = w_stopwatch_time[12:7];
    assign min  = w_stopwatch_time[18:13];
    assign hour = w_stopwatch_time[23:19];

/*
    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_mux_out),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );


    uart_top U_UART_TOP (
        .clk(clk),
        .rst(reset),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .uart_rx_data(w_rx_data),
        .uart_rx_done(w_rx_done)
    );

    ascii_decoder U_ASC_DCD (
        .clk(clk),
        .rst(reset),
        .uart_rx_ascii(w_rx_data),
        .uart_rx_done(w_rx_done),
        .o_asc_dcd(w_asc_dcd)
    );
*/
    btn_decoder U_BTN_DCD (
        .i_btn_l  (btn_l),
        .i_btn_r  (btn_r),
        .i_btn_u  (btn_u),
        .i_btn_d  (btn_d),
        .i_btn_c  (reset),
        .o_btn_dcd(w_btn_con)
    );


endmodule


module mux_rx_btn (
    input [2:0] i_rx,
    input [2:0] i_btn,
    output o_rx_btn_mux

);
    assign i_rx  = o_rx_btn_mux;
    assign i_btn = o_rx_btn_mux;

endmodule


module btn_decoder (
    input i_btn_l,
    input i_btn_r,
    input i_btn_u,
    input i_btn_d,
    input i_btn_c,
    output reg [2:0] o_btn_dcd
);
    always @(*) begin
        if (i_btn_l) begin
            o_btn_dcd = 3'd0;
        end else if (i_btn_r) begin
            o_btn_dcd = 3'd1;
        end else if (i_btn_u) begin
            o_btn_dcd = 3'd2;
        end else if (i_btn_d) begin
            o_btn_dcd = 3'd3;
        end else if (i_btn_c) begin
            o_btn_dcd = 3'd4;
        end else o_btn_dcd = 3'd5;

    end

endmodule



module mux_2 (
    input [23:0] mux_in_stop,
    input [23:0] mux_in_clock,
    input mode,
    output [23:0] mux_out
);
    assign mux_out = (mode) ? mux_in_clock : mux_in_stop;

endmodule



module clock_datapath (
    input clk,
    input reset,
    input hour_up,
    input hour_down,
    input min_up,
    input min_down,
    input sec_up,
    input sec_down,

    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;


    tick_counter_c #(
        .BIT_WIDTH(5),
        .TIMES(24),
        .DEFAULT_TIME(12)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_hour_tick),
        .up(hour_up),
        .down(hour_down),
        .o_count(hour),
        .o_tick()
    );

    tick_counter_c #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .DEFAULT_TIME(0)
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_min_tick),
        .up(min_up),
        .down(min_down),
        .o_count(min),
        .o_tick(w_hour_tick)
    );

    tick_counter_c #(
        .BIT_WIDTH(6),
        .TIMES(60),
        .DEFAULT_TIME(0)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .i_tick(w_sec_tick),
        .up(sec_up),
        .down(sec_down),
        .o_count(sec),
        .o_tick(w_min_tick)
    );

    tick_counter_c #(
        .BIT_WIDTH(7),
        .TIMES(100),
        .DEFAULT_TIME(0)
    ) msec_counter (
        .clk(clk),
        .i_tick(w_tick_100hz),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100Hz_2 U_TICK (
        .clk(clk),
        .reset(reset),
        .o_tick_100hz_2(w_tick_100hz)
    );


endmodule


// msec, sec, min, hour
// tick counter
module tick_counter_c #(
    parameter BIT_WIDTH = 7,
    parameter DEFAULT_TIME = 0,
    TIMES = 100
) (
    input clk,
    input reset,
    input i_tick,
    input clear,
    input up,
    input down,
    output [BIT_WIDTH-1:0] o_count,
    output reg o_tick
);

    //counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;


    //State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= DEFAULT_TIME;
        end else begin
            counter_reg <= counter_next;
        end
    end

    //next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (up) begin
            if (counter_reg == TIMES - 1) counter_next = 0;
            else counter_next = counter_reg + 1;

        end else if (down) begin
            if (counter_reg == 0) counter_next = TIMES - 1;
            else counter_next = counter_reg - 1;

        end else if (i_tick) begin
            if (counter_reg == TIMES - 1) begin
                counter_next = 0;
                o_tick = 1'b1;
            end else begin
                counter_next = counter_reg + 1;
            end
        end
    end

endmodule


module tick_gen_100Hz_2 (
    input      clk,
    input      reset,
    output reg o_tick_100hz_2
);
    parameter F_count = 100_000_000 / 100;
    reg [$clog2(F_count)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            o_tick_100hz_2 <= 1'b0;
        end else begin
            counter_r <= counter_r + 1;
            o_tick_100hz_2 <= 1'b0;
            if (counter_r == (F_count - 1)) begin
                counter_r <= 0;
                o_tick_100hz_2 <= 1'b1;
            end else begin
                o_tick_100hz_2 <= 1'b0;
            end
        end
    end

endmodule




module stopwatch_datapath (
    input clk,
    input reset,
    input mode,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour

);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    tick_counter_s #(
        .BIT_WIDTH(5),
        .TIMES(24)
    ) hour_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(w_hour_tick),
        .mode(mode),
        .run_stop(run_stop),
        .o_count(hour),
        .o_tick()
    );

    tick_counter_s #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) min_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(w_min_tick),
        .mode(mode),
        .run_stop(run_stop),
        .o_count(min),
        .o_tick(w_hour_tick)
    );

    tick_counter_s #(
        .BIT_WIDTH(6),
        .TIMES(60)
    ) sec_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(w_sec_tick),
        .mode(mode),
        .run_stop(run_stop),
        .o_count(sec),
        .o_tick(w_min_tick)
    );

    tick_counter_s #(
        .BIT_WIDTH(7),
        .TIMES(100)
    ) msec_counter (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(w_tick_100hz),
        .mode(mode),
        .run_stop(run_stop),
        .o_count(msec),
        .o_tick(w_sec_tick)
    );

    tick_gen_100Hz U_TICK (
        .clk(clk),
        .reset(reset),
        .i_run_stop(run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

// msec, sec, min, hour
// tick counter
module tick_counter_s #(
    parameter BIT_WIDTH = 7,
    TIMES = 100
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [BIT_WIDTH-1:0] o_count,
    output reg o_tick
);

    //counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;
    //State reg SL
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    //next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick & run_stop) begin
            if (mode == 1'b1) begin
                //down
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
            end else begin
                //up
                if (counter_reg == TIMES - 1) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule


module tick_gen_100Hz (
    input      clk,
    input      reset,
    input      i_run_stop,
    output reg o_tick_100hz
);
    parameter F_count = 100_000_000 / 100;
    reg [$clog2(F_count)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_run_stop) begin
                counter_r <= counter_r + 1;
                o_tick_100hz <= 1'b0;
                if (counter_r == (F_count - 1)) begin
                    counter_r <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    o_tick_100hz <= 1'b0;
                end
            end
        end
    end

endmodule
/*

    assign w_sw = {2'b00, sw, sw};
    assign w_asc_dcd = 3'b111;  // no UART command in this TB
    assign uart_tx = 1'b1;
    assign fnd_digit = 4'b1111;
    assign fnd_data = 8'hFF;

    btn_decoder U_BTN_DCD (
        .i_btn_l  (1'b0),
        .i_btn_r  (btn_u),  // run/stop code
        .i_btn_u  (1'b0),
        .i_btn_d  (1'b0),
        .i_btn_c  (btn_l),  // clear code
        .o_btn_dcd(w_btn_con)
    );

*/