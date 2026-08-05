`timescale 1ns / 1ps



module fnd_controller (
    input clk,
    input reset,
    input [13:0] fnd_in_data,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);


    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_mux_4x1_out; //bit 맞추어야 함
    wire [1:0] w_digit_sel;


    // ssign fnd_digit = 4'b1110;  // to fnd an[3:0]


    digit_splitter U_DIGIT_SPL (
        .in_data(fnd_in_data),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );


   clk_div U_CLK_DIV (
        .clk(clk),
        .reset(reset),
        .o_1khz(w_1khz)
    );


    counter_4 U_COUNTER_4 (
        .clk(w_1khz),
        .reset(reset),
        .digit_sel(w_digit_sel)
    );


    Decoder2x4 U_Decoder_2x4 (
        .digit_sel  (w_digit_sel),
        .fnd_digit_D(fnd_digit)
    );


    mux_4x1 U_Mux_4x1 (
        .sel(w_digit_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),
        .mux_out(w_mux_4x1_out)
    );

    bcd U_BCD (
        .bcd(w_mux_4x1_out),  //sum 8bit 중에서 4bit만 사용하겠음
        .fnd_data(fnd_data) //reg가 아니라, instance 이후 왜 wire인 것일까 bcd에서 선택되었고, controller에서는 값을 연결만 하는 것  
    );


endmodule


module clk_div (
    input  clk,
    input  reset,
    output reg o_1khz
);

    // reg [16:0] counter_r; //module 다르니 다른 변수
    reg [ $clog2(100_000):0] counter_r; //로그로 하면 알아서 bit로 바꿔줌


    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0; // 초기화 안 하면 그냥 X로 출력함 - 일을 안함
            o_1khz <= 1'b0;
        end else begin
            if (counter_r == 99999) begin
                counter_r <= 0;
                o_1khz <= 1'b1;
            end else begin
                counter_r <= counter_r + 1; //9999까지만 가야하므로 조건 필요함
                o_1khz <= 1'b0;            
            end
        end
       
    end


endmodule


module counter_4 (
    input        clk,
    input        reset,
    output [1:0] digit_sel
);
    // 순차논리는 항상 always 구문 사용


    reg [1:0] counter_r;


    assign digit_sel = counter_r; // reg 다음에 assign 나오기 이래야지 오류 안남


    always @(posedge clk, posedge reset) begin
        //초기화 먼저
        if (reset == 1) begin // 괄호 안에 그냥 reset만 적으면 자동적으로 1이면 실행하고 그렇긴 함
            // init counter_r을 0으로 초기화
            counter_r <= 0; //순차논리에서는 부등호 사용하고 = 사용 , 이 방향으로 내보내는데 nonblocking
        end else begin
            //to do
            counter_r <= counter_r + 1;  //2bit이므로, 0~3으로만 나옴
        end
    end
endmodule


//to select to fnd digit display
module Decoder2x4 (
    input [1:0] digit_sel,
    output reg [3:0] fnd_digit_D


);


    always @(digit_sel) begin
        case (digit_sel)
            2'b00: fnd_digit_D = 4'b1110;
            2'b01: fnd_digit_D = 4'b1101;
            2'b10: fnd_digit_D = 4'b1011;
            2'b11: fnd_digit_D = 4'b0111;
        endcase
    end




endmodule


module mux_4x1 (
    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,
    output reg [3:0] mux_out


);


    // reg o_mux_out;
    // assign mux_out = o_mux_out;


    always @(*) begin //*을 사용 = 모든 입력을 감시하겠다는 의미


        case (sel)  //선택만 하면 되는 것이므로
            2'b00: mux_out = digit_1;
            2'b01: mux_out = digit_10;
            2'b10: mux_out = digit_100;
            2'b11: mux_out = digit_1000;


        endcase




    end


endmodule


module digit_splitter (
    input  [13:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);


    //들어오는 값 바로 연산 - assign 문 사용


    assign digit_1 = in_data % 10;
    assign digit_10 = (in_data / 10) % 10;
    assign digit_100 = (in_data / 100) % 10;
    assign digit_1000 = (in_data/1000) % 10; //10bit 이상 되어야지 나타남 지금은 gnd 연결 sum 이 8bit 이기 때문


    //연산기 , 연산은 assign하고 always 문 둘 다 사용 가능
endmodule




module bcd (
    input [3:0] bcd,
    output reg [7:0] fnd_data // bcd에서 나와서 fnd로 들어가서 4bit라고 생각했는데, 아님, 8bit
    // reg 안 쓰면, 기본인 wire로 연결
);


    always @(bcd) begin
        case (bcd)
            4'd0: fnd_data = 8'hc0;  //fnd_data가 output data
            4'd1:
            fnd_data = 8'hf9; //bcd data 1이 들어오면 fnd_data f9가 출력됨 8'hf9를 유지한다는 의미
            4'd2: fnd_data = 8'ha4;
            4'd3: fnd_data = 8'hb0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hf8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            default:
            fnd_data = 8'hFF; //위의 경우 외의 경우에는 FF 출력 유지
        endcase
    end
endmodule


module I2C_Master_top (
    input  logic       clk,
    input  logic       rst,
    // command port 
    input  logic       cmd_start,
    input  logic       cmd_write,
    input  logic       cmd_read,
    input  logic       cmd_stop,
    input  logic [7:0] tx_data,
    input  logic       ack_in,     //master가 받는 것
    // internal output
    output logic [7:0] rx_data,
    output logic       done,
    output logic       ack_out,    //master가 주는 것 
    output logic       busy,
    //external i2c port
    output logic       scl,
    inout  logic       sda
);

    logic sda_o, sda_i;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_master U_I2C_TOP (
        .*,
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
    input  logic [7:0] tx_data,
    input  logic       ack_in,     //master가 받는 것
    // internal output
    output logic [7:0] rx_data,
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
    //IDLE이 아니면 busy 
    assign busy  = (state != IDLE);

    //통신 속도 
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
            ack_in_r     <= 1'b1;  //nack 상태 
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
                        //stop에서 idle로 넘어갈 때, 0으로 줘야하는가?
                        //위에서 assign으로 주는 것으로 변경 
                        //stop일 때 0으로 주는 것도 괜찮을거 같다고?
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
                        endcase
                    end
                end
                WAIT_CMD: begin
                    step <= 0;
                    if (cmd_write) begin
                        //write이면, tx_data를 shift reg에 저장
                        tx_shift_reg <= tx_data;
                        bit_cnt <= 0;
                        is_read <= 1'b0;
                        state <= DATA;
                    end else if (cmd_read) begin
                        rx_shift_reg <= 0;
                        bit_cnt <= 0;
                        is_read <= 1'b1;
                        ack_in_r <= ack_in; //ack 넣어주고 이후에 전송 
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
                                //sda_o = sda_r 
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
                                //master는 1번 구간에서 보냄
                                if (is_read) begin
                                    //latching
                                    //들어온 것을 reg에 넣어두기
                                    //들어오고 다음 명령어로 넘어갈 수 있기 때문 
                                    sda_r <= ack_in_r;
                                end else begin
                                    //ack 읽어야 함
                                    //1이면 왜 input인지는 회로 보면 알게 됨 
                                    //high impedence로 만들어줘야 ack 읽을 수 있음 
                                    sda_r <= 1'b1;  // sda input 설정 , sda high impedence 설정 
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
                                    //data 들어온 갑으로 나감 
                                    //host에게 알려주는 것 
                                    ack_out <= sda_i;
                                end
                                if (is_read) begin
                                    //read 입장에서 ack는 한 byte 받았다는 의미
                                    //한 바이트를 host 쪽으로 주기 
                                    rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;

                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                //신호를 받고 host가 다음을 어떻게 할지 알아서 결정 
                                done  <= 1'b1;
                                step  <= 2'd0;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                STOP: begin
                    if (qtr_tick) begin
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


module master_top (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] sw,
    output logic        scl,
    inout  wire         sda,
    output logic [3:0]  fnd_digit,
    output logic [7:0]  fnd_data
);

    typedef enum logic [3:0] {
        IDLE,
        START_CMD,
        START_WAIT,
        ADDR_CMD,
        ADDR_WAIT,
        WRITE_CMD,
        WRITE_WAIT,
        STOP_CMD,
        STOP_WAIT
    } i2c_state_e;

    localparam logic [7:0] SLA_W = {7'h55, 1'b0};
    localparam int START_DEBOUNCE_MAX = 2_000_000;

    i2c_state_e state;

    logic [7:0] sw_tx_data;
    logic [15:0] sw_meta;
    logic [15:0] sw_sync;
    logic       cmd_start;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic [7:0] m_tx_data;
    logic       ack_in;
    logic [7:0] m_rx_data;
    logic       done;
    logic       ack_out;
    logic       busy;

    logic [13:0] fnd_in_data;

    assign ack_in      = 1'b1;
    assign fnd_in_data = {6'd0, sw_tx_data};

    I2C_Master_top U_I2C_MASTER_TOP (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (m_tx_data),
        .ack_in   (ack_in),
        .rx_data  (m_rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (scl),
        .sda      (sda)
    );

    fnd_controller U_FND_CONTROLLER (
        .clk        (clk),
        .reset      (rst),
        .fnd_in_data(fnd_in_data),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            sw_tx_data    <= 8'h00;
            sw_meta       <= 16'h0000;
            sw_sync       <= 16'h0000;
            cmd_start     <= 1'b0;
            cmd_write     <= 1'b0;
            cmd_read      <= 1'b0;
            cmd_stop      <= 1'b0;
            m_tx_data     <= 8'h00;
        end else begin
            sw_meta <= sw;
            sw_sync <= sw_meta;

            cmd_start <= 1'b0;
            cmd_write <= 1'b0;
            cmd_read  <= 1'b0;
            cmd_stop  <= 1'b0;

            case (state)
                IDLE: begin
                    sw_tx_data <= sw_sync[7:0];
                    state      <= START_CMD;
                end

                START_CMD: begin
                    cmd_start <= 1'b1;
                    state     <= START_WAIT;
                end

                START_WAIT: begin
                    if (done) begin
                        state <= ADDR_CMD;
                    end
                end

                ADDR_CMD: begin
                    cmd_write <= 1'b1;
                    m_tx_data <= SLA_W;
                    state     <= ADDR_WAIT;
                end

                ADDR_WAIT: begin
                    if (done) begin
                        state <= WRITE_CMD;
                    end
                end

                WRITE_CMD: begin
                    cmd_write <= 1'b1;
                    m_tx_data <= sw_tx_data;
                    state     <= WRITE_WAIT;
                end

                WRITE_WAIT: begin
                    if (done) begin
                        state <= STOP_CMD;
                    end
                end

                STOP_CMD: begin
                    cmd_stop <= 1'b1;
                    state    <= STOP_WAIT;
                end

                STOP_WAIT: begin
                    if (done) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
