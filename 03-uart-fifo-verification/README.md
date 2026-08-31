# UART/FIFO/Watch SystemVerilog Verification

시간 모듈과 UART/FIFO 데이터 흐름을 self-checking SystemVerilog Testbench로 검증한 팀 프로젝트입니다.

Generator, Driver, Monitor, Scoreboard 구조를 적용하여 입력 생성부터 DUT 구동, 출력 수집, 예상값 비교까지 반복적으로 수행할 수 있는 검증 환경을 구성했습니다.

## Verification Scope

팀 프로젝트의 전체 검증 범위는 다음과 같습니다.

- Stopwatch Run/Stop/Clear 및 Up/Down randomized test
- Clock 시간 설정과 경계 조건 검증
- FIFO Push/Pop, Full/Empty 및 동시 Read/Write 검증
- UART RX-to-FIFO 데이터 흐름 검증
- FIFO-to-UART TX 데이터 흐름 검증
- Expected Data와 DUT 출력의 Scoreboard 비교

## Personal Contribution

제가 담당한 범위는 Stopwatch와 Clock 모듈의 SystemVerilog 검증입니다.

- Stopwatch Run/Stop 제어 검증
- Stopwatch Up/Down Count 검증
- Stopwatch 복합 입력 시나리오 검증
- Clock Up Time 설정 검증
- Clock Down Time 설정 검증
- Clock Up/Down 복합 시나리오 검증
- Randomized Input에 대한 DUT 출력 수집 및 예상값 비교
- 실행 로그와 Simulation Waveform을 이용한 결과 확인

## Testbench Architecture

Generator에서 randomized transaction을 생성하고 Driver가 DUT에 입력을 전달하도록 구성했습니다. Monitor는 DUT 출력을 수집하며, Scoreboard에서 예상 결과와 실제 결과를 비교하여 PASS/FAIL을 판정합니다.

<img width="878" alt="SystemVerilog Testbench Architecture" src="https://github.com/user-attachments/assets/ad0a5c11-ec5c-4dc1-94e2-73a7a3a99d8e" />

## Structure

```text
rtl/
  Design-under-test dependencies

tb/
  SystemVerilog self-checking testbench
  Legacy testbench
```

## Stopwatch Verification

Stopwatch는 Run/Stop, Up/Down Count 및 복합 입력의 세 가지 randomized scenario로 구분하여 검증했습니다.

### 1. Run/Stop Randomized Test

Run과 Stop 입력을 반복적으로 변경하면서 Stopwatch의 동작 상태와 시간 계수 여부를 확인했습니다.

<details>
<summary>실행 로그 및 Simulation Waveform</summary>

#### Test Log

<img width="1032" alt="Stopwatch Run Stop Randomized Test Log" src="https://github.com/user-attachments/assets/0fff1025-cb2f-4bdf-b1d5-594fda69c7ba" />

#### Simulation Waveform

<img width="948" alt="Stopwatch Run Stop Simulation Waveform" src="https://github.com/user-attachments/assets/2551ad6c-d1b4-4537-b052-b59927b619e1" />

</details>

### 2. Up/Down Count Randomized Test

Up/Down 제어 입력에 따라 Stopwatch의 계수 방향이 정상적으로 전환되는지 확인했습니다.

<details>
<summary>실행 로그 및 Simulation Waveform</summary>

#### Test Log

<img width="1016" alt="Stopwatch Up Down Randomized Test Log" src="https://github.com/user-attachments/assets/0ccf588c-4e24-4c67-aaca-d8d6e55799a8" />

#### Simulation Waveform

<img width="990" alt="Stopwatch Up Down Simulation Waveform" src="https://github.com/user-attachments/assets/c9a50bef-761f-4232-88dc-5dd34884156e" />

</details>

### 3. Combined Randomized Test

Run/Stop과 Up/Down 입력을 함께 변경하는 복합 시나리오에서 Stopwatch의 상태 전이와 계수 결과를 확인했습니다.

<details>
<summary>실행 로그 및 Simulation Waveform</summary>

#### Test Log

<img width="914" alt="Stopwatch Combined Randomized Test Log" src="https://github.com/user-attachments/assets/2ecb4064-4554-4031-befc-1b46d22646b7" />

#### Simulation Waveform

<img width="971" alt="Stopwatch Combined Simulation Waveform" src="https://github.com/user-attachments/assets/1ad258c9-103c-433e-aa43-896cd424ac3c" />

</details>

## Clock Verification

Clock은 시간 증가, 시간 감소 및 두 동작을 결합한 randomized scenario로 구분하여 검증했습니다.

### 1. Up Time Randomized Test

시간 증가 입력에 따라 설정값이 정상적으로 변경되고, 시간 범위에 맞게 처리되는지 확인했습니다.

<details>
<summary>실행 로그 및 Simulation Waveform</summary>

#### Test Log

<img width="840" alt="Clock Up Time Randomized Test Log" src="https://github.com/user-attachments/assets/12415712-6daa-454e-b8d6-77e9c37c0085" />

#### Simulation Waveform

<img width="1428" alt="Clock Up Time Simulation Waveform" src="https://github.com/user-attachments/assets/5751f8d3-760e-4e1d-af50-fcbba57b459d" />

</details>

### 2. Down Time Randomized Test

시간 감소 입력에 따라 설정값이 정상적으로 변경되고, 시간 범위의 하한 조건이 처리되는지 확인했습니다.

<details>
<summary>실행 로그 및 Simulation Waveform</summary>

#### Test Log

<img width="911" alt="Clock Down Time Randomized Test Log" src="https://github.com/user-attachments/assets/9b291c28-eeb4-491b-ba37-283c8d71aa66" />

#### Simulation Waveform

<img width="1398" alt="Clock Down Time Simulation Waveform" src="https://github.com/user-attachments/assets/a73cae6a-f89a-4098-920d-3a5f025c03b5" />

</details>

### 3. Up/Down Combined Randomized Test

시간 증가와 감소 입력을 함께 발생시키면서 Clock의 설정값과 경계 조건 처리 결과를 확인했습니다.

<details>
<summary>실행 로그 및 Simulation Waveform</summary>

#### Test Log

<img width="909" alt="Clock Up Down Combined Test Log" src="https://github.com/user-attachments/assets/65ee11b0-f9a6-4a2d-bd44-e19e137b8f80" />

#### Simulation Waveform

<img width="1374" alt="Clock Up Down Combined Simulation Waveform" src="https://github.com/user-attachments/assets/0bed7ab3-d78a-4ce6-bb10-1963663b4576" />

</details>

## Original Artifacts

- [Vivado XPR](./vivado/original-project/20260227-clock-sv/20260227_Clock_sv.xpr)
- [발표자료](<./docs/presentation/8-1조_이준형_장현동_UART_FIFO_WATCH_STOPWATCH_발표 (1).pptx>)
