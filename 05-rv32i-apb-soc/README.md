# RV32I Multi-Cycle SoC with AMBA APB

Multi-Cycle RV32I CPU와 APB Master, BRAM, GPIO, FND, UART Peripheral을 통합한 팀 프로젝트입니다.

C Firmware를 Machine Code로 변환해 Instruction Memory에 적재하고, CPU가 Memory-Mapped APB Register를 통해 GPIO와 FND를 제어하는 FPGA 기반 SoC를 구현했습니다.

## System Architecture

<div align="center">
  <img width="677" alt="RV32I Multi-Cycle SoC with AMBA APB Block Diagram" src="https://github.com/user-attachments/assets/6402f998-71ef-4a33-9439-83b0da408a78" />
  <br>
  <sub>RV32I CPU, APB Master, Address Decoder와 Memory-Mapped Peripheral의 통합 구조</sub>
</div>

RV32I CPU에서 발생한 Instruction Fetch 요청은 Instruction Memory로 전달됩니다. Load/Store 명령에서 발생한 Data Memory 요청은 APB Master로 전달되며, Address Decoder가 주소 범위에 따라 BRAM, GPIO, FND 또는 UART를 선택합니다.

```text
Instruction Memory
        ↓
Multi-Cycle RV32I CPU
        ↓ Load / Store Request
     APB Master
        ↓
  Address Decoder
        ├─ BRAM
        ├─ GPIO
        ├─ FND
        └─ UART
```

CPU는 Memory-Mapped Address를 사용하므로 일반 메모리와 주변장치를 동일한 Load/Store 명령으로 접근할 수 있습니다.

## RV32I Multi-Cycle CPU

<div align="center">
  <img width="667" alt="RV32I Multi-Cycle CPU Datapath Block Diagram" src="https://github.com/user-attachments/assets/2c102f16-41da-494c-9805-288d112481ea" />
  <br>
  <sub>Control Unit, Register File, ALU, Immediate Generator와 Memory Interface로 구성한 Multi-Cycle Datapath</sub>
</div>

Multi-Cycle 구조는 하나의 명령어를 한 Clock에 모두 처리하지 않고, 명령어 처리 과정을 여러 상태로 나누어 실행합니다.

각 상태에서는 Datapath의 일부만 사용하며, Control Unit이 현재 상태와 `Opcode`, `Funct3`, `Funct7`을 기준으로 ALU 선택, Register Write, Memory Access와 PC 갱신 신호를 생성합니다.

```text
FETCH
  → DECODE
  → EXECUTE
  → MEMORY
  → WRITE BACK
```

Single-Cycle 구조는 가장 긴 명령어 경로에 Clock 주기를 맞춰야 하지만, Multi-Cycle 구조는 연산을 여러 단계로 분리하여 각 단계의 조합논리 경로를 줄일 수 있습니다. 또한 ALU와 같은 연산 자원을 여러 상태에서 재사용할 수 있습니다.

대신 명령어 하나를 완료하는 데 여러 Clock이 필요하며, 명령어 종류에 따라 거치는 상태와 CPI가 달라집니다.

### Instruction Execution Stages

| Stage | 주요 동작 |
|---|---|
| `FETCH` | PC를 Instruction Memory 주소로 전달하고 명령어를 읽음 |
| `DECODE` | Opcode와 Function Field를 해석하고 Register File의 `rs1`, `rs2`를 읽음 |
| `EXECUTE` | ALU 연산, Memory Address 계산, Branch 비교 또는 Jump Target 계산 |
| `MEMORY` | Load/Store 명령의 BRAM 또는 APB Peripheral Read/Write 수행 |
| `WRITE BACK` | ALU 결과나 Load 데이터를 목적 Register `rd`에 기록 |

### Instruction-Type State Flow

| Instruction Type | 주요 상태 흐름 |
|---|---|
| R-Type | Fetch → Decode → ALU Execute → Write Back |
| I-Type Arithmetic | Fetch → Decode → Immediate ALU Execute → Write Back |
| Load | Fetch → Decode → Address Calculate → Memory Read → Write Back |
| Store | Fetch → Decode → Address Calculate → Memory Write |
| Branch | Fetch → Decode → Compare → 조건에 따른 PC 갱신 |
| JAL/JALR | Fetch → Decode → Jump Target 계산 → PC 및 `rd` 갱신 |
| LUI/AUIPC | Fetch → Decode → Immediate/PC 연산 → Write Back |

### Main Datapath Components

