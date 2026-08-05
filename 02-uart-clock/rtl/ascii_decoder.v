`timescale 1ns / 1ps


module ascii_decoder (
    input [7:0] uart_rx_ascii,
    input clk,
    input rst,
    input uart_rx_done,
    output reg [2:0] o_asc_dcd

);


    reg [1:0] current_st, next_st;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            o_asc_dcd <= 3'd6;
        end else begin
            current_st <= next_st;
        end
    end


    always @(*) begin
        o_asc_dcd = 3'd6;
        if (uart_rx_done) begin
            case (uart_rx_ascii)
                8'h72:   o_asc_dcd = 3'd1;  //r btn_r
                8'h61:   o_asc_dcd = 3'd0;  //a btn_l
                8'h64:   o_asc_dcd = 3'd2;  //d btn_u
                8'h73:   o_asc_dcd = 3'd3;  //s btn_d
                8'h63:   o_asc_dcd = 3'd4;  //c btn_reset
                8'h62:   o_asc_dcd = 3'd5;
                default: o_asc_dcd = 3'd6;
            endcase
        end else begin
            o_asc_dcd <= 3'd6;
        end
    end



//  module ascii_sender (
//      input [23:0]clock,
//      input [23:0]stopwatch,
//      input [2:0]sw,
//      output [7:0]o_asc_send
//  );

   /* 
always @(posedge clk, posedge rst) begin
        if (rst) begin
            o_asc_dcd <= 3'd6;
        end else if (uart_rx_done) begin
            case (uart_rx_ascii)
                8'h72:   o_asc_dcd <= 3'd1;  //r btn_r
                8'h61:   o_asc_dcd <= 3'd0;  //a btn_l
                8'h64:   o_asc_dcd <= 3'd2;  //d btn_u
                8'h73:   o_asc_dcd <= 3'd3;  //s btn_d
                8'h63:   o_asc_dcd <= 3'd4;  //c btn_reset
                8'h62:   o_asc_dcd <= 3'd5;
                default: o_asc_dcd <= 3'd6;
            endcase
        end else begin
            o_asc_dcd <= 3'd6;
        end
    end
*/

endmodule