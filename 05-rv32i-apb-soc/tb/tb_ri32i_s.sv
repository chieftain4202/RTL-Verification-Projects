`timescale 1ns / 1ps


module tb_rv32i ();
    logic Pclk, Prst;
    logic [31:0] addr, wdata, Rdata;
    logic [7:0] GPI;
    wire [7:0] GPO;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;
    logic uart_rx;
    tri [15:0] GPIO;
    logic [7:0] sw_value;
    logic Wreq, Rreq, Ready;

    logic slverr;
    logic Penable;
    logic Pwrite;
    logic suerr;
    logic Pready;
    logic Pselx;
    logic Pwdata;
    logic Paddr;
    logic Psel_0;  // RAN
    logic Psel_1;  // GPO
    logic Psel_2;  // GPI
    logic Psel_3;  // GPIO
    logic Psel_4;  // FND
    logic Psel_5;  // UART
    logic Prdata_0;  // from RAM
    logic Prdata_1;  // from GPO
    logic Prdata_2;  // from GPI
    logic Prdata_3;  // from GPIO
    logic Prdata_4;  // from FND
    logic Prdata_5;  // from UART
    logic Pready0;  //from RAM    
    logic Pready1;  //from GPO
    logic Pready2;  //from GPI
    logic Pready3;  //from GPIO
    logic Pready4;  //from FND
    logic Pready5;

    rv32I_top dut (
        .clk     (Pclk),
        .rst     (Prst),
        .GPI     (GPI),
        .GPO     (GPO),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data),
        .uart_rx (uart_rx),
        .uart_tx (),
        .GPIO    (GPIO)
    );


    //    apb_master dut (
    //        .*
    //    );



    always #5 Pclk = ~Pclk;

    assign GPIO[7:0]  = sw_value;
    assign GPIO[15:8] = 8'hzz;

    initial begin
        Rreq = 0;
        Wreq = 0;
        Pclk = 0;
        Prst = 1;
        GPI  = 8'h00;
        uart_rx = 1'b1;
        sw_value = 8'h00;
        //GPI  = 8'h0000;
        //GPIO = 16'h0000;

        @(negedge Pclk);
        @(negedge Pclk);
        Prst = 0;

        repeat (50)  @(negedge Pclk);
        sw_value = 8'h01;

        repeat (50)  @(negedge Pclk);
        sw_value = 8'h02;

        repeat (50)  @(negedge Pclk);
        sw_value = 8'h05;


        repeat (500) @(negedge Pclk);
        /*
        @(negedge Pclk);
        Prst = 1;
        @(posedge Pclk);
        addr  = 32'h1000_0000;
        wdata = 32'h0000_0041;
        Wreq = 1;
        @(Psel_0 && Penable);
        Pready0 = 1'b1;
        @(negedge Pclk);
        Pready0 = 1'b0;
        Wreq = 1'b0;


        //Uart
        @(posedge Pclk);
        @(posedge Pclk);
        #1;
        Rreq = 1'b1;
        addr = 32'h2000_4000;
        @(Psel_5 && Penable);
        @(posedge Pclk);
        @(posedge Pclk);
        #1;
            Pready5 = 1'b1;
            Prdata_5 = 32'h0000_00041;
        @(posedge Pclk);
        #1;
        Pready5 = 1'b0;
        Rreq = 1'b0;
*/
        $stop;
    end
endmodule
