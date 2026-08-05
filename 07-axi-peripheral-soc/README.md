# AXI4-Lite SPI/I2C Peripheral SoC

MicroBlaze에서 AXI4-Lite custom peripheral을 제어하는 HW/SW 통합 프로젝트입니다.
Vivado block design, custom RTL, UVM testbench, Vitis C application을 역할별로 분리했습니다.

## System Scope

- MicroBlaze and AXI interconnect
- AXI4-Lite custom GPIO/I2C peripheral
- Memory-mapped register control
- Vitis application, Driver, HAL layers
- UVM-based transaction verification

## Structure

```text
rtl/custom-ip/     custom AXI peripheral source
rtl/uvm-design/    RTL used by the UVM environment
tb/uvm/            UVM agent, driver, monitor, scoreboard, coverage
sw/                Vitis application, Driver, HAL
constraints/       Basys 3 XDC
scripts/uvm/       VCS/Verdi Makefile and file list
vivado/block-design/  design_1.bd and XCI metadata
vivado/ip-package/    IP packaging metadata
```

## Software Layers

```text
Application
  -> Driver (Button, FND, LED, SPI, I2C)
  -> HAL (GPIO, Timer)
  -> AXI4-Lite peripheral registers
```

## Verification Scope

- AXI write/read transaction
- Expected/observed data comparison in Scoreboard
- SPI/I2C peripheral data integrity
- Functional coverage by data range and operation

`scripts/uvm` 디렉터리에서 `make sim`을 실행하는 구성이며 VCS와 UVM 1.2 환경이 필요합니다.

## Reconstruction Note

대용량 BSP와 Vivado generated output은 제외했습니다. Block Design과 XCI는 구조 확인을 위해
포함했지만, 다른 PC에서 재생성할 때는 사용한 Vivado/Vitis 버전과 custom IP repository path를
맞춰야 합니다.

## Evidence to Add

- System architecture image
- AXI register map
- UVM coverage report
- FPGA board connection and result image

## Original Artifacts

- [Primary Vivado XPR](<./vivado/original-project/20260502-microblaze-i2c-spi/20260502_MicroBlaze_I2C_SPI_Master.xpr>)
- 같은 폴더의 `tmp_edit_project.xpr`는 Vivado가 만든 임시 편집 프로젝트입니다.
- [발표자료](<./docs/presentation/260508_SoC_AXI_Peripheral_장현동.pptx>)
