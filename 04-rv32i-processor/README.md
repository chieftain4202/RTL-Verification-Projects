# RV32I Processor

RV32I 기본 정수 명령어의 Datapath와 Control Flow를 SystemVerilog로 구현한 프로세서 프로젝트입니다.

## Implemented Scope

- R-type and I-type arithmetic/logic instructions
- Load and Store
- Branch and Jump
- Upper-immediate instructions
- Register File, Immediate Generator, ALU, instruction/data memory interface

## Structure

```text
rtl/       active RTL referenced by the Vivado project
tb/        processor testbench
memory/    program memory initialization
*/legacy/  older imported variants retained for comparison
```

## Verification

- 명령어 계열별 register update 확인
- Load/Store memory access 확인
- Branch/Jump PC update 확인
- C 코드에서 변환한 machine code 실행 흐름 확인

## Evidence to Add

- Datapath block diagram
- Supported instruction table
- Representative register/memory waveform
- Test program and expected result

## Original Artifacts

- [Vivado XPR](<./vivado/original-project/20260309-rv32i/20260309_RV32I_S.xpr>)
- [발표자료](<./docs/presentation/RISC-V 장현동.pptx>)
