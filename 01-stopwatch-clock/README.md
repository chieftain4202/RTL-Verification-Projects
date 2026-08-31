# Stopwatch & Clock

FSM과 Datapath를 분리해 Stopwatch 동작을 구현하고 Basys 3의 7-segment display에 출력한 기초 RTL 프로젝트입니다.

## Key Features

- Run, Stop, Clear 제어
- Button debounce
- 100 Hz tick 기반 시간 계수
- BCD 변환과 multiplexed 7-segment display 출력
- Control Unit과 Datapath 분리

## Structure

```text
rtl/
  btn_debounce.v
  control_unit.v
  fnd_controller.v
  stopwatch_top.v
constraints/
  Basys-3-Master.xdc
```

`stopwatch_top.v`의 원본 파일명은 `Top_counter.v`이며 내부 module 이름은 변경하지 않았습니다.
Vivado 프로젝트를 새로 만들 때 RTL과 XDC를 source로 추가해 사용합니다.

## Verification Evidence to Add

<img width="1041" height="533" alt="image" src="https://github.com/user-attachments/assets/6332d2cb-dc05-4947-a353-e82d371b6bf3" />



## Original Artifacts

- [Vivado XPR](<./vivado/original-project/20260130-stopwatch/20260130_stopwatch.xpr>)
- [발표자료](<./docs/presentation/장현동.pptx>)