| Component | 역할 |
|---|---|
| Program Counter | 현재 명령어 주소 유지 및 다음 PC 갱신 |
| Instruction Memory | PC에 해당하는 Machine Code 출력 |
| Control Unit | 명령어와 현재 State에 따른 제어 신호 생성 |
| Register File | `rs1`, `rs2` Operand Read와 `rd` Result Write |
| Immediate Generator | 명령어 Type별 Immediate 확장 |
| ALU | 산술·논리 연산, 주소와 Branch Target 계산 |
| ALU Result Register | 여러 Cycle 사이에서 ALU 결과 유지 |
| Load Data Register | Memory Read 데이터를 Write Back 단계까지 유지 |
| Data Memory Interface | BRAM 또는 APB Master로 Load/Store 요청 전달 |
| Write-Back MUX | ALU Result, Load Data, PC+4 중 Register 입력 선택 |

## APB Transaction

CPU의 Load/Store 요청이 Peripheral 주소를 대상으로 하면 APB Master가 APB Transaction을 시작합니다.

```text
IDLE
  → SETUP
  → ACCESS
  → PREADY 확인
  → IDLE
```

### APB State Operation

| State | 주요 동작 |
|---|---|
| `IDLE` | Transaction 요청을 기다림 |
| `SETUP` | `PADDR`, `PWRITE`, `PWDATA`, `PSEL` 설정 |
| `ACCESS` | `PENABLE`을 활성화하고 Slave 응답 대기 |
| Wait State | `PREADY=0`이면 ACCESS 상태와 제어 신호 유지 |
| Complete | `PREADY=1`이면 Read/Write 완료 후 IDLE 복귀 |

### APB Signals

| Signal | 역할 |
|---|---|
| `PADDR` | Peripheral과 내부 Register 주소 |
| `PSEL` | Address Decoder가 선택한 APB Slave 활성화 |
| `PENABLE` | APB ACCESS Phase 표시 |
| `PWRITE` | `1`: Write, `0`: Read |
| `PWDATA` | APB Write Data |
| `PRDATA` | APB Read Data |
| `PREADY` | Slave의 Transaction 완료 응답 |

## Key Features

- Fetch, Decode, Execute, Memory, Write Back 기반 Multi-Cycle CPU
- 명령어 Type별 상태 전이와 Control Signal 생성
- Register File, Immediate Generator, ALU와 Memory Interface 구성
- APB IDLE, SETUP, ACCESS State Machine
- `PREADY` 응답과 Wait State를 고려한 APB Transaction
- Address Decoder를 이용한 Peripheral 선택
- Memory-Mapped BRAM 및 Peripheral Register
- C Firmware 기반 GPIO/FND 제어
- Memory Initialization File을 이용한 Program 실행
- Basys 3 FPGA 통합 동작 검증

## Memory Map

| Peripheral | Address Range | Size |
|---|---:|---:|
| BRAM | `0x1000_0000`–`0x1000_0FFF` | 4 KB |
| GPIO | `0x2000_2000`–`0x2000_2FFF` | 4 KB |
| FND | `0x2000_3000`–`0x2000_3FFF` | 4 KB |
| UART | `0x2000_4000`–`0x2000_4FFF` | 4 KB |

## Personal Contribution

팀 프로젝트에서 GPIO와 FND APB Slave의 RTL 및 Register Map 구현을 담당했습니다.

- APB Slave GPIO/FND Register 설계
- `PSEL`, `PENABLE`, `PWRITE`, `PREADY` 기반 Read/Write 처리
- GPIO Direction, Output Data, Input Data Register 구현
- GPIO Pin의 Input·Output·High-Z 제어
- FND Display Data 및 Digit/Load Register 구현
- APB Transaction Simulation
- CPU·APB·Peripheral 통합 및 FPGA 동작 확인

## Peripheral Register Map

### GPIO

Base Address: `0x2000_2000`

| Offset | Register | Function |
|---:|---|---|
| `+0x00` | Control Register | GPIO Pin별 Input/Output 방향 설정 |
| `+0x04` | Output Data Register | Output으로 설정된 GPIO Pin의 출력값 |
| `+0x08` | Input Data Register | 외부 GPIO 입력값 확인 |

Control Register의 각 Bit가 `1`이면 해당 Pin을 Output Data로 구동하고, `0`이면 High-Z 상태로 전환해 외부 입력을 읽도록 구성했습니다.

### FND

Base Address: `0x2000_3000`

| Offset | Register | Function |
|---:|---|---|
| `+0x00` | Display Data Register | FND에 표시할 데이터 저장 |
| `+0x04` | Digit/Load Register | 표시 자릿값 또는 Load 제어값 저장 |

## Structure

