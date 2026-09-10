# UART-Controlled Clock

Clock/Stopwatch RTL에 UART RX/TX와 ASCII Command Decoder를 연결하여, 키보드에서 전송한 UART 명령으로 기능을 제어한 FPGA 프로젝트입니다.

## Key Features

- UART TX/RX FSM 구현
- 16x oversampling 및 중앙 지점 sampling
- ASCII Command Decoder 구현
- Button 입력과 UART 명령의 공통 제어 경로 구성
- UART 명령을 통한 Clock 시간 설정
- Stopwatch Run/Stop/Clear 제어
- Clock/Stopwatch 상태와 7-segment display 출력 연동

## System Block Diagram

<img width="1193" alt="UART-Controlled Clock 전체 블록도" src="https://github.com/user-attachments/assets/b0717b3e-25de-46df-b065-6ba423e5cd59" />

## Structure

```text
rtl/
  Clock, Stopwatch, UART, Command Decoder, Display RTL

tb/
  UART RX 및 통합 Watch Testbench

constraints/
  Basys 3 XDC

docs/
  images/
    uart_clock_demo.gif
  presentation/
    Uart_Clock.pptx
```


### UART TX Waveform

UART TX가 Start Bit, 8-bit Data, Stop Bit 순서로 데이터를 전송하는지 Simulation 파형을 통해 확인했습니다.

<img width="784" alt="UART TX Simulation Waveform" src="https://github.com/user-attachments/assets/e388e86a-cd5e-465c-99aa-a7d0456c8d3e" />

### UART RX Waveform

16x oversampling과 중앙 지점 sampling을 통해 UART RX 데이터를 수신하고, 수신된 ASCII Data가 내부 제어 신호로 전달되는 과정을 확인했습니다.

<img width="794" alt="UART RX Simulation Waveform" src="https://github.com/user-attachments/assets/de07bac8-652a-4db6-8df2-58e09defd5ce" />

## FPGA Verification

Serial Terminal에서 전송한 ASCII 명령에 따라 Clock의 시간 설정값이 변경되고, Stopwatch의 Run/Stop 및 Clear 동작이 수행되는 것을 Basys 3 보드에서 확인했습니다.

<img width="360" height="640" alt="uart_clock_demo" src="https://github.com/user-attachments/assets/b486cd25-5ef4-4820-85b6-cba050c242fd" />

## Portability Note

원본 XPR은 `D:/Project_1`에 위치한 외부 RTL 및 XDC 파일을 참조하므로 다른 환경에서 그대로 열리지 않을 수 있습니다.

포트폴리오 저장소에는 원본 저장소에서 확인 가능한 대응 파일을 함께 정리했습니다. 공통 Clock/Stopwatch RTL은 `01-stopwatch-clock`, 검증 관련 파일은 `03-uart-fifo-verification`에서도 확인할 수 있습니다.

다른 PC에서 재구성할 때는 새 Vivado 프로젝트를 생성한 후 `rtl/`과 `constraints/`의 파일을 추가하고, Top Module과 Source Order를 확인하는 방식을 권장합니다.

## Original Artifacts

- [Vivado XPR](<./vivado/original-project/20260206-uart-stopwatch/20260206 Uart_Stopwatch_project.xpr>)
- [발표자료](./docs/presentation/Uart_Clock.pptx)!
