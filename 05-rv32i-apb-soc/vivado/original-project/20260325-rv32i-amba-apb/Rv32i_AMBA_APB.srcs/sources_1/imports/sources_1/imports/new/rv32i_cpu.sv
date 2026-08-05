`timescale 1ns / 1ps
`include "define.vh"

module rv32i_cpu (
    input         clk,
    input         rst,
    input         bus_ready,
    input  [31:0] instr_data,
    input  [31:0] bus_rdata,
    output        bus_wreq,
    output        bus_rreq,
    output [31:0] instr_addr,
    output [31:0] bus_addr,
    output [31:0] bus_wdata,
    output [ 2:0] o_funct3
);

    logic pc_en, rf_we, alu_src, branch, jal, jalr;
    logic [ 2:0] rfwd_src;
    logic [ 3:0] alu_control;
    logic [31:0] alu_result;

    control_unit U_CONTROL_UNIT (
        .clk        (clk),
        .rst        (rst),
        .funct7     (instr_data[31:25]),
        .funct3     (instr_data[14:12]),
        .opcode     (instr_data[6:0]),
        .ready      (bus_ready),
        .pc_en      (pc_en),            
        .rf_we      (rf_we),
        .alu_src    (alu_src),
        .dwe        (bus_wreq),
        .dre        (bus_rreq),
        .jal        (jal),
        .jalr       (jalr),
        .rfwd_src   (rfwd_src),
        .o_funct3   (o_funct3),
        .branch     (branch),
        .alu_control(alu_control)
    );

    rv32I_datapath u_datapath (
        .clk        (clk),
        .rst        (rst),
        .dwe        (bus_wreq),
        .rf_we      (rf_we),
        .pc_en      (pc_en),
        .alu_src    (alu_src),
        .alu_control(alu_control),
        .instr_data (instr_data),
        .bus_rdata  (bus_rdata),
        .jal        (jal),
        .jalr       (jalr),
        .rfwd_src   (rfwd_src),
        .instr_addr (instr_addr),
        .bus_addr   (bus_addr),
        .branch     (branch),
        .bus_wdata  (bus_wdata)

    );
endmodule


