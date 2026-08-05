`timescale 1ns / 1ps

module i2c_slave (
    input  logic       clk,
    input  logic       rst,
    // command port 
    input  logic [7:0] tx_data,
    //input  logic       ack_in,   // slave 가 받는 것
    // internal output
    output logic [7:0] rx_data,
    //output logic       done,
   // output logic       ack_out,  // slave 가 주는 것 
    //output logic       busy,
    //external i2c port
    input  logic       scl,
    inout  logic       sda
);

    // 3state buffer
    logic sda_o, sda_i, sda_r, scl_r;
    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;


    logic edge_scl, edge_sda, cfw, cfr;
    logic scl_rise, scl_fall, sda_rise, sda_fall;
    logic [3:0] bit_cnt;
    logic ack_in_r, start;
    logic [1:0] step;

    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic [6:0] fnd_slave_addr;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_scl <= 0;
        end else begin
            edge_scl <= scl;
        end
    end

    assign scl_rise = ~edge_scl & scl;
    assign scl_fall = ~scl & edge_scl;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            edge_sda <= 0;
        end else begin
            edge_sda <= sda;
        end
    end

    assign sda_rise = ~edge_sda & scl;
    assign sda_fall = ~scl & edge_sda;
    // assign scl = scl_r;
    assign sda_o = sda_r;

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        ADDR,
        DATA_ACK,
        W_DATA,
        R_DATA,
        STOP
    } i2c_state_e;

    i2c_state_e state;
    assign rx_data = rx_shift_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            bit_cnt <= 0;
            fnd_slave_addr <= 7'b0111000;
            
        end else begin

        end
    end

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            // scl_r        <= 1'b1;
            sda_r        <= 1'b1;
            cfw          <= 0;
            cfr          <= 0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            step         <= 0;
            ack_in_r     <= 1'b1;
        end else begin
            case (state)
                IDLE: begin
                    /*case (step)
                        2'b00: begin
                            if (sda_i == 0) begin
                                step <= 2'b01;
                            end
                        end
                        2'b01: */
                            if (scl_fall) begin
                                state <= ADDR;
                                step  <= 0;
                                bit_cnt <= 0;
                            tx_shift_reg <= tx_data[7:0];
                        end
                 //   endcase
                end

                ADDR: begin
                    if (scl_rise) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                    end
                    if (scl_fall) begin
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            bit_cnt <= 0;
                            if (rx_shift_reg[7:1] == fnd_slave_addr) begin
                                sda_r <= 1'b0;
                                state <= DATA_ACK;
                            end else begin
                                sda_r <= 1'b1;
                                state <= IDLE;
                            end
                        end
                    end
                end

                // bit_cnt == 7 rise
                DATA_ACK: begin
             /*       if (scl_rise) begin
                        sda_r <= 1'b1;
                        if (sda_i == 1'b1) begin
                            state <= W_DATA;
                         
                        end else begin
                            state <= STOP;
                        end
                    end*/

                    if (scl_fall) begin
                        sda_r <= 1'b1;
                        if (rx_shift_reg[0] == 1) begin
                            state <= W_DATA;
                        end else begin
                            state <= R_DATA;
                        end
                    end

                end

                W_DATA: begin
                    
                    if (scl_rise) begin
                        sda_r <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            bit_cnt <= 0;
                            state   <= DATA_ACK;
                        end
                    end
                end

                R_DATA: begin
                    cfr <= 1;
                    if (scl_rise) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                    
                    end
                    if (scl_fall) begin
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7) begin
                            sda_r <= 1'b0;
                            state <= DATA_ACK;
                            bit_cnt <= 0;
                            
                        end

                    end
                end

                STOP: begin
                    step <= 2'b00;
                    case (step)
                        2'b00: begin
                            if (scl_rise) begin
                                step <= 2'b01;
                            end
                        end
                        2'b01: begin
                            if (sda_rise) begin
                                state <= IDLE;
                                step  <= 0;
                            end
                        end
                    endcase
                end

                default: state = IDLE;
            endcase
        end

    end

endmodule
