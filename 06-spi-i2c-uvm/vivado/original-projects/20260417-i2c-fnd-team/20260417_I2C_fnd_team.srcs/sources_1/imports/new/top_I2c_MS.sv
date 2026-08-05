`timescale 1ns / 1ps


module top_I2c_MS (
    input  logic       clk,
    input  logic       rst,
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] M_tx_data,
    input  logic [7:0] S_tx_data,
    output logic [7:0] S_rx_data,
    output logic [7:0] M_rx_data,
    output logic       mscl,
    input  logic       sscl,
    inout  wire        msda,
    inout  wire        ssda,
    output logic       done
);


    logic [7:0] counter;
    //logic [7:0] S_tx_data;
    logic       ack_in;  //master가 받는 것
    logic       ack_out;  //master가 주는 것 
    logic       busy;
    logic       scl;
    wire        sda;

    //    pullup(sda);

    i2c_slave U_I2c_Slave (
        .*,
        .scl(sscl),
        .sda(msda),
        .tx_data(S_tx_data),
        .rx_data(S_rx_data)

    );


    I2C_Master U_I2C_Master (
        .clk(clk),
        .rst(rst),
        .*,
        .scl(mscl),
        .sda(msda)
    );

endmodule



module btn_debounce (
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
);


    // clock divider for debounce shift register
    // 100MHZ -> 100khz
    // counter -> 100M/100K = 1000
    parameter CLK_DIV = 1000_000;
    parameter F_COUNT = 100_000_000 / CLK_DIV;
    reg [$clog2(F_COUNT)-1:0] counter_reg;
    reg clk_100khz_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            clk_100khz_reg <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                clk_100khz_reg <= 1'b1;
            end else begin
                clk_100khz_reg <= 1'b0;
            end
        end
    end

    //series 8 tap F/F
    //1 reg [7:0] debounce_reg;
    reg [7:0] q_reg, q_next;
    wire debounce;

    //SL
    always @(posedge clk_100khz_reg, posedge reset) begin
        if (reset) begin
            //1 debounce_reg <= 0;
            q_reg <= 0;
        end else begin
            //shift register
            //1  debounce_reg <= {i_btn, debounce_reg[7:1]}
            q_reg <= q_next;
        end
    end

    //next CL
    always @(*) begin
        q_next = {i_btn, q_reg[7:1]};
    end

    //debounce, 8input AND
    assign debounce = &q_reg;

    reg edge_reg;
    //edge detection
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 1'b0;
        end else begin
            edge_reg <= debounce;
        end
    end
    assign o_btn = debounce & {~edge_reg};

endmodule




module sw_data (
    input  logic [7:0] sw,
    output logic [7:0] hex_data
);

    always_comb begin
        if (sw) begin
            hex_data = {sw};
        end else begin
            hex_data = 8'h00;
        end
    end

endmodule
