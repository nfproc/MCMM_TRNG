# constraints for Coherent Sampling-based TRNG with MMCMs
# See COPYING file for license information.

set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK }];
set_clock_groups -name mmcm_async -asynchronous -group { sys_clk_pin } -group { CLK_OUT_INT } -group { CLK_OUT_INT_1 };

set_property -dict { PACKAGE_PIN D9 IOSTANDARD LVCMOS33 } [get_ports { RST }];

set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { TXD }];

set_property -dict { PACKAGE_PIN H5 IOSTANDARD LVCMOS33 } [get_ports { LED }];