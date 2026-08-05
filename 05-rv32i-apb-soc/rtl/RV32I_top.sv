`timescale 1ns / 1ps

module rv32I_top (
    input         clk,
    input         rst,
    input  [ 7:0] GPI,
    output [ 7:0] GPO,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data,
    input        uart_rx,
    output       uart_tx,

    inout  [15:0] GPIO
);

    logic       dwe, w_uart_rx, w_uart_tx;
    logic [2:0] o_funct3;
    logic [15:0] o_GPO, o_GPIO;
    logic [31:0] instr_addr, instr_data, bus_addr, bus_wdata, bus_rdata;
    logic bus_wreq, bus_rreq, bus_ready, Pwrite, Penable;
    logic Psel_0, Psel_1, Psel_2, Psel_3, Psel_4, Psel_5;
    logic Pready0, Pready1, Pready2, Pready3, Pready4, Pready5;
    logic [31:0]
        Prdata_0,
        Prdata_1,
        Prdata_2,
        Prdata_3,
        Prdata_4,
        Prdata_5,
        Pwdata,
        Paddr;

    assign uart_rx = w_uart_rx;
    assign uart_tx = w_uart_tx;

    instruction_mem U_INSTRUCTION_MEM (.*);
    rv32i_cpu U_RV32I (
        .*,
        .o_funct3(o_funct3)
    );
    /*
    data_mem U_DATA_MEM (
        .*,
        .i_funct3(o_funct3)
    );
*/
    apb_master U_APB_master (
        .Pclk    (clk),
        .Prst    (rst),
        .addr    (bus_addr),
        .wdata   (bus_wdata),
        .Wreq    (bus_wreq),
        .Rreq    (bus_rreq),
        .Rdata   (bus_rdata),
        .Ready   (bus_ready),
        .Penable (Penable),
        .Pwrite  (Pwrite),
        .Pwdata  (Pwdata),
        .Paddr   (Paddr),
        .Psel_0  (Psel_0),     // RAN
        .Psel_1  (Psel_1),     // GPO
        .Psel_2  (Psel_2),     // GPI
        .Psel_3  (Psel_3),     // GPIO
        .Psel_4  (Psel_4),     // FND
        .Psel_5  (Psel_5),     // UART
        .Prdata_0(Prdata_0),   // from RAM
        .Prdata_1(Prdata_1),   // from GPO
        .Prdata_2(Prdata_2),   // from GPI
        .Prdata_3(Prdata_3),   // from GPIO
        .Prdata_4(Prdata_4),   // from FND
        .Prdata_5(Prdata_5),   // from UART
        .Pready0 (Pready0),    //from RAM    
        .Pready1 (Pready1),    //from GPO
        .Pready2 (Pready2),    //from GPI
        .Pready3 (Pready3),    //from GPIO
        .Pready4 (Pready4),    //from FND
        .Pready5 (Pready5)     //from UART
    );

    BRAM U_BRAM (
        .Pclk(clk),
        .Prst(rst),
        .Penable(Penable),
        .Pwrite(Pwrite),
        .Psel(Psel_0),
        .Pwdata(Pwdata),
        .Paddr(Paddr),
        .Prdata(Prdata_0),
        .Pready(Pready0)

    );


    GPO U_GPO (
        .Pclk(clk),
        .Prst(rst),
        .Penable(Penable),
        .Pwrite(Pwrite),
        .Psel(Psel_1),
        .Pwdata(Pwdata),
        .Paddr(Paddr),
        .Prdata(Prdata_1),
        .Pready(Pready1),
        .gpo_out(GPO)
    );

    GPI U_GPI (
        .Pclk(clk),
        .Prst(rst),
        .Penable(Penable),
        .Pwrite(Pwrite),
        .Pwdata(Pwdata),
        .Psel(Psel_2),
        .Pready(Pready2),
        .Paddr(Paddr),
        .idata(GPI),
        .Prdata(Prdata_2)
    );


    GPIO U_GPIO (
        .Pclk(clk),
        .Prst(rst),
        .Penable(Penable),
        .Pwrite(Pwrite),
        .Psel(Psel_3),
        .Pwdata(Pwdata),
        .Paddr(Paddr),
        .Prdata(Prdata_3),
        .Pready(Pready3),
        .gpio(GPIO)
    );

    APB_FNDCON U_FND (
        .Pclk(clk),
        .Prst(rst),
        .Penable(Penable),
        .Pwrite(Pwrite),
        .Psel(Psel_4),
        .Pwdata(Pwdata),
        .Paddr(Paddr),
        .Prdata(Prdata_4),
        .Pready(Pready4),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
    );


    APB_UART U_UART (
        .Pclk(clk),
        .Prst(rst),
        .Penable(Penable),
        .Pwrite(Pwrite),
        .Psel(Psel_5),
        .Pwdata(Pwdata),
        .Paddr(Paddr),
        .Prdata(Prdata_5),
        .Pready(Pready5),
        .uart_rx(w_uart_rx),
        .uart_tx(w_uart_tx)
    );
endmodule
