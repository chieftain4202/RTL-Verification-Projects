# SPI/I2C RTL Design & UVM Verification

SPI와 I2C Master/Slave RTL을 설계하고 UVM environment와 FPGA prototype으로 검증한 프로젝트입니다.

## Design Scope

- SPI Master/Slave FSM and shift register
- I2C Start, Stop, Address, ACK/NACK, Read/Write
- FPGA board-level Master/Slave prototypes

## UVM Environment

- Sequence Item and Sequence
- Sequencer and Driver
- Monitor and Agent
- Scoreboard
- Functional Coverage
- Test and Environment

## Structure

```text
rtl/i2c/       I2C DUT
rtl/spi/       SPI DUT
tb/i2c/        I2C UVM components
tb/spi/        SPI UVM components
fpga/          board-level prototypes
scripts/       VCS/Verdi Makefile and file list
docs/          editable Draw.io diagrams
```

## Running the Original UVM Setup

각 `scripts/*/Makefile`과 `filelist.f`는 재배치된 소스 경로에 맞게 갱신했습니다.
해당 script 디렉터리에서 `make sim`을 실행하는 구성이며, 설치된 UVM/VCS 버전은 별도로 확인해야 합니다.

## Evidence to Add

- Random transaction count and pass/fail summary
- Functional coverage percentage
- SPI mode and I2C ACK/NACK waveform
- FPGA board-to-board communication result

## Original Artifacts

- [Vivado XPR 프로젝트 모음](./vivado/original-projects)
- [발표자료](<./docs/presentation/260420_SPI_I2C_UVM_verification_장현동.pptx>)
