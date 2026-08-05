## Basys3 constraints for demo_slave
## Top module ports:
## clk, rst, sscl, ssda, fnd_digit[3:0], fnd_data[7:0]

## Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset button
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports rst]

## I2C slave pins on PMOD JC
## JC1: SCL input from master mscl
## JC2: SDA open-drain inout to master msda
set_property -dict { PACKAGE_PIN K17 IOSTANDARD LVCMOS33 } [get_ports sscl]
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 PULLUP true } [get_ports ssda]

## 7-segment display segments
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[0]}]
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[1]}]
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[2]}]
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[3]}]
set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[4]}]
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[5]}]
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[6]}]
set_property -dict { PACKAGE_PIN V7 IOSTANDARD LVCMOS33 } [get_ports {fnd_data[7]}]

## 7-segment digit enables
set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[0]}]
set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[1]}]
set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[2]}]
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports {fnd_digit[3]}]

## Configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
