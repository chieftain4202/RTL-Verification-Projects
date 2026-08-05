`timescale 1ns / 1ps
//`include "define.vh"


module Amba_apb ();


endmodule

module apb_master (
    input Pclk,
    input Prst,

    input [31:0] addr,
    input [31:0] wdata,
    input        Wreq,
    input        Rreq,

    output logic        Ready,
    output       [31:0] Rdata,

    output logic Penable,
    output logic Pwrite,

    output logic [31:0] Pwdata,
    output logic [31:0] Paddr,

    output logic [31:0] Psel_0,  // RAN
    output logic [31:0] Psel_1,  // GPO
    output logic [31:0] Psel_2,  // GPI
    output logic [31:0] Psel_3,  // GPIO
    output logic [31:0] Psel_4,  // FND
    output logic [31:0] Psel_5,  // UART

    input [31:0] Prdata_0,  // from RAM
    input [31:0] Prdata_1,  // from GPO
    input [31:0] Prdata_2,  // from GPI
    input [31:0] Prdata_3,  // from GPIO
    input [31:0] Prdata_4,  // from FND
    input [31:0] Prdata_5,  // from UART

    input Pready0,  //from RAM    
    input Pready1,  //from GPO
    input Pready2,  //from GPI
    input Pready3,  //from GPIO
    input Pready4,  //from FND
    input Pready5   //from UART
);

    logic decode_en;
    /*
    register u_addr (
        .clk  (Pclk),
        .rst  (Prst),
        .idata(),
        .odata()
    );

    register u_wdata (
        .clk  (Pclk),
        .rst  (Prst),
        .idata(),
        .odata()
    );
*/
    apb_mux u_mux (
        .sel     (Paddr),
        .Prdata_0(Prdata_0),
        .Prdata_1(Prdata_1),
        .Prdata_2(Prdata_2),
        .Prdata_3(Prdata_3),
        .Prdata_4(Prdata_4),
        .Prdata_5(Prdata_5),
        .Pready0 (Pready0),
        .Pready1 (Pready1),
        .Pready2 (Pready2),
        .Pready3 (Pready3),
        .Pready4 (Pready4),
        .Pready5 (Pready5),
        .ready   (Ready),
        .Rdata   (Rdata)

    );

    address_dec u_decoder (
        .addr  (Paddr),
        .en    (decode_en),
        .sel   (),
        .PSel_0(Psel_0),
        .PSel_1(Psel_1),
        .PSel_2(Psel_2),
        .PSel_3(Psel_3),
        .PSel_4(Psel_4),
        .PSel_5(Psel_5),
        .PSel_6()
    );

    typedef enum {
        IDLE,
        SETUP,
        ACCESS
    } state_a;

    state_a c_state, n_state;

    logic [31:0] PADDR_next, PWDATA_next;
    logic Pwrite_next;

    assign transfer = Wreq | Rreq;

    always_ff @(posedge Pclk, posedge Prst) begin
        if (Prst) begin
            c_state <= IDLE;
            Paddr   <= 32'h0;
            Pwdata  <= 32'h0;
            Pwrite  <= 1'b0;
        end else begin
            c_state <= n_state;
            Paddr   <= PADDR_next;
            Pwdata  <= PWDATA_next;
            Pwrite  <= Pwrite_next;
        end
    end

    always_comb begin
        decode_en   = 1'b0;
        Penable     = 1'b0;
        // Ready       = 1'b0;
        Pwrite_next = Pwrite;
        PADDR_next  = Paddr;
        PWDATA_next = Pwdata;
        n_state     = c_state;

        case (c_state)
            IDLE: begin
                decode_en   = 0;
                Penable     = 0;
                PADDR_next  = 32'd0;
                PWDATA_next = 32'd0;
                Pwrite_next = 1'b0;
                if (transfer) begin
                    PADDR_next  = addr;
                    PWDATA_next = wdata;
                    if (Wreq) begin
                        Pwrite_next = 1'b1;
                    end else begin
                        Pwrite_next = 1'b0;
                    end
                    n_state = SETUP;
                end
            end
            SETUP: begin
                decode_en = 1;
                Penable   = 0;
                if (Wreq) begin
                    Pwrite_next = 1;
                end else begin
                    Pwrite_next = 0;
                end
                PWDATA_next = wdata;
                n_state = ACCESS;
            end
            ACCESS: begin
                decode_en = 1;
                Penable = 1;
                // Ready = 1;
                if (!Ready) begin
                    n_state = ACCESS;
                end else if (transfer) begin
                    n_state = SETUP;
                end else begin
                    n_state = IDLE;
                end
            end
        endcase
    end

