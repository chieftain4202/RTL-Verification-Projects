`timescale 1ns / 1ps

module GPO (
    input        Pclk,
    input        Prst,
    input        Penable,
    input        Pwrite,
    input        Psel,
    input [31:0] Pwdata,
    input [31:0] Paddr,

    output logic [31:0] Prdata,
    output logic        Pready,

    output logic [15:0] gpo_out

);

    localparam [11:0] GPO_ctl_addr = 12'h000;
    localparam [11:0] GPO_odata_addr = 12'h004;

    logic we;
    logic [15:0] GPO_odata_reg, GPO_ctl_reg;

    assign we = (Penable & Pwrite & Psel);
    assign Pready = (Penable & Psel) ? 1'b1 : 1'b0;
    assign Prdata = (Paddr[11:0] == GPO_ctl_addr) ? {16'h0000,GPO_ctl_reg} : 
                    (Paddr[11:0] == GPO_odata_addr) ? {16'h0000,GPO_odata_reg}: 32'hxxxx_xxxx;

    always_ff @(posedge Pclk, posedge Prst) begin
        if (Prst) begin
            GPO_odata_reg <= 16'd0;
            GPO_ctl_reg   <= 16'd0;
        end else begin
            if (we) begin
                case (Paddr[11:0])
                    GPO_ctl_addr:   GPO_ctl_reg <= Pwdata[15:0];
                    GPO_odata_addr: GPO_odata_reg <= Pwdata[15:0];
                endcase
            end
        end
    end

    genvar i;
    generate
    for (i = 0; i < 16; i++) begin
        assign gpo_out[i] = (GPO_ctl_reg[i]) ? GPO_odata_reg[i] : 1'bz;
    end
    endgenerate

endmodule
