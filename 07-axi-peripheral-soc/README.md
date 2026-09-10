# AXI4-Lite SPI/I2C Peripheral SoC

MicroBlaze에서 AXI4-Lite Custom Peripheral을 제어하고, FPGA에서 SPI/I2C 통신을 확인한 HW/SW 통합 프로젝트입니다.

Vivado Block Design과 Custom RTL로 하드웨어 시스템을 구성했습니다. FPGA 보드의 FND에는 SPI 수신 데이터와 I2C 송신 데이터를 표시하고, Vitis의 UART 출력은 GPIO 입력과 I2C 내부 상태를 확인하는 디버그 로그로 사용했습니다.

AXI-SPI는 AXI Register의 8-bit 데이터를 SPI Mode 0으로 전송하고 MISO에서 수신한 데이터를 FND에 표시합니다. AXI-I2C는 GPIO 입력을 제어값과 송신 데이터로 사용하며, Write/Read 데이터 경로는 별도의 UVM 환경에서 검증했습니다.

## Project Highlights

- MicroBlaze 기반 AXI4-Lite SoC 구성
- AXI-SPI 및 AXI-I2C Master Custom Peripheral 구현
- Memory-Mapped Register 기반 주변장치 제어
- AXI-SPI Register 기반 8-bit 송수신 및 FND 결과 표시
- GPIO 입력 기반 I2C Write Transaction 수행
- I2C 상태 Register의 FSM·Busy·Done·ACK 확인
- FND를 통한 SPI 수신 데이터 및 I2C 송신 데이터 표시
- Vitis UART를 통한 GPIO 입력 및 I2C 상태 디버깅
- FPGA Master/Slave 통신 확인
- AXI-I2C Write/Read 경로 UVM 검증
- Scoreboard 자동 비교 및 Functional Coverage 수집

## System Architecture

SPI와 I2C는 각각 별도의 Block Design으로 구현했습니다. 현재 `main.c`에서 실행되는 Software Flow는 MicroBlaze, GPIO 2개와 AXI-I2C Master를 사용한 `CommTest` 구성입니다.

<table>
  <tr>
    <th>MicroBlaze + AXI-SPI Master</th>
    <th>MicroBlaze + AXI-I2C Master</th>
  </tr>
  <tr>
    <td align="center">
      <img width="480" alt="MicroBlaze AXI SPI Master Block Design" src="https://github.com/user-attachments/assets/0e40b062-78a2-40f9-ac7c-58a40b55c53f">
    </td>
    <td align="center">
      <img width="500" alt="MicroBlaze AXI I2C Master Block Design" src="https://github.com/user-attachments/assets/1d4cee2d-77ba-4a2f-940b-f58d5e7e987c">
    </td>
  </tr>
  <tr>
    <td>
      AXI-SPI Driver와 Custom IP를 이용한 SPI Master 구현 구성입니다.
    </td>
    <td>
      현재 Vitis 실행 코드와 연결된 AXI-I2C Master 및 GPIO 구성입니다.
    </td>
  </tr>
</table>

- **MicroBlaze**: Vitis C Application 실행 및 Memory-Mapped Register 접근
- **GPIO8_0**: I2C로 전송할 8-bit Switch Data 입력
- **GPIO8_1**: 상위 Bit를 이용한 I2C Transaction 시작 제어
- **AXI-SPI Master**: AXI Register의 8-bit 데이터를 MOSI로 전송하고 MISO 수신 데이터 복원
- **AXI-I2C Master**: 제어값을 I2C START·Address·Write Data·STOP 신호로 변환
- **FND**: SPI Master 수신 데이터 또는 I2C 송신 데이터를 FPGA 보드에 표시
- **UART**: Vitis에서 GPIO 입력값과 I2C 내부 상태를 확인하기 위한 디버그 로그 출력

## AXI-SPI Hardware Data Flow

