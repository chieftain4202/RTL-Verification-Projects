`timescale 1ns / 1ps

module control_unit (
    input clk,
    input reset,
    input i_mode,
    input sw_1,
    input sw_2,
    input [2:0] i_rx_data,
    input [2:0] i_btn_dcd,
//

    output reg o_run_stop,
    output o_mode,
    output reg o_clear,
    output reg o_hour_up,
    output reg o_hour_down,
    output reg o_min_up,
    output reg o_min_down,
    output reg o_sec_up,
    output reg o_sec_down

);


   reg i_left, i_run_stop, i_right, i_down, i_clear, i_up;

    assign o_mode = i_mode;

    always @(*) begin
        i_clear    = 1'b0;
        i_run_stop = 1'b0;
        i_left     = 1'b0;
        i_right    = 1'b0;
        i_up       = 1'b0;
        i_down     = 1'b0;

        if(sw_1 == 0)begin
        case (i_btn_dcd)
            3'b010: i_run_stop = 1'b1;  // run/stop
            3'b100: i_clear = 1'b1;
            default: begin
            end
            endcase
            case (i_rx_data)
            3'b001: i_run_stop = 1'b1;  // run/stop
            3'b100: i_clear = 1'b1;
            default: begin
            end
        endcase 
        
        end
        if(sw_1 == 1)begin
        case (i_btn_dcd)
            3'b100: i_left = 1'b1;  
            3'b001: i_right = 1'b1;
            3'b011: i_down = 1'b1;
            3'b010: i_up = 1'b1;
            default: begin
            end
        endcase
         case (i_rx_data)
            3'b000: i_left = 1'b1;  
            3'b101: i_right = 1'b1;
            3'b011: i_down = 1'b1;
            3'b010: i_up = 1'b1;
            3'b100: i_clear = 1'b1;
            default: begin
            end
        endcase 
        end
      /*  case (i_rx_data)
            3'b001: i_run_stop = 1'b1;  // run/stop
            3'b100: i_clear = 1'b1;
            3'b000: i_left = 1'b1;  
            3'b101: i_right = 1'b1;
            3'b011: i_down = 1'b1;
            3'b010: i_up = 1'b1;
            default: begin
            end
        endcase */
    end



    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    reg [2:0] current_st, next_st;


    //state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= STOP;
        end else if (sw_1 == 0) begin
            current_st <= next_st;
        end
    end


    always @(*) begin
        next_st = current_st;
        o_run_stop = 1'b0;
        o_clear = 1'b0;
        case (current_st)
            STOP: begin
                //moore output
                o_run_stop = 1'b0;
                o_clear = 1'b0;
                if (i_run_stop) begin
                    next_st = RUN;
                end else if (i_clear) begin
                    next_st = CLEAR;
                end
            end
            RUN: begin
                o_run_stop = 1'b1;
                o_clear = 1'b0;
                if (i_run_stop) begin
                    next_st = STOP;
                end
            end
            CLEAR: begin
                o_run_stop = 1'b0;
                o_clear = 1'b1;
                next_st = STOP;
            end
        endcase
    end

    localparam SEL_HOUR = 2'b00;
    localparam SEL_MIN  = 2'b01;
    localparam SEL_SEC  = 2'b10;

reg [2:0] clk_st, clk_next;

always @(posedge clk, posedge reset) begin
    if (reset) begin
        clk_st <= SEL_HOUR; 
    end else if (sw_1 == 1) begin 
        clk_st <= clk_next;
    end
end

always @(*) begin

    clk_next = clk_st;

    o_hour_up   = 1'b0;
    o_hour_down = 1'b0;
    o_min_up    = 1'b0;
    o_min_down  = 1'b0;
    o_sec_up    = 1'b0;
    o_sec_down  = 1'b0;

    case (clk_st)

        SEL_HOUR: begin
            if (i_left) begin
                clk_next = SEL_SEC;
            end else if (i_right) begin
                clk_next = SEL_MIN;
            end else if (i_up) begin
                o_hour_up = 1'b1;
            end else if (i_down) begin
                o_hour_down = 1'b1;
            end
        end


        SEL_MIN: begin
            if (i_left) begin
                clk_next = SEL_HOUR;
            end else if (i_right) begin
                clk_next = SEL_SEC;
            end else if (i_up) begin
                o_min_up = 1'b1;
            end else if (i_down) begin
                o_min_down = 1'b1;
            end
        end

        SEL_SEC: begin
            if (i_left) begin
                clk_next = SEL_MIN;
            end else if (i_right) begin
                clk_next = SEL_HOUR;
            end else if (i_up) begin
                o_sec_up = 1'b1;
            end else if (i_down) begin
                o_sec_down = 1'b1;
            end 
        end
    endcase
end


endmodule