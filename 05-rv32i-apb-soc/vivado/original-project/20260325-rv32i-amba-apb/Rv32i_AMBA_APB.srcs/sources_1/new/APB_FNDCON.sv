`timescale 1ns / 1ps

module APB_FNDCON (
    input        Pclk,
    input        Prst,
    input        Penable,
    input        Pwrite,
    input        Psel,
    input [31:0] Pwdata,
    input [31:0] Paddr,

    output logic [31:0] Prdata,
    output logic        Pready,
    output logic [ 3:0] fnd_digit,
    output logic [ 7:0] fnd_data
);

    logic [15:0] ifnd;
    localparam [11:0] FND_odata_addr = 12'h000;
    localparam [11:0] FND_load_addr = 12'h004;

    logic [15:0] FND_odata_reg, FND_load_reg, FND_idata_reg;
    logic we;

    assign we = (Penable & Pwrite & Psel);
    assign Pready = (Penable & Psel) ? 1'b1 : 1'b0;

    always_ff @(posedge Pclk, posedge Prst) begin
        if (Prst) begin
            FND_odata_reg <= 0;
            FND_load_reg  <= 0;
        end else begin
            if (we) begin
                case (Paddr[11:0])
                    FND_load_addr:  FND_load_reg <= Pwdata[15:0];
                    FND_odata_addr: FND_odata_reg <= Pwdata[15:0];
                endcase
            end
        end
    end

    assign Prdata = (Paddr[11:0] == FND_odata_addr) ? {16'h0000,FND_odata_reg}  : 
                    (Paddr[11:0] == FND_load_addr) ? {16'h0000,FND_load_reg}: 32'hxxxx_xxxx;

    assign ifnd = FND_odata_reg[13:0];

    fnd_controller U_FND (
        .clk        (Pclk),
        .reset      (Prst),
        .fnd_in_data(ifnd),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data),
        .digit1     (FND_load_reg[3:0]),
        .digit10    (FND_load_reg[7:4]),
        .digit100   (FND_load_reg[11:8]),
        .digit1000  (FND_load_reg[15:12])
    );

endmodule