AXI-SPI Custom IP는 AXI4-Lite Slave Register와 SPI Master RTL, FND Controller를 하나의 상위 Wrapper로 구성합니다. MicroBlaze가 `+0x00` Register에 기록한 하위 8-bit 값은 SPI 송신 데이터가 되고, MISO에서 복원한 수신 데이터는 FND에 표시됩니다.

```mermaid
flowchart LR
    CPU["MicroBlaze"] -->|"AXI4-Lite Write"| REG0["SPI +0x00<br/>slv_reg0[7:0]"]
    REG0 --> DATA["8-bit TX Data"]
    DATA --> FSM["SPI Master FSM<br/>IDLE → START → DATA → STOP"]
    FSM -->|"MOSI / SCLK / CS_n"| SLAVE["External SPI Slave"]
    SLAVE -->|"MISO"| RX["8-bit RX Data"]
    RX --> FND["FND Controller<br/>수신값 표시"]
```

SPI Master는 `CPOL=0`, `CPHA=0`의 Mode 0으로 동작하며 `clk_div=4`를 적용합니다. `CS_n`을 Low로 내린 뒤 송신 Shift Register의 MSB부터 MOSI로 출력하고, SCLK Edge에서 MISO를 8-bit 수신 Shift Register에 저장합니다. 전송이 끝나면 `CS_n`을 High로 복귀하고 수신값을 `master_rx_data`에 반영합니다.

### SPI RTL Files

| 파일 | 역할 |
|---|---|
| [SPI_Master_v1_0.v](./rtl/custom-ip/spi-master/SPI_Master_v1_0.v) | AXI4-Lite Slave와 SPI Master/FND RTL을 연결하는 Custom IP 상위 Wrapper |
| [SPI_Master_v1_0_S00_AXI.v](./rtl/custom-ip/spi-master/SPI_Master_v1_0_S00_AXI.v) | AXI4-Lite Write/Read Channel과 4개의 32-bit Slave Register 구현 |
| [spi_master.sv](./rtl/custom-ip/spi-master/spi_master.sv) | SPI Mode 0 송수신 FSM, Clock Divider, Shift Register 및 FND 표시 구현 |

### AXI-SPI Software Control Flow

SPI Driver는 Base Address를 저장한 뒤 `Xil_Out32()`와 `Xil_In32()`로 AXI-SPI Register에 접근하도록 구성했습니다. [SPIMaster.c](./sw/Driver/SPIMaster/SPIMaster.c)와 [SPIMaster.h](./sw/Driver/SPIMaster/SPIMaster.h)에서 구현을 확인할 수 있습니다.

```mermaid
flowchart TD
    INIT["SPIMaster_Init()<br/>Base Address 저장"] --> CALL["SPIMaster_SendByte()<br/>8-bit TX Data 전달"]
    CALL --> TX["SPIMaster_WriteTxData()"]
    TX --> REG0["Xil_Out32()<br/>Base + 0x00에 TX Data 기록"]
    REG0 --> START["SPIMaster_Start()"]
    START --> REG1["Xil_Out32()<br/>Base + 0x04에 1 기록"]

    READ["SPIMaster_ReadReg()"] --> AXI_R["Xil_In32()<br/>Base + Register Offset"]
    AXI_R --> VALUE["32-bit Register 값 반환"]
```

| 순서 | 함수 | Software 동작 |
|---:|---|---|
| 1 | `SPIMaster_Init()` | AXI-SPI Base Address를 Driver Handle에 저장 |
| 2 | `SPIMaster_SendByte()` | 송신 데이터 기록과 Start 함수 순차 호출 |
| 3 | `SPIMaster_WriteTxData()` | 8-bit TX Data를 `Base + 0x00`에 기록 |
| 4 | `SPIMaster_Start()` | 제어값 `1`을 `Base + 0x04`에 기록 |
| 5 | `SPIMaster_ReadReg()` | 지정한 Offset의 32-bit Register 값 반환 |

