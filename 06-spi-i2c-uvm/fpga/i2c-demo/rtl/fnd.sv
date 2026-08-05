`timescale 1ns / 1ps


module fnd_controller (
    input  [7:0] sum,
    input  [1:0] btn,
    input        clk,
    input        rst,
    input        ibtn,
    input        done,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_mux_4X1_out;
    logic [7:0] display_data;
    logic [1:0] addr;
    logic [1:0] digit_sel;
    logic refresh_tick;

    digit_splitter U_DIGIT_SPL (
        .in_data   (display_data),
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
        .sel       (digit_sel),
        .mux_out   (w_mux_4X1_out)
    );

    decoder_2X4 U_DECODER_2X4 (
        .digit_sel(digit_sel),
        .fnd_digit(fnd_digit)
    );

    bcd U_BCD (
        .bcd     (w_mux_4X1_out),
        .fnd_data(fnd_data)
    );

    assign display_data = sum;

    counter u_btn_counter (
        .clk(clk),
        .rst(rst),
        .ibtn(ibtn),
        .ocount(addr)
    );

    clk_div u_refresh_div (
        .clk   (clk),
        .reset (rst),
        .o_1khz(refresh_tick)
    );

    counter_4 counter (
        .clk(refresh_tick),
        .reset(rst),
        .digit_sel(digit_sel)
    );

endmodule



module Mem (
    input  logic       clk,
    input  logic       rst,
    input  logic [1:0] addr,
    input  logic       done,
    input  logic [7:0] idata,
    output logic [7:0] odata
);

    logic [7:0] mem;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            mem <= 0;

        end else begin
            if (done) begin
                mem <= idata;
            end
        end
    end

    assign odata = mem;

endmodule



module counter (
    input  logic       clk,
    input  logic       rst,
    input  logic       ibtn,
    output logic [1:0] ocount
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            ocount <= 0;
        end else begin
            if (ibtn) begin
                if (ocount == 2'b11) begin
                    ocount <= 2'b00;
                end else ocount <= ocount + 1;

            end
        end

    end

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

module clk_div (
    input clk,
    input reset,
    output reg o_1khz
);

    // reg [16:0] counter_r; //module 다르니 다른 변수
    reg [$clog2(
100_000
):0] counter_r;  //로그로 하면 알아서 bit로 바꿔줌 

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0; // 초기화 안 하면 그냥 X로 출력함 - 일을 안함
            o_1khz <= 1'b0;
        end else begin
            if (counter_r == 99999) begin
                counter_r <= 0;
                o_1khz <= 1'b1;
            end else begin
                counter_r <= counter_r + 1; //9999까지만 가야하므로 조건 필요함
                o_1khz <= 1'b0;
            end
        end

    end

endmodule

module counter_4 (
    input        clk,
    input        reset,
    output [1:0] digit_sel
);
    // 순차논리는 항상 always 구문 사용

    reg [1:0] counter_r;

    assign digit_sel = counter_r; // reg 다음에 assign 나오기 이래야지 오류 안남 

    always @(posedge clk, posedge reset) begin
        //초기화 먼저
        if (reset == 1) begin // 괄호 안에 그냥 reset만 적으면 자동적으로 1이면 실행하고 그렇긴 함 
            // init counter_r을 0으로 초기화 
            counter_r <= 0; //순차논리에서는 부등호 사용하고 = 사용 , 이 방향으로 내보내는데 nonblocking
        end else begin
            //to do
            counter_r <= counter_r + 1;  //2bit이므로, 0~3으로만 나옴 
        end
    end
endmodule
