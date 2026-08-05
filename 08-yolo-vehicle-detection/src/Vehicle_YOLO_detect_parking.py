from pathlib import Path
import time

import cv2
from ultralytics import YOLO


# 실행 위치와 관계없이 현재 파일과 같은 폴더의 TensorRT 엔진을 사용합니다.
ENGINE_PATH = Path(__file__).resolve().parent / "vehicle5_yolo11n_v500.engine"
CAMERA_INDEX = 0
CAMERA_WIDTH = 640
CAMERA_HEIGHT = 480
MODEL_IMAGE_SIZE = 640
CONFIDENCE_THRESHOLD = 0.3
LOW_CONFIDENCE_THRESHOLD = 0.1
IOU_THRESHOLD = 0.45
HOLD_SECONDS = 2
MATCH_IOU_THRESHOLD = 0.3
PARKING_SECONDS = 5.0
TRACK_TTL_SECONDS = 1.0
TRACK_IOU_THRESHOLD = 0.3
STATIONARY_MOVE_RATIO = 0.03
VEHICLE_NAMES = {
    0: "truck",
    1: "trailer",
    2: "bus",
    3: "car",
    4: "motorcycle",
}
WINDOW_NAME = "Vehicle Detection"
PARKING_COLOR = (0, 0, 255)


def box_iou(box_a, box_b):
    ax1, ay1, ax2, ay2 = box_a
    bx1, by1, bx2, by2 = box_b

    inter_x1 = max(ax1, bx1)
    inter_y1 = max(ay1, by1)
    inter_x2 = min(ax2, bx2)
    inter_y2 = min(ay2, by2)
    inter_w = max(0.0, inter_x2 - inter_x1)
    inter_h = max(0.0, inter_y2 - inter_y1)
    inter_area = inter_w * inter_h

    area_a = max(0.0, ax2 - ax1) * max(0.0, ay2 - ay1)
    area_b = max(0.0, bx2 - bx1) * max(0.0, by2 - by1)
    union_area = area_a + area_b - inter_area
    if union_area <= 0:
        return 0.0

    return inter_area / union_area


def filter_boxes_with_confidence_hold(result, recent_boxes, current_time):
    if result.boxes is None or result.boxes.cls is None:
        recent_boxes = [
            recent for recent in recent_boxes
            if current_time - recent["last_high_confidence_time"] <= HOLD_SECONDS
        ]
        return [], recent_boxes

    boxes_data = result.boxes.data
    boxes_xyxy = result.boxes.xyxy.cpu().numpy()
    class_ids = result.boxes.cls.cpu().numpy().astype(int)
    confidences = result.boxes.conf.cpu().numpy()

    keep_indexes = []
    next_recent_boxes = []
    matched_recent_indexes = set()

    for index in sorted(range(len(boxes_data)), key=lambda i: confidences[i], reverse=True):
        class_id = class_ids[index]
        confidence = confidences[index]
        box = boxes_xyxy[index]

        if class_id not in VEHICLE_NAMES:
            continue

        is_high_confidence = confidence >= CONFIDENCE_THRESHOLD
        matched_recent_index = None

        for recent_index, recent in enumerate(recent_boxes):
            if recent_index in matched_recent_indexes:
                continue
            if recent["class_id"] != class_id:
                continue
            if current_time - recent["last_high_confidence_time"] > HOLD_SECONDS:
                continue
            if box_iou(recent["box"], box) < MATCH_IOU_THRESHOLD:
                continue

            matched_recent_index = recent_index
            matched_recent_indexes.add(recent_index)
            break

        if is_high_confidence or matched_recent_index is not None:
            keep_indexes.append(index)

        if is_high_confidence:
            next_recent_boxes.append({
                "box": box,
                "class_id": class_id,
                "last_high_confidence_time": current_time,
            })
        elif matched_recent_index is not None:
            recent = recent_boxes[matched_recent_index]
            next_recent_boxes.append({
                "box": box,
                "class_id": class_id,
                "last_high_confidence_time": recent["last_high_confidence_time"],
            })

    for recent_index, recent in enumerate(recent_boxes):
        if recent_index in matched_recent_indexes:
            continue
        if current_time - recent["last_high_confidence_time"] <= HOLD_SECONDS:
            next_recent_boxes.append(recent)

    result.update(boxes=boxes_data[keep_indexes])
    return keep_indexes, next_recent_boxes


def count_detections_by_class(result):
    counts = {class_id: 0 for class_id in VEHICLE_NAMES}
    if result.boxes is None or result.boxes.cls is None:
        return counts

    for class_id in result.boxes.cls.cpu().numpy().astype(int):
        if class_id in counts:
            counts[class_id] += 1

    return counts


def box_center(box):
    x1, y1, x2, y2 = box
    return (x1 + x2) / 2.0, (y1 + y2) / 2.0


def normalized_move(previous_box, current_box):
    prev_cx, prev_cy = box_center(previous_box)
    cur_cx, cur_cy = box_center(current_box)
    dx = cur_cx - prev_cx
    dy = cur_cy - prev_cy

    x1, y1, x2, y2 = current_box
    width = max(1.0, x2 - x1)
    height = max(1.0, y2 - y1)
    diagonal = (width * width + height * height) ** 0.5

    return (dx * dx + dy * dy) ** 0.5 / diagonal