이 흐름은 공개된 SPI Driver의 Software 동작을 나타냅니다. 현재 공개된 `main.c`는 AXI-I2C `CommTest`를 실행하므로 SPI Driver를 직접 호출하지 않으며, SPI 실행 Application은 별도로 구성해야 합니다.

### AXI-SPI Register Map

| Offset | 접근 | RTL에서 연결된 기능 |
|---:|---|---|
| `+0x00` | Read/Write | `slv_reg0[7:0]`을 SPI TX Data로 전달 |
| `+0x04` | Read/Write | 범용 `slv_reg1`, SPI 제어 로직에는 연결되지 않음 |
| `+0x08` | Read/Write | 범용 `slv_reg2`, SPI 제어 로직에는 연결되지 않음 |
| `+0x0C` | Read/Write | 범용 `slv_reg3`, SPI 제어 로직에는 연결되지 않음 |

`SPI_Master_v1_0_S00_AXI`는 AXI Write Address와 Data를 수신해 선택된 Slave Register에 저장하고, Read 요청 시 같은 Register 값을 반환합니다. 실제 SPI 데이터 경로에는 `slv_reg0[7:0]`만 연결되어 있습니다.

### SPI Transfer Sequence

| 순서 | 모듈 | 동작 |
|---:|---|---|
| 1 | MicroBlaze / AXI4-Lite | `+0x00` Register에 8-bit 송신 데이터 기록 |
| 2 | `SPI_Master_v1_0_S00_AXI` | `slv_reg0[7:0]`을 `sw` 신호로 출력 |
| 3 | `spi_master` | 송신 데이터를 Shift Register에 저장하고 `CS_n` 활성화 |
| 4 | `SPI_master` FSM | SCLK에 맞춰 MOSI 송신과 MISO Sampling을 8회 수행 |
| 5 | `SPI_master` FSM | 수신 데이터를 `master_rx_data`에 저장하고 `CS_n` 비활성화 |
| 6 | `fnd_controller` | 수신한 8-bit 값을 10진수 Digit으로 분리해 FND에 표시 |

현재 공개된 SPI RTL에서는 `slv_reg1`을 Start 신호로 사용하지 않고, SPI FSM의 IDLE/Busy 상태에 따라 전송을 진행합니다. 따라서 `+0x00` TX Data Write는 RTL과 대응하지만, `+0x04`에 기록하는 `SPIMaster_Start()`는 현재 공개된 RTL 제어 경로에는 연결되어 있지 않습니다.

### SPI FPGA Integration Result

AXI-SPI 구성에서 MicroBlaze가 `slv_reg0[7:0]`에 기록한 데이터를 MOSI, SCLK, CS_n을 통해 외부 SPI Slave 보드로 전송했습니다. Slave가 MISO로 반환한 8-bit 데이터를 Master가 복원하고, 해당 수신값을 FPGA 보드의 FND에 표시하여 AXI Register 접근부터 SPI 물리 신호와 출력 장치까지 이어지는 동작을 확인했습니다.

## Current I2C Hardware/Software Control Flow

### I2C RTL Files

| 파일 | 역할 |
|---|---|
| [i2c_masterr_v1_0.v](./rtl/custom-ip/i2c-master/i2c_masterr_v1_0.v) | AXI4-Lite Slave와 I2C Master/FND RTL을 연결하고 SCL·SDA를 외부로 출력하는 Custom IP 상위 Wrapper |
| [i2c_masterr_v1_0_S00_AXI.v](./rtl/custom-ip/i2c-master/i2c_masterr_v1_0_S00_AXI.v) | AXI4-Lite Write/Read Channel, 제어·송신 Register와 상태 Register Read 경로 구현 |
| [master.sv](./rtl/custom-ip/i2c-master/master.sv) | START·Address·Write Data·STOP 제어, I2C 송수신 FSM, 상태값 생성 및 FND 표시 구현 |

