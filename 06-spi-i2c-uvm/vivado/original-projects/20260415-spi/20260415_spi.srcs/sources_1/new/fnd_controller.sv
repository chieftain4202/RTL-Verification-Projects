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
    logic [7:0] one_reg, ten_reg, hun_reg, thou_reg, o_mem;
    logic [1:0] addr;

    digit_splitter U_DIGIT_SPL (
        .in_data   (o_mem),
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
        .sel       (btn),
        .mux_out   (w_mux_4X1_out)
    );

    decoder_2X4 U_DECODER_2X4 (
        .digit_sel(addr),
        .fnd_digit(fnd_digit)
    );

    bcd U_BCD (
        .bcd     (o_mem[3:0]),
        .fnd_data(fnd_data)
    );

    Mem U_mem (
        .clk  (clk),
        .addr (addr),
        .rst  (rst),
        .done (done),
        .idata(sum),
        .odata(o_mem)
    );

    counter u_btn_counter (
        .clk(clk),
        .rst(rst),
        .ibtn(ibtn),
        .ocount(addr)
    );

endmodule

module control (
    input  [7:0] idata,
    input        clk,
    input        rst,
    input        btn,
    output       odata
);
    localparam logic [1:0] one = 2'b00, ten = 2'b01, hun = 2'b10, thou = 2'b11;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin

        end
    end

endmodule


module Mem (
    input  logic       clk,
    input  logic       rst,
    input  logic [1:0] addr,
    input  logic       done,
    input  logic [7:0] idata,
    output logic [7:0] odata
);

    logic [7:0] mem[0:3];

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 4; i++) begin
                mem[i] <= 0;
            end
        end else begin
            if (done) begin
                mem[addr] <= idata;
            end
        end
    end

    assign odata = mem[addr];

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
