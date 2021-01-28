// Top Module of Coherent Sampling-based TRNG with MMCMs
// 2020-03-07 Naoki F., AIT
// New BSD License is applied. See COPYING file for details.

`include "define.v"

module TOP (CLK, RST, TXD, LED);
    input        CLK, RST;
    output       TXD;
    output       LED;

    wire         clk_a, clk_b, locked_a, locked_b, rst_int;
    wire   [7:0] count, pack_data;
    wire         count_en;
    wire  [31:0] uart_data;
    reg   [11:0] send_count;
    reg          uart_en;
    wire         uart_we, pack_en;

    assign rst_int   = RST | ~locked_a | ~locked_b;
    assign uart_data = {24'h0, pack_data};
    assign LED       = count_en;
    assign uart_we   = uart_en & pack_en;

    MMCM_AR7 #(.MMCM_D(`MMCMA_D), .MMCM_M(`MMCMA_M), .MMCM_Q(`MMCMA_Q))
        MMCMA (.CLK_IN(CLK), .RST(RST), .CLK_OUT(clk_a), .LOCKED(locked_a));
    MMCM_AR7 #(.MMCM_D(`MMCMB_D), .MMCM_M(`MMCMB_M), .MMCM_Q(`MMCMB_Q))
        MMCMB (.CLK_IN(CLK), .RST(RST), .CLK_OUT(clk_b), .LOCKED(locked_b));

    COUNTER #(.PERIOD(`CNT_PERIOD))
        CNT (.CLK(CLK), .RST(rst_int), .D_FF(clk_a), .CLK_FF(clk_b),
             .COUNT(count), .COUNT_EN(count_en));
    Pack1b8b #(.PACK_ENABLE(`PACK_ENABLE)) 
        PACK(.CLK(CLK), .RST(rst_int), .DIN(count), .WE(count_en),
             .DOUT(pack_data), .EN(pack_en));
    uartsender UART (.CLK(CLK), .RST(rst_int), .DATA(uart_data), .WE(uart_we),
                     .MODE(1'b1), .TXD(TXD), .READY(), .EMPTY(empty), .FULL());
                     
    always @(posedge CLK) begin
        if (rst_int) begin
            send_count <= 12'd0;
            uart_en    <= 1'b1;
        end else if (uart_en) begin
            if (count_en) begin
                send_count <= send_count + 1'b1;
                uart_en    <= (send_count < 12'd4000);
            end
        end else begin
            if (empty) begin
                uart_en    <= 1'b1;
            end
        end
    end
endmodule