`i2c_masterr_v1_0_S00_AXI`는 `slv_reg0[15:0]`을 I2C 제어값과 송신 데이터로 전달하고, `+0x04` Read 요청에는 `master_top`에서 생성한 FSM·Busy·Done·ACK 상태값을 반환합니다.

```mermaid
flowchart TB
    MAIN["main.c"] --> INIT["CommTest_Init()"]
    INIT --> GPIO_INIT["GPIO8_0 / GPIO8_1<br/>Input Mode 설정"]
    INIT --> I2C_INIT["I2CMaster_Init()<br/>Base Address 설정"]

    MAIN --> LOOP["CommTest_Execute()<br/>100ms Polling"]
    LOOP --> GPIO0["Xil_In32()<br/>GPIO8_0 IDR 읽기"]
    LOOP --> GPIO1["Xil_In32()<br/>GPIO8_1 IDR 읽기"]

    GPIO0 --> WORD["swWord 생성<br/>TX Data = GPIO8_0[7:0]"]
    GPIO1 --> WORD
    WORD --> DRIVER["I2CMaster_WriteSwWord()"]
    DRIVER --> AXI_W["Xil_Out32()<br/>AXI-I2C +0x00 Write"]
    AXI_W --> I2C_IP["AXI-I2C Master IP"]
    I2C_IP --> BUS["I2C Write Transaction<br/>START → Address → Data → STOP"]

    LOOP --> STATUS["I2CMaster_ReadStatus()"]
    STATUS --> AXI_R["Xil_In32()<br/>AXI-I2C +0x04 Read"]
    AXI_R --> UART["xil_printf()<br/>입력값 및 상태 출력"]
```

## Current Software Call Sequence

| 순서 | 함수 및 모듈 | 동작 |
|---:|---|---|
| 1 | `main()` | `CommTest_Init()` 실행 후 `CommTest_Execute()` 반복 호출 |
| 2 | `CommTest_Init()` | GPIO 2개를 입력으로 설정하고 I2C Base Address 저장 |
| 3 | `CommTest_Execute()` | 100ms 주기로 GPIO 입력과 I2C 상태 확인 |
| 4 | `CommTest_ReadGpioInput()` | `Xil_In32()`로 GPIO Input Data Register 접근 |
| 5 | `I2CMaster_WriteSwWord()` | 제어값과 송신 데이터를 AXI-I2C `+0x00`에 기록 |
| 6 | AXI-I2C Master IP | START, Slave Address, Write Data, STOP 순서 수행 |
| 7 | `I2CMaster_ReadStatus()` | AXI-I2C `+0x04`에서 통신 상태 읽기 |
| 8 | `xil_printf()` | 입력 또는 상태가 변경된 경우 UART 로그 출력 |

## I2C CommTest Data Flow

GPIO 입력 2개를 이용해 I2C 송신 데이터와 시작 신호를 구성합니다.

```mermaid
flowchart LR
    SW0["GPIO8_0<br/>Switch Data"] --> TX["TX Data<br/>swWord[7:0]"]
    SW1["GPIO8_1[7]<br/>Start Control"] --> START["Start<br/>swWord[15]"]

    TX --> COMBINE["16-bit swWord"]
    START --> COMBINE

    COMBINE --> REG0["AXI-I2C +0x00"]
    REG0 --> FSM["I2C Master FSM"]
    FSM --> ADDRESS["Write Address<br/>7'h55 + W"]
    ADDRESS --> DATA["8-bit Write Data"]
    DATA --> STOP["STOP"]
```

`GPIO8_0`의 8-bit 입력은 I2C Write Data로 사용합니다. `GPIO8_1`의 상위 Bit는 `swWord[15]`에 배치되어 Transaction 시작을 제어합니다.

Application은 생성한 `swWord`를 I2C Driver에 전달하고, Driver는 `Xil_Out32()`를 사용해 AXI-I2C 제어 Register에 기록합니다. 이후 상태 Register를 읽어 FSM State, Busy, Done, ACK와 내부 송신 데이터를 확인합니다.

