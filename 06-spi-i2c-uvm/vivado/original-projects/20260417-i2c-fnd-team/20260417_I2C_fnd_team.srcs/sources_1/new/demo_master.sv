`timescale 1ns / 1ps

module I2c_demo_top (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] sw,
    input  logic       btn_start,
    input  logic       btn_stop,
    input  logic       btn_addr,
    input  logic       btn_write,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data,
    output logic       mscl,
    inout logic       msda



);

    logic start, stop, write, read, addr;

    logic [7:0] counter;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] M_tx_data;
    logic [7:0] S_tx_data;
    logic       ack_in;
    logic [7:0] M_rx_data;
    logic [7:0] S_rx_data;
    logic       done;
    logic       master_ack_out;
    logic       busy;
    logic       scl;
    logic [7:0] sw_hex_data;
    wire        sda;




    assign ack_in = 1'b1;

    sw_data u_sw_data (
        .sw      (sw),
        .hex_data(sw_hex_data)
    );

    btn_debounce u_btn_debounce_start (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_start),
        .o_btn(start)
    );

    btn_debounce u_btn_debounce_stop (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_stop),
        .o_btn(stop)
    );

    btn_debounce u_btn_debounce_write (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_write),
        .o_btn(write)
    );

    btn_debounce u_btn_debounce_addr (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_addr),
        .o_btn(addr)
    );






    I2C_Master U_I2C_Master (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(start),
        .cmd_write(write),
        .cmd_read (read),
        .cmd_stop (stop),
        .M_tx_data(M_tx_data),
        .ack_in   (ack_in),
        .M_rx_data(M_rx_data),
        .done     (done),
        .ack_out  (master_ack_out),
        .busy     (busy),
        .scl      (mscl),
        .sda      (msda)
    );

    typedef enum logic [2:0] {
        IDLE  = 0,
        START,
        ADDR,
        WRITE,
        STOP

    } i2c_state_e;

    localparam SLA_W = {7'h12, 1'b0};
    i2c_state_e state;


    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            counter   <= 0;
            state     <= IDLE;
            cmd_start <= 0;
            cmd_write <= 0;
            cmd_read  <= 0;
            cmd_stop  <= 0;
            M_tx_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    cmd_start <= 0;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    if (start) begin
                        state <= START;
                    end
                end

                START: begin
                    cmd_start <= 1;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    if (done) begin
                        state <= ADDR;
                    end
                end

                ADDR: begin
                    cmd_start <= 0;
                    cmd_write <= 1;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    M_tx_data <= 8'b01110000;
                    if (done) begin
                        state <= WRITE;
                    end
                end

                WRITE: begin
                    cmd_start <= 0;
                    cmd_write <= 1;
                    cmd_read  <= 0;
                    cmd_stop  <= 0;
                    M_tx_data <= sw_hex_data;
                    if (write) begin
                        state <= STOP;
                    end
                end

                STOP: begin
                    cmd_start <= 0;
                    cmd_write <= 0;
                    cmd_read  <= 0;
                    cmd_stop  <= 1;
                    if (done) begin
                        state   <= IDLE;
                        counter <= counter + 1;
                    end
                end

            endcase
        end
    end
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
`timescale 1ns / 1ps

module I2C_Master (
    input  logic       clk,
    input  logic       rst,
    // command port 
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] M_tx_data,
    input  logic       ack_in,     //master가 받는 것
    // internal output
    output logic [7:0] M_rx_data,
    output logic       done,
    output logic       ack_out,    //master가 주는 것 
    output logic       busy,
    // external i2c port
    output logic       scl,
    inout  logic       sda
);
    logic sda_o, sda_i;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;


    i2c_master u_i2c_master (
        .*,
        .ack_in(ack_in),
        .ack_out(ack_out),
        .sda_o(sda_o),
        .sda_i(sda_i)
    );
endmodule

