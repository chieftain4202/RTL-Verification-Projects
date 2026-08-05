`timescale 1ns / 1ps

module GPIO (
    input        Pclk,
    input        Prst,
    input        Penable,
    input        Pwrite,
    input        Psel,
    input [31:0] Pwdata,
    input [31:0] Paddr,

    output logic [31:0] Prdata,
    output logic        Pready,
    inout  logic [15:0] gpio
);

    localparam [11:0] GPIO_ctl_addr = 12'h000;
    localparam [11:0] GPIO_odata_addr = 12'h004;
    localparam [11:0] GPIO_idata_addr = 12'h008;
    logic we;
    logic [15:0] GPIO_odata_reg, GPIO_ctl_reg, GPIO_idata_reg;

    assign we = (Penable & Pwrite & Psel);
    assign Pready = (Penable & Psel) ? 1'b1 : 1'b0;

    assign Prdata = (Paddr[11:0] == GPIO_ctl_addr) ? {16'h0000,GPIO_ctl_reg} :
                    (Paddr[11:0] == GPIO_odata_addr) ? {16'h0000,GPIO_odata_reg} :
                    (Paddr[11:0] == GPIO_idata_addr) ? {16'h0000,GPIO_idata_reg} :
                    32'hxxxx_xxxx;

    always_ff @(posedge Pclk, posedge Prst) begin
        if (Prst) begin
            GPIO_odata_reg <= 16'd0;
            GPIO_ctl_reg   <= 16'd0;
        end else begin
            if (Pready) begin
                if (Pwrite) begin
                    case (Paddr[11:0])
                        GPIO_ctl_addr:   GPIO_ctl_reg <= Pwdata[15:0];
                        GPIO_odata_addr: GPIO_odata_reg <= Pwdata[15:0];
                    endcase
                end
            end

        end
    end

    gpio U_gpio (
        .ctl   (GPIO_ctl_reg),
        .o_data(GPIO_odata_reg),
        .i_data(GPIO_idata_reg),
        .gpio  (gpio)
    );
endmodule

module gpio (
    input        [15:0] ctl,
    input        [15:0] o_data,
    output logic [15:0] i_data,
    inout  logic [15:0] gpio
);

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin
            assign gpio[i]   = ctl[i] ? o_data[i] : 1'dz;
            assign i_data[i] = ~ctl[i] ? gpio[i] : 1'b0;
        end

    endgenerate

endmodule