## Active Address Map

| Peripheral | Base Address | 현재 용도 |
|---|---:|---|
| AXI-I2C Master | `0x44A0_0000` | I2C 제어값 기록 및 상태 확인 |
| GPIO8_0 | `0x44A1_0000` | 8-bit I2C 송신 데이터 입력 |
| GPIO8_1 | `0x44A2_0000` | I2C 시작 신호 입력 |

## Active Register Map

### AXI-I2C Master

| Offset | 접근 | 기능 |
|---:|---|---|
| `+0x00` | Write | `swWord[15:0]` 제어값 및 송신 데이터 |
| `+0x04` | Read | I2C FSM과 통신 상태 |
| `+0x08` | Read/Write | Reserved Register |
| `+0x0C` | Read/Write | Reserved Register |

### I2C Status Register (`+0x04`)

| Bit | 필드 | 기능 |
|---:|---|---|
| `[3:0]` | State | I2C Master FSM 현재 상태 |
| `[4]` | Busy | I2C Transaction 진행 상태 |
| `[5]` | Done | 통신 단계 완료 감지 |
| `[6]` | ACK | Slave ACK/NACK 상태 |
| `[7]` | Start Level | 동기화된 Start 입력 상태 |
| `[8]` | Start Seen | Start 입력 감지 여부 |
| `[16:9]` | Switch TX Data | GPIO에서 전달된 송신 데이터 |
| `[24:17]` | Master TX Data | I2C Master가 현재 전송하는 데이터 |

### GPIO8

| Offset | 접근 | 기능 |
|---:|---|---|
| `+0x00` | Write | GPIO 방향 제어 Register |
| `+0x04` | Read | GPIO Input Data Register |
| `+0x08` | Write | GPIO Output Data Register |

현재 `CommTest_Init()`은 GPIO Control Register에 `0x00`을 기록해 GPIO8_0과 GPIO8_1을 입력으로 설정합니다.

## Additional Software Sources

저장소에는 현재 `CommTest` 실행 경로 외에도 SPI Master, FND, LED, Button, Timer Driver와 HAL 코드가 포함되어 있습니다.

현재 공개된 `main.c`는 다음 파일을 실행합니다.

```text
main.c
  └─ ap/CommTest/CommTest.c
       └─ Driver/I2CMaster/I2CMaster.c
```

다음 소스는 별도로 보존된 기능별 구현 자료이며 현재 `main.c`의 실행 경로에서는 호출되지 않습니다.

- `Driver/SPIMaster/`
- `Driver/FND/`
- `Driver/LED/`
- `Driver/Button/`
- `HAL/GPIO/`
- `HAL/TMR/`
- `ap/Clock/`
- `ap/TimeClock/`
- `ap/UpCounter/`
- `ap/ap_main.c`

## Project Structure

```text
rtl/
├─ custom-ip/
│  ├─ spi-master/      AXI-SPI Wrapper, AXI4-Lite Register 및 SPI/FND RTL
│  ├─ i2c-master/      AXI-I2C Wrapper, AXI4-Lite Register 및 I2C/FND RTL
│  └─ gpio8/           AXI-GPIO8 Custom IP
└─ uvm-design/         UVM 검증용 AXI-I2C RTL

tb/
└─ uvm/                Agent, Driver, Monitor,
                       Scoreboard 및 Coverage

sw/
├─ ap/
│  ├─ CommTest/        현재 main.c에서 실행하는 Application
│  ├─ Clock/           별도 Application Source
│  ├─ TimeClock/       별도 Application Source
│  └─ UpCounter/       별도 Application Source
├─ Driver/             I2C, SPI, FND, LED, Button Driver
├─ HAL/                GPIO 및 Timer HAL
└─ main.c              현재 Software Entry Point

constraints/           Basys 3 XDC
scripts/uvm/           VCS/Verdi Makefile 및 File List
vivado/block-design/   Block Design과 XCI Metadata
vivado/ip-package/     Custom IP Packaging Metadata
```

