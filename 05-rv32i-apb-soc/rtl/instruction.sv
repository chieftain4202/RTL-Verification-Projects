`timescale 1ns / 1ps

module instruction_mem (
    input  [31:0] instr_addr,
    output [31:0] instr_data
);

    logic [31:0] rom[0:256];

    initial begin
            //$readmemh("Rivc_V_rv32_rom.mem",rom);
            //$readmemh("APB_Rom.mem",rom);
            //$readmemh("APB_GPO.mem",rom);
            //$readmemh("APB_BRAM_GPO_GPI.mem",rom);
            //$readmemh("APB_GPIO_LED_BLINK.mem",rom);
            //$readmemh("APB_GPIO.mem",rom);
            $readmemh("APB_FNDC.mem",rom);
    //    rom[0] = 32'h123452B7;  // LUI   x5,  0x12345   -> x5 = 0x12345000
    //    rom[1] = 32'hABCDE337;  // LUI   x6,  0xABCDE   -> x6 = 0xABCDE000
    //    rom[2] = 32'h00010397;  // AUIPC x7,  0x00010   -> x7 = PC + 0x00010000
    //    rom[3] = 32'h00001417;  // AUIPC x8,  0x00001   -> x8 = PC + 0x00001000


    end
    //    rom[0] = 32'h004182b3;  // ADD X5, X3, X4
    //    rom[1] = 32'h00812123;  // SW x2, 2(x8),  sw x2,x8,2
    //    rom[2] = 32'h00212383;  // LW x7, X2, 2
    //    rom[3] = 32'h00840463;  // BEQ x8, x8, 8
    //    rom[4] = 32'h004182b3;  // ADD X5, X3, X4
    //    rom[5] = 32'h00812123;  // SW x2, 2(x8),  sw x2,x8,2
    //    rom[6] = 32'h00812123;  // SW x2, 2(x8)
    //    rom[7] = 32'h00812123;  // SW x2, 2(x8)

    assign instr_data = rom[instr_addr[31:2]];
    // rom[11] = {7'b0, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011};
    // rom[3] = 32'h00838463;  // BEQ X7, X8, 8
endmodule


module data_mem (
    input         clk,
    input         rst,
    input         dwe,
    input  [ 2:0] i_funct3,
    input  [31:0] daddr,
    input  [31:0] dwdata,
    output [31:0] drdata
);

    logic [31:0] dmem[0:200];
    logic [31:0] load_data, word_data;
    logic [1:0] byte_off;

    assign byte_off  = daddr[1:0];
    assign word_data = dmem[daddr[31:2]];

    // Store path
    always_ff @(posedge clk) begin
        if (dwe) begin
            case (i_funct3)
                3'b000: begin  // SB
                    case (byte_off)
                        2'b00: dmem[daddr[31:2]][7:0] <= dwdata[7:0];
                        2'b01: dmem[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b10: dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: dmem[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end
                3'b001: begin  // SH
                    if (byte_off[1] == 1'b0)
                        dmem[daddr[31:2]][15:0] <= dwdata[15:0];
                    else dmem[daddr[31:2]][31:16] <= dwdata[15:0];
                end
                3'b010:  dmem[daddr[31:2]] <= dwdata;  // SW
                default: ;
            endcase
        end
    end

    // IL_TYPE load path
    always_comb begin
        load_data = 32'd0;
        case (i_funct3)
            3'b000: begin  // LB
                case (byte_off)
                    2'b00: load_data = {{24{word_data[7]}}, word_data[7:0]};
                    2'b01: load_data = {{24{word_data[15]}}, word_data[15:8]};
                    2'b10: load_data = {{24{word_data[23]}}, word_data[23:16]};
                    2'b11: load_data = {{24{word_data[31]}}, word_data[31:24]};
                endcase
            end
            3'b001: begin  // LH
                if (byte_off[1] == 1'b0)
                    load_data = {{16{word_data[15]}}, word_data[15:0]};
                else load_data = {{16{word_data[31]}}, word_data[31:16]};
            end
            3'b010:  load_data = word_data;  // LW
            3'b100: begin  // LBU
                case (byte_off)
                    2'b00: load_data = {24'b0, word_data[7:0]};
                    2'b01: load_data = {24'b0, word_data[15:8]};
                    2'b10: load_data = {24'b0, word_data[23:16]};
                    2'b11: load_data = {24'b0, word_data[31:24]};
                endcase
            end
            3'b101: begin  // LHU
                if (byte_off[1] == 1'b0) load_data = {16'b0, word_data[15:0]};
                else load_data = {16'b0, word_data[31:16]};
            end
            default: load_data = word_data;
        endcase
    end

    assign drdata = load_data;

endmodule
