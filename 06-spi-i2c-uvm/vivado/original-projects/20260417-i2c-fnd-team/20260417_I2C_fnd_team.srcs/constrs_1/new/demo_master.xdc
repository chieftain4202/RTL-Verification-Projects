## Basys3 constraints for demo_master
## Top module ports:
## clk, rst, sw[7:0], btn_start, btn_stop, btn_addr, btn_write, mscl, msda

## Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Switches
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {sw[0]}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {sw[1]}]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports {sw[2]}]
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } [get_ports {sw[3]}]
set_property -dict { PACKAGE_PIN W15 IOSTANDARD LVCMOS33 } [get_ports {sw[4]}]
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports {sw[5]}]
set_property -dict { PACKAGE_PIN W14 IOSTANDARD LVCMOS33 } [get_ports {sw[6]}]
set_property -dict { PACKAGE_PIN W13 IOSTANDARD LVCMOS33 } [get_ports {sw[7]}]

## Buttons
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst]
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports btn_start]
set_property -dict { PACKAGE_PIN W19 IOSTANDARD LVCMOS33 } [get_ports btn_stop]
set_property -dict { PACKAGE_PIN T17 IOSTANDARD LVCMOS33 } [get_ports btn_addr]
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports btn_write]

## I2C master pins on PMOD JB
## JB1: SCL output
## JB2: SDA open-drain inout
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports mscl]
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 PULLUP true } [get_ports msda]

## Configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
