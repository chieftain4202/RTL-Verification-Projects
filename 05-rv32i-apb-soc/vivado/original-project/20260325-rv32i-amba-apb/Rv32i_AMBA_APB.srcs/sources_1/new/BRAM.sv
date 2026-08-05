`timescale 1ns / 1ps

module BRAM (
    input        Pclk,
    input        Prst,
    input        Penable,
    input        Pwrite,
    input        Psel,
    input [31:0] Pwdata,
    input [31:0] Paddr,

    output logic [31:0] Prdata,
    output logic        Pready

);

    logic [31:0] bmem[0:1024];

    assign Pready = (Penable & Psel) ? 1'b1 : 1'b0;

    always_ff @(posedge Pclk) begin
        if (Pwrite & Psel & Penable) bmem[Paddr[11:2]] <= Pwdata;
    end

    assign Prdata = bmem[Paddr[11:2]];

endmodule