```text
rtl/
  RV32I CPU, APB Master, Address Decoder
  BRAM, GPO, GPI, GPIO, FND, UART RTL

tb/
  Integrated RV32I/APB SoC Testbench

memory/
  Firmware and Processor Memory Images

constraints/
  Basys 3 XDC
```

## APB Peripheral Simulation

### GPIO Register Verification

APB Master가 GPIO Control, Output Data, Input Data Register에 접근하는 과정을 Simulation으로 확인했습니다.

파형의 `PSEL`, `PENABLE`, `PWRITE`를 통해 SETUP과 ACCESS 구간을 구분할 수 있습니다. `PADDR`에 따라 GPIO Register가 선택되고, Write Transaction에서는 `PWDATA`가 내부 Register에 저장되며 Read Transaction에서는 `PRDATA`로 값이 반환됩니다.

강조된 구간에서는 다음 동작을 확인했습니다.

- GPIO Control Register의 방향 설정값 반영
- Output Data Register의 출력값 변경
- Input Data Register의 외부 입력값 반영
- Output으로 지정되지 않은 Pin의 High-Z 상태
- APB ACCESS 구간에서 `PREADY` 응답 발생

<img width="828" alt="APB GPIO Register Simulation Waveform" src="https://github.com/user-attachments/assets/a7937357-c458-4db6-84e4-15d4eaa29289" />

### FND Register Verification

FND Base Address의 Display Data Register에 `0x04D2`를 기록하고, APB Write Transaction이 FND 내부 Register에 정상적으로 반영되는지 확인했습니다.

`0x04D2`는 10진수 `1234`에 해당하며, `PADDR`, `PWDATA`, `PWRITE`, `PSEL`, `PENABLE`과 FND Register 값을 함께 관찰해 CPU에서 전달한 데이터가 Peripheral에 저장되는 과정을 확인했습니다.

<img width="825" alt="APB FND 0x04D2 Write Simulation Waveform" src="https://github.com/user-attachments/assets/404c5850-f56a-4126-ac7a-76ba1f133443" />

## Firmware-Based Integration Verification

C Firmware에서 GPIO Switch 값을 읽어 LED와 FND에 출력하도록 구성했습니다.

`blink_flag`에 따라 Switch 입력값과 8-bit 반전값을 1초 간격으로 번갈아 출력합니다. 이를 통해 CPU가 GPIO Input Register를 읽고, 연산 결과를 GPIO Output Register와 FND Register에 기록하는 전체 경로를 검증했습니다.

```c
while (1) {
    if (blink_flag == 0) {
        sw_data = sw_read(GPIOA) & 0xFFU;
        disp_data = sw_data;
        blink_flag = 1;
    } else {
        disp_data = (sw_data ^ 0xFFU) & 0xFFU;
        blink_flag = 0;
    }

    fnd_data = sum_led_sw_value(disp_data);
    led_write(GPIOA, disp_data);
    fnd_write(fnd_data);
    delay_ms(1000);
}

void delay_ms(int delay)
{
    volatile int i = 0, j = 0;

    for (i = 0; i < delay; i++) {
        for (j = 0; j < 10000 / 12; j++) {
        }
    }
}
```

### Firmware Execution Waveform

C Firmware를 Machine Code로 변환해 ROM에 적재한 후 다음 데이터 경로를 파형으로 확인했습니다.

```text
GPIO Switch Input
  → APB GPIO Input Register Read
  → RV32I CPU Data Processing
  → APB GPIO/FND Register Write
  → LED 및 FND Output
```

<img width="692" alt="RV32I Firmware GPIO and FND Simulation Waveform" src="https://github.com/user-attachments/assets/d0ba81c3-ccb1-4c25-a6c9-c57579abd000" />

## FPGA Verification

Basys 3의 `SW[7:0]`을 순서대로 변경하면서 GPIO LED와 FND 출력이 입력값에 맞게 변경되는지 확인했습니다.

Switch가 모두 활성화된 경우 GPIO 입력값은 `0xFF`가 되며, FND에는 이에 대응하는 10진수 값 `0255`가 표시됩니다. 중간 Switch 조합에서도 LED 상태와 FND 표시값이 함께 변경되는 것을 확인했습니다.

<img width="480" alt="RV32I APB GPIO and FND FPGA Demonstration" src="https://github.com/user-attachments/assets/814ac9b1-bfc4-4b6a-918e-fe1e9ab52c4b" />

## Original Artifacts

- [Vivado XPR](./vivado/original-project/20260325-rv32i-amba-apb/Rv32i_AMBA_APB.xpr)
- [발표자료](<./docs/presentation/3조_김수빈, 장현동, 문태성, 조승아_RV32I Multi Cycle 설계.pptx>)
