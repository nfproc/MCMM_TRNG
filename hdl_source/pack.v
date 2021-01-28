// Data Packer
// 2020-03-07 Naoki F., AIT
// New BSD License is applied. See COPYING file for details.

module Pack1b8b(CLK, RST, DIN, WE, DOUT, EN);
    input        CLK, RST;
    input  [7:0] DIN;
    input        WE;
    output [7:0] DOUT;
    output       EN;

    parameter PACK_ENABLE = 1'b1;

    reg    [2:0] d_avail;
    reg    [6:0] d_past;

    assign DOUT    = (PACK_ENABLE) ? {d_past, DIN[0]} : DIN;
    assign EN      = (&d_avail) & WE;

    always @(posedge CLK) begin
        if (RST) begin
            d_avail <= PACK_ENABLE ? 3'b000 : 3'b111;
            d_past  <= 7'b0000000;
        end else if (PACK_ENABLE & WE) begin
            d_avail <= d_avail + 1'b1;
            d_past  <= {d_past[5:0], DIN[0]};
        end
    end
endmodule