def update_parking_tracks(result, tracks, current_time, next_track_id):
    if result.boxes is None or result.boxes.cls is None:
        tracks = [
            track for track in tracks
            if current_time - track["last_seen"] <= TRACK_TTL_SECONDS
        ]
        return tracks, next_track_id

    boxes_xyxy = result.boxes.xyxy.cpu().numpy()
    class_ids = result.boxes.cls.cpu().numpy().astype(int)
    matched_track_indexes = set()

    for box, class_id in zip(boxes_xyxy, class_ids):
        if class_id not in VEHICLE_NAMES:
            continue

        best_track_index = None
        best_iou = 0.0

        for track_index, track in enumerate(tracks):
            if track_index in matched_track_indexes:
                continue
            if track["class_id"] != class_id:
                continue

            iou = box_iou(track["box"], box)
            if iou > best_iou:
                best_iou = iou
                best_track_index = track_index

        if best_track_index is None or best_iou < TRACK_IOU_THRESHOLD:
            tracks.append({
                "id": next_track_id,
                "box": box,
                "class_id": class_id,
                "stationary_start_time": current_time,
                "last_seen": current_time,
            })
            matched_track_indexes.add(len(tracks) - 1)
            next_track_id += 1
            continue

        track = tracks[best_track_index]
        movement = normalized_move(track["box"], box)
        if movement >= STATIONARY_MOVE_RATIO:
            track["stationary_start_time"] = current_time

        track["box"] = box
        track["last_seen"] = current_time
        matched_track_indexes.add(best_track_index)

    tracks = [
        track for track in tracks
        if current_time - track["last_seen"] <= TRACK_TTL_SECONDS
    ]
    return tracks, next_track_id


def find_parking_track(box, class_id, tracks, current_time):
    for track in tracks:
        if track["class_id"] != class_id:
            continue
        if current_time - track["last_seen"] > TRACK_TTL_SECONDS:
            continue
        if current_time - track["stationary_start_time"] < PARKING_SECONDS:
            continue
        if box_iou(track["box"], box) >= TRACK_IOU_THRESHOLD:
            return track

    return None


def draw_parking_boxes(frame, result, tracks, current_time):
    if result.boxes is None or result.boxes.cls is None:
        return

    boxes_xyxy = result.boxes.xyxy.cpu().numpy()
    class_ids = result.boxes.cls.cpu().numpy().astype(int)

    for box, class_id in zip(boxes_xyxy, class_ids):
        parking_track = find_parking_track(box, class_id, tracks, current_time)
        if parking_track is None:
            continue

        x1, y1, x2, y2 = box.astype(int)
        cv2.rectangle(frame, (x1, y1), (x2, y2), PARKING_COLOR, 3)
        cv2.putText(
            frame,
            "Warning!",
            (x1, max(0, y1 - 8)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.75,
            PARKING_COLOR,
            2,
            lineType=cv2.LINE_AA,
        )


def main():
    if not ENGINE_PATH.is_file():
        raise FileNotFoundError(f"TensorRT 엔진을 찾을 수 없습니다: {ENGINE_PATH}")

    # 5종 차량 데이터로 학습하고 Jetson에서 생성한 TensorRT 엔진을 로드합니다.
    model = YOLO(str(ENGINE_PATH), task="detect")
    #print("model.names =", model.names)

    cap = cv2.VideoCapture(CAMERA_INDEX)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, CAMERA_WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, CAMERA_HEIGHT)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

    if not cap.isOpened():
        raise RuntimeError(f"카메라를 열 수 없습니다: index={CAMERA_INDEX}")

    cv2.namedWindow(WINDOW_NAME, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(WINDOW_NAME, CAMERA_WIDTH, CAMERA_HEIGHT)

    previous_time = time.perf_counter()
    recent_boxes = []
    parking_tracks = []
    next_track_id = 0

    try:
        while True:
            success, frame = cap.read()
            if not success:
                print("카메라 프레임을 읽을 수 없습니다.")
                break

            results = model.predict(
                source=frame,
                imgsz=MODEL_IMAGE_SIZE,
                conf=LOW_CONFIDENCE_THRESHOLD,
                iou=IOU_THRESHOLD,
                device=0,
                verbose=False,
            )

            result = results[0]

            result.names = VEHICLE_NAMES
            current_time = time.perf_counter()
            _, recent_boxes = filter_boxes_with_confidence_hold(
                result,
                recent_boxes,
                current_time,
            )
            parking_tracks, next_track_id = update_parking_tracks(
                result,
                parking_tracks,
                current_time,
                next_track_id,
            )
            display_frame = result.plot()
            draw_parking_boxes(display_frame, result, parking_tracks, current_time)

            elapsed = current_time - previous_time
            fps = 1.0 / elapsed if elapsed > 0 else 0.0
            previous_time = current_time

            class_counts = count_detections_by_class(result)
            overlay_lines = [
                f"{VEHICLE_NAMES[class_id]}: {count}"
                for class_id, count in class_counts.items()
            ]
            overlay_lines.append(f"FPS: {fps:.1f}")

            for line_index, text in enumerate(overlay_lines):
                cv2.putText(
                    display_frame,
                    text,
                    (10, 30 + line_index * 30),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.65,
                    (0, 255, 0),
                    2,
                    lineType=cv2.LINE_AA,
                )

            cv2.imshow(WINDOW_NAME, display_frame)

            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
    finally:
        cap.release()
        cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