endmodule


module address_dec (
    input        [31:0] addr,
    input               en,
    output logic        PSel_0,
    output logic        PSel_1,
    output logic        PSel_2,
    output logic        PSel_3,
    output logic        PSel_4,
    output logic        PSel_5,
    output logic        PSel_6,
    output logic [ 3:0] sel
);

    always_comb begin
        PSel_0 = 0;  //idle : 0
        PSel_1 = 0;
        PSel_2 = 0;
        PSel_3 = 0;
        PSel_4 = 0;
        PSel_5 = 0;
        PSel_6 = 0;
        if (en) begin
            casez (addr[31:0])
                32'h1???_????: begin
                    PSel_0 = 1;
                    sel = 4'd0;
                end  // RAM
                32'h2000_0???: begin
                    PSel_1 = 1;
                //    PSel_3 = 1;
                    sel = 4'd1;
                end  // GPO
                32'h2000_1???: begin
                    PSel_2 = 1;
                //    PSel_3 = 1;
                    sel = 4'd2;
                end  // GPI
                32'h2000_2???: begin
                    PSel_3 = 1;
                    sel = 4'd3;
                end  // GPIO
                32'h2000_3???: begin
                    PSel_4 = 1;
                    sel = 4'd4;
                end  // FND
                32'h2000_4???: begin
                    PSel_5 = 1;
                    sel = 4'd5;
                end  // UART
            endcase
        end

    end

endmodule


module apb_mux (
    input        [31:0] sel,
    input        [31:0] Prdata_0,
    input        [31:0] Prdata_1,
    input        [31:0] Prdata_2,
    input        [31:0] Prdata_3,
    input        [31:0] Prdata_4,
    input        [31:0] Prdata_5,
    input               Pready0,
    input               Pready1,
    input               Pready2,
    input               Pready3,
    input               Pready4,
    input               Pready5,
    output logic        ready,
    output logic [31:0] Rdata

);

    always_comb begin
        case (sel[31:28])
            4'h1: begin
                Rdata = Prdata_0;
                ready = Pready0;
            end
            4'h2: begin
                case (sel[15:12])
                    4'h0: begin
                        Rdata = Prdata_1;
                        ready = Pready1;
                    end
                    4'h1: begin
                        Rdata = Prdata_2;
                        ready = Pready2;
                    end
                    4'h2: begin
                        Rdata = Prdata_3;
                        ready = Pready3;
                    end
                    4'h3: begin
                        Rdata = Prdata_4;
                        ready = Pready4;
                    end
                    4'h4: begin
                        Rdata = Prdata_5;
                        ready = Pready5;
                    end
                    default: begin
                        Rdata = 32'hxxxx_xxxx;
                        ready = 1'bx;
                    end
                endcase
            end
        endcase
    end


endmodule

/*
module register (
    input         clk,
    input         rst,
    input  [31:0] idata,
    output [31:0] odata
);
    logic [31:0] ldata;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            ldata <= 0;
        end else begin
            ldata <= idata;
        end
    end

    assign odata = ldata;
endmodule

module register_1byte (
    input  clk,
    input  rst,
    input  idata,
    output odata
);
    logic ldata;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            ldata <= 0;
        end else begin
            ldata <= idata;
        end
    end

    assign odata = ldata;
endmodule
*/