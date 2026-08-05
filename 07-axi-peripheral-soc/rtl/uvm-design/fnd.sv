`timescale 1ns / 1ps

module fnd_controller (
    input  logic       clk,   
    input  logic       rst,     
    input  logic [7:0] data_in,  
    output logic [7:0] fnd_seg,  
    output logic [3:0] fnd_sel  
);
    localparam TIME_1MS = 100_000;
    logic [16:0] count_1ms;
    logic        tick_1ms;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            count_1ms <= 17'd0;
            tick_1ms  <= 1'b0;
        end else begin
            if (count_1ms == TIME_1MS - 1) begin
                count_1ms <= 17'd0;
                tick_1ms  <= 1'b1;
            end else begin
                count_1ms <= count_1ms + 1;
                tick_1ms  <= 1'b0;
            end
        end
    end

    logic [1:0] digit_sel;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            digit_sel <= 2'b00;
        end else if (tick_1ms) begin
            digit_sel <= digit_sel + 1;
        end
    end

    logic [3:0] hex_data;
    logic       digit_off; 

    always_comb begin
        digit_off = 1'b0;
        case (digit_sel)
            2'b00: begin
                fnd_sel  = 4'b1110;       
                hex_data = data_in[3:0];  
            end
            2'b01: begin
                fnd_sel  = 4'b1101;      
                hex_data = data_in[7:4];  
            end
            2'b10: begin
                fnd_sel   = 4'b1011;     
                hex_data  = 4'h0;
                digit_off = 1'b1;         
            end
            2'b11: begin
                fnd_sel   = 4'b0111;      
                hex_data  = 4'h0;
                digit_off = 1'b1;        
            end
            default: begin
                fnd_sel   = 4'b1111;
                hex_data  = 4'h0;
                digit_off = 1'b1;
            end
        endcase
    end

    always_comb begin
        if (digit_off) begin
            fnd_seg = 8'hFF;
        end else begin
            case (hex_data)
                4'h0: fnd_seg = 8'hC0;
                4'h1: fnd_seg = 8'hF9; 
                4'h2: fnd_seg = 8'hA4; 
                4'h3: fnd_seg = 8'hB0; 
                4'h4: fnd_seg = 8'h99; 
                4'h5: fnd_seg = 8'h92; 
                4'h6: fnd_seg = 8'h82; 
                4'h7: fnd_seg = 8'hF8; 
                4'h8: fnd_seg = 8'h80; 
                4'h9: fnd_seg = 8'h90; 
                4'hA: fnd_seg = 8'h88; 
                4'hB: fnd_seg = 8'h83; 
                4'hC: fnd_seg = 8'hC6; 
                4'hD: fnd_seg = 8'hA1; 
                4'hE: fnd_seg = 8'h86; 
                4'hF: fnd_seg = 8'h8E; 
                default: fnd_seg = 8'hFF;
            endcase
        end
    end

endmodule