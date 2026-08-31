# RV32I Multi-Cycle SoC with AMBA APB

Multi-cycle RV32I CPU, APB Master, BRAM, GPIO, FND, UART peripheral을 통합한 팀 프로젝트입니다.

## Architecture

- Fetch, Decode, Execute, Memory, Write Back state flow
- APB IDLE, SETUP, ACCESS state machine
- Wait-state capable APB transaction
- Memory-mapped BRAM and peripherals
- Firmware image loaded through memory initialization files

## Memory Map

| Peripheral | Address Range | Size |
|---|---:|---:|
| BRAM | `0x1000_0000`-`0x1000_0FFF` | 4 KB |
| GPIO | `0x2000_2000`-`0x2000_2FFF` | 4 KB |
| FND | `0x2000_3000`-`0x2000_3FFF` | 4 KB |
| UART | `0x2000_4000`-`0x2000_4FFF` | 4 KB |

## Personal Contribution

- APB Slave GPIO/FND register와 peripheral logic 설계
- GPIO direction/data register 구현
- FND data/load register 구현
- 담당 peripheral simulation

## Structure

```text
rtl/          RV32I, APB, BRAM, GPIO, FND, UART RTL
tb/           integrated processor testbench
memory/       firmware and processor memory images
constraints/  Basys 3 constraints
```

## Evidence to Add

- CPU/APB/peripheral architecture diagram
- APB transfer waveform
- GPIO/FND register test result
- FPGA firmware execution video

## Original Artifacts

- [Vivado XPR](<./vivado/original-project/20260325-rv32i-amba-apb/Rv32i_AMBA_APB.xpr>)
- [발표자료](<./docs/presentation/3조_김수빈, 장현동, 문태성, 조승아_RV32I Multi Cycle 설계.pptx>)
