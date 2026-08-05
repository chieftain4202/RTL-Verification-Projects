`timescale 1ns / 1ps
interface watch_interface (
    input clk
);
    logic       rst;
    logic       sw;
    logic       btn_l;
    logic       btn_r;
    logic       btn_u;
    logic       btn_d;
    logic [6:0] msec;
    logic [5:0] sec;
    logic [5:0] min;
    logic [4:0] hour;

endinterface  //watch_if watch_if


class transaction;
    rand bit    rst;
    rand bit    sw;
    rand bit    btn_l;
    rand bit    btn_r;
    rand bit    btn_u;
    rand bit    btn_d;
    logic [6:0] msec;
    logic [5:0] sec;
    logic [5:0] min;
    logic [4:0] hour;
    function void display(string name);
        if (sw) begin
            $display(
                "%t : [%s] Mode = %d, Left = %d,  Right = %d, Down = %d, Up = %d",
                $realtime, name, sw, btn_l, btn_r, btn_d, btn_u);
        end else if (!sw) begin
            $display("%t : [%s] Run/Stop = %d, Clear = %d, Mode = %d",
                     $realtime, name, btn_u, btn_l, sw);
        end
    endfunction
endclass  //transaction


class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event scb2gen_ev;
    function new(mailbox#(transaction) gen2drv_mbox, event scb2gen_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.scb2gen_ev   = scb2gen_ev;
    endfunction  //new()

    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.btn_l = 0;
            tr.rst = 0;
            tr.btn_u = 1;
            
        //    assert (std::randomize(tr.btn_u));
            tr.sw = 0;

            gen2drv_mbox.put(tr);
            tr.display("gen");
            @(scb2gen_ev);
        end
    endtask  //run

endclass  //generator


class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual watch_interface watch_if;
    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual watch_interface watch_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.watch_if     = watch_if;
    endfunction  //new()

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge watch_if.clk);
            #4;
            watch_if.sw = tr.sw;
            watch_if.btn_l = tr.btn_l;
            watch_if.btn_r = tr.btn_r;
            watch_if.btn_u = tr.btn_u;
            watch_if.btn_d = tr.btn_d;
            watch_if.rst   = tr.rst;
            tr.display("drv");
        end

    endtask  //run
endclass  //driver



class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual watch_interface watch_if;
    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual watch_interface watch_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.watch_if     = watch_if;
    endfunction  //new()

    task run();
        forever begin
            tr = new;
            @(posedge watch_if.clk);
            #1;
            tr.sw    = watch_if.sw;
            tr.btn_l = watch_if.btn_l;
            tr.btn_r = watch_if.btn_r;
            tr.btn_u = watch_if.btn_u;
            tr.btn_d = watch_if.btn_d;
            tr.msec  = watch_if.msec;
            tr.sec  = watch_if.sec;
            tr.min  = watch_if.min;
            tr.hour  = watch_if.hour;
            tr.display("mon");
            mon2scb_mbox.put(tr);
        end
    endtask  //run
endclass  //monitor



class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual watch_interface watch_if;
    event scb2gen_ev;
    localparam clk_10ms = 1_000_000;
    int tick_cnt, tick_msec, tick_sec,  tick_min, tick_hour;
    int pass_cnt, fail_cnt,  try_count;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual watch_interface watch_if, event scb2gen_ev);
        this.watch_if     = watch_if;
        this.tick_cnt     = 0;
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_ev   = scb2gen_ev;
    endfunction  //new()

    // task run();
    //     fork
    //         tick();
    //         check();
    //     join_none
    // endtask //run


    task tick();
        forever begin
            @(posedge watch_if.clk);
            if (watch_if.rst) begin
                tick_cnt  = 0;
                tick_msec = 0;
                tick_sec  = 0;
                tick_min  = 0;
                tick_hour = 0;

            end else begin
                if (tick_cnt == (clk_10ms - 1)) begin
                    tick_cnt = 0;
                    if (tick_msec == 99) begin
                        tick_msec = 0;
                        if (tick_sec == 59) begin
                            tick_sec = 0;
                            if (tick_min == 59) begin
                                tick_min = 0;
                                if (tick_hour == 23) tick_hour = 0;
                                else tick_hour++;
                            end else tick_min++;
                        end else tick_sec++;
                    end else tick_msec++;
                end else begin
                    tick_cnt++;
                end
            end
        end
    endtask  //tick



    task run();
        pass_cnt  = 0;
        fail_cnt  = 0;
        try_count = 0;
        fork
            tick();
            forever begin
                mon2scb_mbox.get(tr);
                tr.display("scb");
                try_count++;

                if ((tick_msec == tr.msec) &&
                    (tick_sec  == tr.sec)  &&
                    (tick_min  == tr.min)  &&
                    (tick_hour == tr.hour)) begin
                    pass_cnt++;
                    $display("%t : PASS", $realtime);
                end else begin
                    fail_cnt++;
                    $display(
                        "%t : FAIL exp = %0d : %0d : %0d : %0d got = %0d : %0d : %0d : %0d",
                        $realtime, tick_hour, tick_min, tick_sec, tick_msec,
                        tr.hour, tr.min, tr.sec, tr.msec);
                end
                ->scb2gen_ev;
            end
        join_none

    endtask  //run


endclass  //scoreboard



class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event                  scb2gen_ev;

    function new(virtual watch_interface watch_if);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen = new(gen2drv_mbox, scb2gen_ev);
        drv = new(gen2drv_mbox, watch_if);
        mon = new(mon2scb_mbox, watch_if);
        scb = new(mon2scb_mbox, watch_if, scb2gen_ev);
    endfunction  //new()

    task run();
        fork
            gen.run(20);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #200;
        $display("___________________________");
        $display("** 8bit register verifi  **");
        $display("***************************");
        $display("**     Try Count = %3d    **", scb.try_count);
        $display("**    PASS Count = %3d    **", scb.pass_cnt);
        $display("**    FAIL Count = %3d    **", scb.fail_cnt);
        $display("***************************");
        $stop;
    endtask  //run
endclass  //environment




module tb_watch_sv ();

    logic clk;
    watch_interface watch_if (clk);
    environment env;

    Top_stopwatch dut (
        .clk      (watch_if.clk),
        .reset    (watch_if.rst),
        .btn_r    (watch_if.btn_r),
        .btn_d    (watch_if.btn_d),
        .btn_u    (watch_if.btn_u),
        .btn_l    (watch_if.btn_l),
        .sw       (watch_if.sw),     //sw[0] up/down
        .uart_rx  (),
        .uart_tx  (),
        .fnd_digit(),
        .fnd_data (),
        .msec     (watch_if.msec),
        .sec      (watch_if.sec),
        .min      (watch_if.min),
        .hour     (watch_if.hour)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(watch_if);
        env.run;

    end
endmodule