module control_unit (
    input              clk,
    input              rst,
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    input              ready,
    output logic       pc_en,
    output logic       rf_we,
    output logic       alu_src,
    output logic       jal,
    output logic       jalr,
    output logic       branch,
    output logic       dwe,
    output logic       dre,
    output logic [2:0] o_funct3,
    output logic [2:0] rfwd_src,
    output logic [3:0] alu_control
);

    typedef enum {
        FETCH,
        DECODE,
        EXECUTE,
        EXE_R,
        EXE_I,
        EXE_S,
        EXE_B,
        EXE_L,
        EXE_J,
        EXE_JL,
        EXE_U,
        EXE_UA,
        MEM,
        MEM_S,
        MEM_L,
        WB
    } state_e;

    state_e c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= FETCH;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        n_state = c_state;
        case (c_state)
            FETCH: begin
                n_state = DECODE;
            end
            DECODE: begin
                n_state = EXECUTE;
            end
            EXECUTE: begin
                case (opcode)
                    `UL_TYPE,`U_TYPE,`JL_TYPE,`J_TYPE,`R_TYPE,`B_TYPE,`I_TYPE: begin
                        n_state = FETCH;
                    end
                    `S_TYPE: begin
                        n_state = MEM;
                    end
                    `IL_TYPE: begin
                        n_state = MEM;
                    end
                endcase
            end
            MEM: begin
                case (opcode)
                    `S_TYPE: begin
                        if (ready) begin
                        n_state = FETCH;
                        end
                    end
                    `IL_TYPE: n_state = WB;
                endcase
            end
            WB: begin
                if (ready) begin
                    n_state = FETCH;
                end
            end
        endcase
    end

    always_comb begin
        pc_en       = 1'b0;
        branch      = 1'b0;
        jal         = 1'b0;
        jalr        = 1'b0;
        rf_we       = 1'b0;
        alu_src     = 1'b0;
        dwe         = 1'b0;  //for S type, IL type
        dre         = 1'b0;  //for IL type
        o_funct3    = 3'b000;  //for S type, IL type
        alu_control = 4'b0000;
        rfwd_src    = 3'b000;

        case (c_state)
            FETCH: begin
                pc_en = 1'b1;
            end
            DECODE: begin

            end
            EXECUTE: begin
                case (opcode)
                    `R_TYPE: begin
                        rf_we       = 1'b1;
                        alu_src     = 1'b0;
                        alu_control = {funct7[5], funct3};
                    end
                    `I_TYPE: begin
                        rf_we   = 1'b1;
                        alu_src = 1'b1;
                        if (funct3 == 3'b101) alu_control = {funct7[5], funct3};
                        else alu_control = {1'b0, funct3};
                    end
                    `B_TYPE: begin
                        alu_src     = 1'b0;
                        alu_control = {1'b0, funct3};
                        branch      = 1'b1;
                    end
                    `S_TYPE: begin
                        alu_src     = 1'b1;
                        alu_control = 4'b0000;
                    end
                    `IL_TYPE: begin
                        alu_src     = 1'b1;
                        alu_control = 4'b0000;
                    end
                    `U_TYPE: begin
                        rf_we    = 1'b1;
                        rfwd_src = 3'b011;
                    end
                    `UL_TYPE: begin
                        rf_we    = 1'b1;
                        rfwd_src = 3'b010;
                    end
                    `J_TYPE: begin
                        rf_we    = 1'b1;
                        jal      = 1;
                        jalr     = 0;
                        rfwd_src = 3'b100;
                    end
                    `JL_TYPE: begin
                        rf_we    = 1'b1;
                        jal      = 1;
                        jalr     = 1;
                        rfwd_src = 3'b100;
                    end
                endcase
            end
            MEM: begin
                // S type, IL type
                o_funct3 = funct3;
                if (opcode == `S_TYPE) dwe = 1'b1;
                else dre = 1'b1;
            end
            WB: begin
                rf_we = 1'b1;
                // IL type
                if (opcode == `IL_TYPE) rfwd_src = 3'b001;
            end

        endcase
    end


    /*
    always_comb begin
        dwe         = 1'b0;
        branch      = 0;
        jal         = 0;
        jalr        = 0;
        rf_we       = 1'b0;
        alu_src     = 1'b0;
        o_funct3    = 3'b000;
        alu_control = 4'b0000;
        rfwd_src    = 3'b000;
        case (opcode)
            // R-type, to write register file, alu_contrl == {funct7[5], funct3}
            `R_TYPE: begin
                rf_we       = 1'b1;  // write register
                alu_src     = 1'b0;  // 0 = rs2, 1 = imm 
                alu_control = {funct7[5], funct3};  // funct7, funct3 [3:0]
                rfwd_src    = 3'b000;  // o_alu value sel mux
                o_funct3    = 3'b000;  // data_mem control (M)
                dwe         = 1'b0;  // data mem control write
                branch      = 0;  // for control B Type
                jal         = 0;  // for jal
                jalr        = 0;  // for jalr
            end
            `S_TYPE: begin
                rf_we       = 1'b0;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b001;
                o_funct3    = funct3;
                dwe         = 1'b1;
                branch      = 0;
                jal         = 0;
                jalr        = 0;

            end
            `IL_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b001;
                o_funct3    = funct3;
                dwe         = 1'b0;
                branch      = 0;
                jal         = 0;
                jalr        = 0;
            end
            `I_TYPE: begin
                rf_we   = 1'b1;
                alu_src = 1'b1;

                if (funct3 == 3'b101) begin
                    alu_control = {funct7[5], funct3};
                end else begin
                    alu_control = {1'b0, funct3};
                end

                rfwd_src = 3'b000;
                o_funct3 = funct3;
                dwe      = 1'b0;
                branch   = 0;
                jal      = 0;
                jalr     = 0;
            end
            `B_TYPE: begin
                rf_we       = 1'b0;
                alu_src     = 1'b0;
                alu_control = {1'b0, funct3};
                rfwd_src    = 3'b000;
                o_funct3    = funct3;
                dwe         = 1'b0;
                branch      = 1'b1;
                jal         = 0;
                jalr        = 0;
            end


            `U_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b011;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                branch      = 1'b0;
                jal         = 0;
                jalr        = 0;
            end
            `UL_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b010;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                branch      = 1'b0;
                jal         = 0;
                jalr        = 0;
            end
            `J_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b1;
                alu_control = 4'b0000;
                rfwd_src    = 3'b100;
                o_funct3    = 3'b000;
                dwe         = 1'b0;
                branch      = 1'b0;
                jal         = 1;
                jalr        = 0;
            end
            `JL_TYPE: begin
                rf_we       = 1'b1;
                alu_src     = 1'b0;
                alu_control = 4'b0000;
                rfwd_src    = 3'b100;
                o_funct3    = funct3;
                dwe         = 1'b0;
                branch      = 1'b0;
                jal         = 1;
                jalr        = 1;
            end
        endcase
    end
    */
endmodule
