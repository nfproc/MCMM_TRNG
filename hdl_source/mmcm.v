// MMCM Instantiation
// 2020-03-07 Naoki F., AIT
// New BSD License is applied. See COPYING file for details.

module MMCM_AR7 (CLK_IN, RST, CLK_OUT, LOCKED);
    input  CLK_IN, RST;
    output CLK_OUT, LOCKED;

    parameter MMCM_D = 1;
    parameter MMCM_M = 7.750;
    parameter MMCM_Q = 8.000;

    wire   CLK_OUT_INT, CLKFB;

    BUFG OUTBUF (.I(CLK_OUT_INT), .O(CLK_OUT));

    MMCME2_BASE # (.CLKFBOUT_MULT_F(MMCM_M),
                   .CLKIN1_PERIOD(10.0),
                   .CLKOUT0_DIVIDE_F(MMCM_Q),
                   .CLKOUT0_DUTY_CYCLE(0.5),
                   .CLKOUT0_PHASE(0.0),
                   .DIVCLK_DIVIDE(MMCM_D))
    MMCM_INST (.RST(RST),
               .CLKIN1(CLK_IN),
               .CLKFBIN(CLKFB),
               .CLKFBOUT(CLKFB),
               .CLKOUT0(CLK_OUT_INT),
               .LOCKED(LOCKED),
               .PWRDWN(1'b0));
endmodule