## FPGA Prototype

SPI와 I2C는 각각의 FPGA 구성에서 Master와 Slave 사이의 데이터 전송을 확인했습니다. 현재 공개된 `main.c`의 실행 경로는 AXI-I2C와 GPIO를 사용하는 `CommTest` 구성입니다.

<table>
  <tr>
    <th>AXI-SPI FPGA 동작</th>
    <th>AXI-I2C FPGA 동작</th>
  </tr>
  <tr>
    <td align="center">
      <img width="280" alt="AXI SPI FPGA Demo" src="https://github.com/user-attachments/assets/bacf0a67-eb09-4e82-86d4-23f0efb0493f">
    </td>
    <td align="center">
      <img width="480" alt="AXI I2C FPGA Demo" src="https://github.com/user-attachments/assets/ff9d2524-5f26-45a5-8d8a-2baee028adfa">
    </td>
  </tr>
  <tr>
    <td>
      별도의 AXI-SPI 구성에서 MicroBlaze가 SPI Master Register를 제어하고, FPGA 보드 간 송수신 동작을 확인했습니다.
    </td>
    <td>
      현재 CommTest 구성에서 GPIO 입력값을 AXI-I2C Register에 기록하고, I2C Write Transaction과 상태 변화를 확인했습니다.
    </td>
  </tr>
</table>

## AXI-I2C UVM Verification

현재 공개된 UVM Testbench는 보드에서 실행되는 `CommTest`와 분리된 검증 환경이며, `rtl/uvm-design`의 AXI-I2C Custom IP를 대상으로 Write/Read 데이터 경로를 검증합니다.

이 AXI 프로젝트의 UVM 코드·로그·Coverage 자료는 **AXI-I2C에 대한 결과**입니다. `rtl/custom-ip/spi-master/`의 AXI-SPI RTL은 해당 UVM 검증 대상에 포함되지 않습니다.

### Verification Scope

- AXI4-Lite Write/Read Transaction
- AXI Write Data와 I2C Slave 수신 데이터 비교
- I2C Slave 송신 데이터와 Master 수신 데이터 비교
- Scoreboard 기반 자동 PASS/FAIL 판정
- Expected/Observed Data Functional Coverage
- Write Path 및 Read Path Cross Coverage

### UVM Data Flow

```mermaid
flowchart LR
    SEQ["Sequence<br/>Random Data Generation"] --> DRV["Driver"]
    DRV -->|AXI Write/Read| DUT["AXI-I2C DUT"]
    DRV -->|Slave TX Data| SLAVE["I2C Slave Model"]

    DUT <--> SLAVE
    DUT --> MON["Monitor"]
    SLAVE --> MON

    SEQ -->|Expected Data| SB["Scoreboard"]
    MON -->|Observed Data| SB
    SB --> RESULT["PASS / FAIL"]
    MON --> COV["Functional Coverage"]
```

| 검증 경로 | Expected Data | Observed Data | 비교 목적 |
|---|---|---|---|
| Write Path | AXI에 기록한 Write Data | I2C Slave가 수신한 Data | Master → Slave 전송 확인 |
| Read Path | Slave에 설정한 TX Data | I2C Master가 수신한 Data | Slave → Master 전송 확인 |

### UVM Verification Blocks

<table>
  <tr>
    <th>전체 검증 흐름</th>
    <th>Write Path</th>
    <th>Read Path</th>
  </tr>
  <tr>
    <td align="center">
      <img width="300" alt="AXI I2C UVM Verification Flow" src="https://github.com/user-attachments/assets/5198c957-3ce9-4298-932e-28e828ac1d74">
    </td>
    <td align="center">
      <img width="305" alt="AXI I2C UVM Write Flow" src="https://github.com/user-attachments/assets/1b427d06-31b6-4b5b-9617-c961e883c03e">
    </td>
    <td align="center">
      <img width="300" alt="AXI I2C UVM Read Flow" src="https://github.com/user-attachments/assets/cbb71db6-23d2-4313-ba45-51ef9dfb0fd2">
    </td>
  </tr>
