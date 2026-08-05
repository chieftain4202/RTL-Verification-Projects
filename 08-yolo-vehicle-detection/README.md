# YOLO Vehicle Detection

YOLO와 TensorRT를 이용해 차량을 탐지하고, 검출 안정화·구역 집계·정차 판정 기능을 구현한 Edge AI 팀 프로젝트입니다.

## Features

- Truck, Trailer, Bus, Car, Motorcycle detection
- High/Low confidence and IoU-based detection hold filter
- Cross-class duplicate bounding-box removal
- Region-of-interest vehicle counting
- Tracking-based stopped-vehicle detection
- Event screenshot capture

## Structure

```text
src/              Python inference and filtering variants
requirements.txt  Python dependencies
```

## Setup

```bash
python -m venv .venv
pip install -r requirements.txt
```

TensorRT installation depends on the NVIDIA GPU, CUDA, cuDNN, and TensorRT versions of the target system.
The original ONNX and TensorRT engine binaries were intentionally excluded from this Git-friendly copy.
Place a compatible model file in a local model directory and update the path used by the selected script.

## Evidence to Add

- Input/output example image
- FPS and target hardware
- Detection metrics and confidence threshold
- Team role and personal contribution

## Original Artifact

- [결과보고서 발표자료](<./docs/presentation/KCCI_OnDevice_결과보고서(1팀) (1).pptx>)
