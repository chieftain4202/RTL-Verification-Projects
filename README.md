# Digital Design & Verification Portfolio

Verilog/SystemVerilog 기반 RTL 설계에서 시작해 통신 프로토콜, RV32I 프로세서,
AMBA APB/AXI 기반 SoC 주변장치, UVM 검증 환경까지 단계적으로 구현한 프로젝트 모음입니다.
별도의 Edge AI 프로젝트는 관련 경험을 보여주기 위해 마지막 항목에 구분해 수록했습니다.

> 관심 분야: RTL Design · Design Verification · FPGA · SoC · Embedded System

## Project Roadmap

```text
RTL 기초
  -> Stopwatch & Clock
  -> UART 통신
  -> SystemVerilog 검증
  -> RV32I Processor
  -> RV32I + AMBA APB SoC
  -> SPI/I2C + UVM
  -> AXI + MicroBlaze SoC
  -> YOLO Edge AI
```

## Featured Projects

### AXI-Based SPI/I2C Peripheral SoC

MicroBlaze에서 AXI4-Lite 레지스터를 통해 SPI/I2C Custom IP를 제어하는
HW/SW 통합 시스템입니다. UVM 검증 환경과 Vitis 애플리케이션 소스를 함께 정리했습니다.

- AXI4-Lite Slave register 기반 Custom IP
- MicroBlaze, AXI Interconnect, memory-mapped peripheral 구성
- Vitis C application, Driver, HAL 계층
- UVM Sequence, Driver, Monitor, Scoreboard, Coverage

[프로젝트 보기](./07-axi-peripheral-soc)

### SPI/I2C RTL & UVM Verification

SPI/I2C Master/Slave RTL과 재사용 가능한 UVM 환경을 구성하고,
FPGA 보드용 프로토타입 소스도 함께 정리했습니다.

- Protocol FSM과 shift register 설계
- Agent, Sequencer, Driver, Monitor, Scoreboard 구성
- Random transaction과 functional coverage
- VCS/Verdi 실행용 Makefile과 file list 포함

[프로젝트 보기](./06-spi-i2c-uvm)

### RV32I Processor

RV32I 명령어 형식에 맞춰 Datapath와 Control Unit을 구현하고
명령어별 레지스터·메모리 갱신 흐름을 검증한 프로젝트입니다.

[프로젝트 보기](./04-rv32i-processor)

## Projects

| No. | Project | Key Topics | Type |
|---:|---|---|---|
| 01 | [Stopwatch & Clock](./01-stopwatch-clock) | FSM, Datapath, Debounce, FND | RTL / FPGA |
| 02 | [UART Clock](./02-uart-clock) | UART TX/RX, Oversampling, ASCII Decoder | RTL / FPGA |
| 03 | [UART/FIFO Verification](./03-uart-fifo-verification) | Random Test, Scoreboard, SystemVerilog | Verification |
| 04 | [RV32I Processor](./04-rv32i-processor) | ISA, Datapath, Control Unit | RTL |
| 05 | [RV32I APB SoC](./05-rv32i-apb-soc) | Multi-cycle CPU, APB, GPIO, FND, UART | RTL / SoC |
| 06 | [SPI/I2C UVM](./06-spi-i2c-uvm) | Protocol RTL, UVM, Coverage | RTL / Verification |
| 07 | [AXI Peripheral SoC](./07-axi-peripheral-soc) | AXI4-Lite, MicroBlaze, Vitis | HW/SW Co-design |
| 08 | [YOLO Vehicle Detection](./08-yolo-vehicle-detection) | YOLO, OpenCV, TensorRT | Edge AI |

## Technical Skills

| Category | Skills |
|---|---|
| HDL | Verilog, SystemVerilog |
| Verification | Self-checking Testbench, UVM, Constrained Random, Scoreboard, Functional Coverage |
| Architecture | RV32I, Single-cycle/Multi-cycle Datapath, FSM |
| Bus & Interface | AMBA APB, AXI4-Lite, UART, SPI, I2C |
| FPGA & Embedded | AMD Vivado, Vitis, MicroBlaze, Basys 3 |
| Programming | C, Python |
| Edge AI | YOLO, OpenCV, ONNX, TensorRT |

## Repository Structure

```text
rtl/          synthesizable RTL and custom IP
tb/           testbench and UVM components
constraints/  FPGA XDC constraints
memory/       processor memory initialization files
fpga/         board-level protocol prototypes
sw/           embedded C application, Driver, HAL
scripts/      simulation Makefile and file list
vivado/       block design and IP metadata required for reconstruction
docs/         presentation files and editable diagrams
src/          Python application source
```

## Notes

- 이 폴더는 원본 툴 프로젝트에서 사람이 작성한 소스와 재구성에 필요한 파일을 중심으로 선별한 포트폴리오 사본입니다.
- Vivado/VCS/Vitis가 자동 생성하는 캐시, 빌드 결과, 시뮬레이터 바이너리는 포함하지 않았습니다.
- 기존 Vivado XPR와 대응 `.srcs`는 각 프로젝트의 `vivado/original-project*`에 보존했습니다.
- 기존 발표자료 8개는 각 프로젝트의 `docs/presentation`에 원본 PPTX로 보존했습니다.
- 팀 프로젝트의 개인 기여 범위는 각 프로젝트 README에서 구분합니다.
- 원본 경로와 제외 항목은 [MIGRATION_NOTES.md](./MIGRATION_NOTES.md)에 기록했습니다.
- 라이선스는 팀 코드와 벤더 생성 코드의 권리 관계를 확인한 뒤 별도로 결정해야 합니다.