</table>

Sequence에서 Write Data와 Read Data를 생성하고, Driver가 AXI Register와 I2C Slave Model에 전달합니다. Monitor는 Slave 수신 데이터와 Master 수신 데이터를 수집하며, Scoreboard는 각 경로의 Expected Data와 Observed Data를 비교합니다.

### Simulation Result

<details>
<summary><strong>UVM Transaction 중간 로그 보기</strong></summary>
<br>

<img width="1000" alt="AXI I2C UVM Transaction Log" src="https://github.com/user-attachments/assets/890971c1-23d1-4baa-a568-d68a810c430d">

Sequence에서 생성한 데이터와 Monitor가 관측한 데이터가 Scoreboard로 전달되는 과정을 확인할 수 있습니다.

</details>

<details>
<summary><strong>UVM 최종 결과 보기</strong></summary>
<br>

<img width="1000" alt="AXI I2C UVM Final Result" src="https://github.com/user-attachments/assets/83c50d1a-5cb4-483e-97f9-3f77e04abb26">

Simulation 종료 시 Write/Read 경로의 비교 결과와 PASS/ERROR Count를 확인합니다.

</details>

## Functional Coverage

다음 항목을 대상으로 Functional Coverage를 수집했습니다.

- Write Expected Data
- Read Expected Data
- Slave Received Data
- Master Received Data
- Write Expected/Observed Cross
- Read Expected/Observed Cross

<img width="615" alt="AXI I2C Verdi Coverage Result" src="https://github.com/user-attachments/assets/168a4ff2-d5e7-476b-9bf2-5a16daf21f23">

### Data Range Coverage

`0x00`부터 `0xFF`까지 다양한 8-bit 데이터를 적용하여 특정 값에 편중되지 않도록 확인했습니다.

<table>
  <tr>
    <td align="center">
      <img width="380" alt="AXI I2C Data Coverage 00 to FF Part 1" src="https://github.com/user-attachments/assets/dba383e9-bcf0-4bd7-a18f-470585541224">
    </td>
    <td align="center">
      <img width="380" alt="AXI I2C Data Coverage 00 to FF Part 2" src="https://github.com/user-attachments/assets/ae148481-7b58-44f9-b510-3a19dffad74b">
    </td>
  </tr>
</table>

## Running the UVM Testbench

Synopsys VCS와 UVM 1.2를 사용할 수 있는 Linux 환경에서 실행합니다.

```bash
cd scripts/uvm
make sim
```

Verdi와 Coverage 결과는 다음 명령으로 확인합니다.

```bash
make verdi
make vc
```

다른 Random Seed를 적용하려면 다음과 같이 실행합니다.

```bash
make SEED=<number> sim
```

## Reconstruction Note

대용량 BSP와 Vivado Generated Output은 저장소에서 제외했습니다.

Block Design과 XCI Metadata는 시스템 구조 확인을 위해 포함했지만, 다른 PC에서 프로젝트를 재구성할 때는 다음 항목을 확인해야 합니다.

- 원본 프로젝트와 호환되는 Vivado/Vitis 버전
- Custom IP Repository 경로
- Block Design의 IP 상태
- Source 및 Constraint 파일 경로
- BSP 및 Bitstream 재생성

## Original Artifacts

- [Primary Vivado XPR](<./vivado/original-project/20260502-microblaze-i2c-spi/20260502_MicroBlaze_I2C_SPI_Master.xpr>)
- [발표자료](<./docs/presentation/260508_SoC_AXI_Peripheral_장현동.pptx>)
- 같은 프로젝트 폴더의 `tmp_edit_project.xpr`는 Vivado가 생성한 임시 편집 프로젝트입니다.
