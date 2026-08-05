`timescale 1ns / 1ps

module Top_stopwatch (
    input        clk,
    input        reset,
    input        btn_r,      //i_run_stop
    input        btn_l,      //i_clear
    input  [2:0] sw,         //sw[0] up/down
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [13:0] w_counter;
    wire w_run_stop, w_clear, w_mode;
    wire o_btn_run_stop, o_btn_run_clear;
    wire [23:0] w_stopwatch_time;

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_run_clear)
    );

    control_unit U_CONTROL_UNIT (
        .clk       (clk),
        .reset     (reset),
        .i_mode    (sw),
        .i_run_stop(o_btn_run_stop),
        .i_clear   (o_btn_run_clear),
        .o_mode    (w_mode),
        .o_run_stop(w_run_stop),
        .o_clear   (w_clear)

    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_mode),
        .clear   (w_clear),
        .run_stop(w_run_stop),
        .msec    (w_stopwatch_time[6:0]),    //7bit
        .sec     (w_stopwatch_time[12:7]),   //6bit  
        .min     (w_stopwatch_time[18:13]),  //6bit      
        .hour    (w_stopwatch_time[23:19])   //6bit
    );


    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_stopwatch_time),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );


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

    tick_counter #(
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

    tick_counter #(
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

    tick_counter #(
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

    tick_counter #(
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
module tick_counter #(
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






