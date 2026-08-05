`timescale 1ns / 1ps

module GPI (
    input               Pclk,
    input               Prst,
    input               Penable,
    input               Pwrite,
    input               Psel,
    input        [31:0] Pwdata,
    input        [31:0] Paddr,
    input        [15:0] idata,
    output logic        Pready,
    output logic [31:0] Prdata
);

    localparam [11:0] GPI_ctl_addr = 12'h000;
    localparam [11:0] GPI_idata_addr = 12'h004;
    logic [15:0] GPI_idata_reg, GPI_ctl_reg;
    logic re;

    assign re = (Psel & Penable) ? 1'b1 : 1'b0;
    assign Pready = (Penable & Psel) ? 1'b1 : 1'b0;

    assign Prdata = (Paddr[11:0] == GPI_ctl_addr) ? {16'h0000,GPI_ctl_reg} : 
                    (Paddr[11:0] == GPI_idata_addr) ? {16'h0000,GPI_idata_reg}: 32'hxxxx_xxxx;

    always_ff @(posedge Pclk, posedge Prst) begin
        if (Prst) begin
            GPI_ctl_reg <= 16'd0;
        //    GPI_idata_reg <= 16'd0;
        end else if (re) begin
            case (Paddr[11:0])
                GPI_ctl_addr: GPI_ctl_reg <= Pwdata[15:0];
            endcase
        end

    end

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign GPI_idata_reg[i] = (GPI_ctl_reg[i]) ? idata[i] : 1'bz;
        end
    endgenerate

endmodule
