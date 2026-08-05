# UART/FIFO/Watch SystemVerilog Verification

시간 모듈과 UART/FIFO 데이터 흐름을 self-checking SystemVerilog testbench로 검증한 팀 프로젝트입니다.

## Verification Scope

- Generator, Driver, Monitor, Scoreboard 구조
- Stopwatch Run/Stop/Clear 및 Up/Down random test
- Clock 시간 설정 경계 조건
- FIFO Push/Pop, Full/Empty, simultaneous Read/Write
- UART RX-to-FIFO와 FIFO-to-UART TX 데이터 흐름

## Structure

```text
rtl/  design-under-test dependencies
tb/   SystemVerilog and legacy testbench
```

## Team Contribution

지원서에 사용하기 전 아래 내용을 실제 담당 범위에 맞게 구체화해야 합니다.

- 직접 작성 또는 수정한 class/module
- 담당한 test scenario
- 발견한 bug와 수정 내용
- 최종 pass count와 coverage 결과

## Verification Evidence to Add

- Testbench architecture diagram
- Scoreboard comparison log
- Random test pass count
- Boundary-condition waveform

## Original Artifacts

- [Vivado XPR](<./vivado/original-project/20260227-clock-sv/20260227_Clock_sv.xpr>)
- [발표자료](<./docs/presentation/8-1조_이준형_장현동_UART_FIFO_WATCH_STOPWATCH_발표 (1).pptx>)
