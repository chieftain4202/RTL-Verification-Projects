# RV32I Processor

RV32I 기본 정수 명령어의 Datapath와 Control Flow를 SystemVerilog로 구현한 Single-Cycle Processor 프로젝트입니다.

명령어를 해석해 Control Signal을 생성하고, Register File·Immediate Generator·ALU·Data Memory·Write Back 경로를 통해 연산 결과가 저장되도록 구성했습니다.

## Architecture

PC에서 Instruction Memory의 명령어를 가져오고, Control Unit이 Opcode·Funct3·Funct7을 해석하여 Datapath 제어 신호를 생성합니다.

Register File에서 읽은 Operand와 Immediate Generator에서 생성한 값을 ALU에 전달하며, 명령어 종류에 따라 ALU Result, Load Data, Immediate, PC+Immediate 또는 PC+4를 Register File에 Write Back하도록 구성했습니다. Branch와 Jump 명령은 비교 결과와 Immediate를 이용해 다음 PC를 결정합니다.

<img width="778" alt="RV32I Processor 전체 블록도" src="https://github.com/user-attachments/assets/64cc517d-20ca-4167-a297-a1b7783a946f" />

## Implemented Instructions

| Category | Instructions |
|---|---|
| R-type | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND` |
| I-type | `ADDI`, `SLLI`, `SLTI`, `SLTIU`, `XORI`, `SRLI`, `SRAI`, `ORI`, `ANDI` |
| Load | `LB`, `LH`, `LW`, `LBU`, `LHU` |
| Store | `SB`, `SH`, `SW` |
| Branch | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Upper Immediate | `LUI`, `AUIPC` |
| Jump | `JAL`, `JALR` |

## Main Components

- Program Counter 및 Next PC 선택 회로
- Instruction Memory와 Data Memory Interface
- 32×32-bit Register File
- R/I/S/B/U/J-type Immediate Generator
- Arithmetic, Logic, Shift 및 Comparison ALU
- Opcode·Funct3·Funct7 기반 Control Unit
- Branch Condition Comparator
- Load Data의 부호·제로 확장 처리
- Byte·Half Word·Word Store 처리
- ALU·Memory·Immediate·PC 기반 Write Back MUX

## Structure

```text
rtl/
  Active RTL referenced by the Vivado project

rtl/legacy/
  Older imported RTL variants retained for comparison

tb/
  Processor testbench

tb/legacy/
  Older processor testbench

memory/
  Program memory initialization data
```

## Verification

다음 항목을 중심으로 Processor의 명령어 실행 결과를 확인했습니다.

- 명령어 계열별 Register Write 여부와 결과값
- Byte·Half Word·Word Load/Store Memory Access
- Branch 조건에 따른 PC 변경
- `JAL`과 `JALR`의 Jump 및 Return Address 처리
- `LUI`와 `AUIPC`의 Immediate Write Back
- C Test Program에서 변환한 Machine Code 실행 흐름

## C Test Program

함수 호출, 반복문, 조건 분기와 산술 연산이 포함된 C 코드를 Test Program으로 사용했습니다.

```c
int adder(int a, int b);

void main(void)
{
    int i = 0;
    int sum = 0;

    while (i < 11) {
        i = i + 1;
        sum = adder(i, sum);
    }
}

int adder(int a, int b)
{
    return a + b;
}
```

Test Program은 다음 순서로 Processor의 Instruction Memory에 적용했습니다.

```text
C Source
  → RV32I Assembly
  → 32-bit Machine Code
  → Hexadecimal ROM Data
  → Instruction Memory Initialization
  → RTL Simulation
```

반복문에서 1부터 11까지 누적하므로 최종 예상값은 `66`입니다. 이를 기준으로 Program Counter의 명령어 진행, 함수 호출과 복귀, Register File 및 Memory의 상태 변화를 확인했습니다.

사용한 ROM 초기화 데이터는 [Rivc_V_rv32_rom.mem](./memory/Rivc_V_rv32_rom.mem)에서 확인할 수 있습니다.

## Program Execution Waveform

C 코드에서 변환한 Machine Code를 ROM에 적재한 후, Program Counter와 Instruction Address가 반복문 및 함수 호출 흐름에 따라 변경되는지 확인했습니다.

파형을 통해 순차 명령어에서는 주소가 증가하고, Branch·Jump·함수 호출 및 복귀 구간에서는 계산된 Target Address로 실행 흐름이 이동하는지 추적했습니다.

<img width="1129" alt="RV32I C Test Program Address Waveform" src="https://github.com/user-attachments/assets/808adcb3-347b-4683-915c-3a1ca16e9eb3" />

## Register File Verification

Instruction Address의 진행과 함께 Register File 상태를 확인하여, 각 명령어의 Source Register와 Destination Register가 의도한 순서로 사용되는지 검증했습니다.

특히 반복문의 Index 증가, `adder()` 함수의 Argument 전달, 덧셈 결과 반환 및 누적값 갱신 과정을 추적했습니다.

<img width="915" alt="RV32I Adder Test Register File State" src="https://github.com/user-attachments/assets/2e677039-15a5-462c-8edd-fe329e11a5f2" />


## C Test Program 누적 연산 결과

C Test Program에서 반복문과 `adder()` 함수를 실행하고, Register File의 값이 누적되는 과정을 Simulation 파형으로 확인했습니다.

RISC-V 호출 규약에 따라 `x10(a0)`은 함수의 첫 번째 인자와 반환값으로 사용되고, `x11(a1)`은 두 번째 인자를 전달합니다. 파형에서 `x11`에는 호출 직전의 누적값 `55`가 전달되며, `adder()` 실행 후 최종 계산 결과인 `66 (0x00000042)`이 `x10`에 반환되는 것을 확인했습니다.

<img width="1124" height="529" alt="image" src="https://github.com/user-attachments/assets/6398446e-36c0-4e0a-a9df-891d96b677a8" />


## Original Artifacts

- [Vivado XPR](./vivado/original-project/20260309-rv32i/20260309_RV32I_S.xpr)
- [발표자료](<./docs/presentation/RISC-V 장현동.pptx>)
