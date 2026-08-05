# UART-Controlled Clock

Clock/Stopwatch RTL에 UART RX/TX와 ASCII command decoder를 연결해 외부 명령으로 기능을 제어한 프로젝트입니다.

## Key Features

- UART TX/RX FSM
- 16x oversampling과 중앙 샘플링
- ASCII command decoder
- Button 입력과 UART 명령의 공통 제어 경로
- Stopwatch/Clock 상태와 FND 출력 연동

## Structure

```text
rtl/          clock, stopwatch, UART, decoder, display RTL
tb/           UART RX and integrated watch testbench
constraints/  Basys 3 constraints
```

## Portability Note

원본 XPR은 `D:/Project_1`의 외부 RTL과 XDC를 참조했습니다. 포트폴리오 사본에서는
원본 저장소 안에서 확인 가능한 대응 파일을 `01-stopwatch-clock`과
`03-uart-fifo-verification`에서 함께 복제했습니다. 공개 전에 Vivado에서 source order와
port compatibility를 다시 확인하는 것이 좋습니다.

## Verification Evidence to Add

- UART bit timing waveform
- ASCII command별 mode transition 표
- FPGA와 serial terminal 동작 화면

## Original Artifacts

- [Vivado XPR](<./vivado/original-project/20260206-uart-stopwatch/20260206 Uart_Stopwatch_project.xpr>)
- [발표자료](<./docs/presentation/Uart_Clock.pptx>)
