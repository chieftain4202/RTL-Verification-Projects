# RV32I Multi-Cycle SoC with AMBA APB

Multi-Cycle RV32I CPU와 APB Master, BRAM, GPIO, FND, UART Peripheral을 통합한 팀 프로젝트입니다.

C Firmware를 Machine Code로 변환해 Instruction Memory에 적재하고, CPU가 Memory-Mapped APB Register를 통해 GPIO와 FND를 제어하는 FPGA 기반 SoC를 구현했습니다.

## Architecture

명령어 실행을 여러 Clock Cycle에 걸쳐 처리하도록 CPU를 구성했습니다.

```text
FETCH
  → DECODE
  → EXECUTE
  → MEMORY
  → WRITE BACK
```

CPU의 Load/Store 요청은 APB Master로 전달되며, APB Transaction은 다음 상태에 따라 진행됩니다.

```text
IDLE
  → SETUP
  → ACCESS
  → PREADY 확인
  → IDLE
```

### Key Features

- Fetch, Decode, Execute, Memory, Write Back 기반 Multi-Cycle CPU
- APB IDLE, SETUP, ACCESS State Machine
- `PREADY` 응답을 고려한 APB Transaction
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
