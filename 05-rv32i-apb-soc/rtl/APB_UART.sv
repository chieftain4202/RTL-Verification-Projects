`timescale 1ns / 1ps

module APB_UART (
    input        Pclk,
    input        Prst,
    input        Penable,
    input        Pwrite,
    input        Psel,
    input [31:0] Pwdata,
    input [31:0] Paddr,
    input        uart_rx,
    output       uart_tx,

    output logic [31:0] Prdata,
    output logic        Pready
);

    localparam [11:0] UART_ctl_addr = 12'h000;
    localparam [11:0] UART_baud_addr = 12'h004;
    localparam [11:0] UART_status_addr = 12'h008;
    localparam [11:0] UART_txdata_addr = 12'h00c;
    localparam [11:0] UART_rxdata_addr = 12'h010;

    logic we, tx_start, tx_busy, rx_done, w_b_tick;
    logic [1:0] baud_gen;
    logic [7:0]
        tx_data_reg, rx_data_reg, rx_data_wire, ctl_reg, status_reg, baud_reg, rx_data;

    assign we = (Penable && Pwrite && Psel) ? 1 : 0;
    assign Pready = (Penable & Psel) ? 1 : 0;

 /*   assign Prdata = (Paddr[11:0] == UART_ctl_addr) ? {16'h0000,ctl_reg} : 
                    (Paddr[11:0] == UART_baud_addr) ? {16'h0000,baud_reg}:
                    (Paddr[11:0] == UART_status_addr) ? {16'h0000,status_reg} :
                    (Paddr[11:0] == UART_txdata_addr) ? {16'h0000,tx_data_reg} :
                    (Paddr[11:0] == UART_rxdata_addr) ? {16'h0000,rx_data_reg} 
                    :32'hxxxx_xxxx;
*/

    always_ff @(posedge Pclk, posedge Prst) begin
        if (Prst) begin
            tx_data_reg <= 0;
            rx_data_reg <= 0;
            ctl_reg     <= 0;
            status_reg  <= 0;
            baud_reg    <= 0;
        end else begin
            if(rx_data_reg) rx_data_reg <= rx_data_wire;
            if (we) begin
                case (Paddr[11:0])
                    UART_ctl_addr: ctl_reg[0] <= tx_start;
                    UART_baud_addr: baud_reg[1:0] <= baud_gen;
                    UART_status_addr: begin
                        status_reg[0] <= tx_busy;
                        status_reg[7] <= rx_done;
                    end
                    UART_txdata_addr: tx_data_reg <= Pwdata[7:0];
                    UART_rxdata_addr: Prdata[7:0] <= rx_data_reg;
                endcase
            end
        end
    end




    uart_tx U_UART_TX (
        .clk(Pclk),
        .rst(Prst),
        .tx_start(ctl_reg[0]),
        .b_tick(w_b_tick),
        .tx_data(tx_data_reg),
        .uart_tx(uart_tx),
        .tx_busy(tx_busy),
        .tx_done()
    );

    uart_rx U_UART_RX (
        .clk(Pclk),
        .rst(Prst),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(rx_data_wire),
        .rx_done(rx_done)
    );

    baud_tick U_BAUD_TICK (
        .clk(Pclk),
        .rst(Prst),
        .o_b_tick(w_b_tick)
    );



endmodule