module i2c_master (
    input  logic       clk,
    input  logic       rst,
    // command port 
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] M_tx_data,
    input  logic       ack_in,     //master가 받는 것
    // internal output
    output logic [7:0] M_rx_data,
    output logic       done,
    output logic       ack_out,    //master가 주는 것 
    output logic       busy,
    //external i2c port
    output logic       scl,
    output logic       sda_o,
    input  logic       sda_i
);

    //100KHz : standard mode 
    //bit 신호를 보낼 때마다, 구간을 4개로 쪼개서 할 것임
    //실제 tick이 발생하는 속도는 400KHz로 해야 함

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        START,
        WAIT_CMD,
        DATA,
        DATA_ACK,
        STOP
    } i2c_state_e;

    i2c_state_e       state;

    logic       [7:0] div_cnt;
    logic             qtr_tick;
    logic scl_r, sda_r;
    logic [1:0] step;
    logic [7:0] tx_shift_reg, rx_shift_reg;
    logic [2:0] bit_cnt;
    logic is_read, ack_in_r;

    assign scl   = scl_r;
    assign sda_o = sda_r;
    assign busy  = (state != IDLE);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            //들어오는 clk = 100MHz
            //400MHz = {100MHz/(100KHz * 4)} - 1
            //{100_000_000 / (100_000 * 4)} - 1 = 250 - 1 = 249 
            div_cnt  <= 0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == (250 - 1)) begin  // scl : 100kHz 
                div_cnt  <= 0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 1;
                qtr_tick <= 1'b0;
            end
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            scl_r        <= 1'b1;
            sda_r        <= 1'b1;
            //busy         <= 1'b0;
            step         <= 0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            is_read      <= 1'b0;
            bit_cnt      <= 0;
            ack_in_r     <= 1'b1;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    scl_r <= 1'b1;
                    sda_r <= 1'b1;
                    //busy  <= 1'b0;
                    if (cmd_start) begin
                        state <= START;
                        step  <= 0;  //한 주기를 4로 나눈 step 
                        //busy  <= 1'b1;
                    end
                end
                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                //현 상태 유지 
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                step  <= 2'd0;
                                //start 구간 끝났다는 의미 
                                done  <= 1'b1;
                                state <= WAIT_CMD;
                            end
                            default: begin

                            end
                        endcase
                    end
                end
                WAIT_CMD: begin
                    step <= 0;
                    if (cmd_write) begin
                        //write이면, tx_data를 shift reg에 저장
                        tx_shift_reg <= M_tx_data;
                        bit_cnt <= 0;
                        is_read <= 1'b0;
                        state <= DATA;
                    end else if (cmd_read) begin
                        rx_shift_reg <= 0;
                        bit_cnt <= 0;
                        is_read <= 1'b1;
                        state <= DATA;
                    end else if (cmd_stop) begin
                        state <= STOP;
                    end else if (cmd_start) begin
                        state <= START;
                    end
                end
                DATA: begin
                    if (qtr_tick) begin
                        //이 동작을 8번 반복해야 됨 
                        case (step)
                            2'd0: begin
                                //전송 
                                scl_r <= 1'b0;
                                //sda_r에 넣어야지 전송 
                                //입력값이 들어올 때 나가면 안됨
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];
                                step  <= 2'd1;
                            end

                            2'd1: begin
                                // scl 상승 구간 
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end

                            2'd2: begin
                                //수신 
                                scl_r <= 1'b1;
                                //read일 때 읽겠다.
                                if (is_read) begin
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                                end
                                step <= 2'd3;
                            end

                            2'd3: begin
                                //shift
                                scl_r <= 1'b0;
                                //read 아닐 때, write 상태일 때 shift 
                                //다음 비트 준비 
                                if (!is_read) begin
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                                step <= 2'd0;

                                if (bit_cnt == 7) begin
                                    //여기서 다시 0으로 초기화 안 해줘도 되나?
                                    state <= DATA_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 1;
                                end
                            end
                        endcase
                    end
                end
                DATA_ACK: begin
                    //master 입장에서
                    //ack 주고, 받고
                    //nack를 줌 
                    //read, write를 먼저 판단 
                    //ack_in -> 0: ack / 1: nack 
                    //이 신호를 host 쪽에서 주는 것 
                    //cpu가 넣어주는 것 (코딩해서)
                    //받은 값은 ack_out을 통해서 host로 주는 것 
                    //**ack를 host 쪽에서 판단 
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                if (is_read) begin
                                    sda_r <= ack_in_r;
                                end else begin
                                    sda_r <= 1'b1;
                                end
                                step <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;

                            end
                            2'd2: begin
                                //ack는 3번째에서 받는게 좋음
                                scl_r <= 1'b1;
                                if (!is_read) begin  // ack 수신
                                    ack_out <= sda_i;

                                end
                                if (is_read) begin
                                    M_rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;

                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                done  <= 1'b1;
                                step  <= 2'd0;
                                state <= WAIT_CMD;

                            end
                        endcase
                    end
                end
                STOP: begin
                    if (qtr_tick) begin
                        //step <= step + 1;
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                sda_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
                            end
                        endcase
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
