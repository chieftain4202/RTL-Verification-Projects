from pathlib import Path
import time

import cv2
import numpy as np
from ultralytics import YOLO


# 실행 위치와 관계없이 현재 파일과 같은 폴더의 TensorRT 엔진을 사용합니다.
ENGINE_PATH = Path(__file__).resolve().parent / "vehicle5_yolo11n_v500_e250.engine"
CAMERA_INDEX = 0
CAMERA_WIDTH = 640
CAMERA_HEIGHT = 480
MODEL_IMAGE_SIZE = 640
CONFIDENCE_THRESHOLD = 0.3
LOW_CONFIDENCE_THRESHOLD = 0.1
IOU_THRESHOLD = 0.45
HOLD_SECONDS = 2
MATCH_IOU_THRESHOLD = 0.3
CROSS_CLASS_IOU_THRESHOLD = 0.5
ZONE_TRACK_IOU_THRESHOLD = 0.3
ZONE_TRACK_TTL_SECONDS = 1.0
STOP_SECONDS = 5.0
STOP_MOVE_THRESHOLD_PX = 20.0
STOP_TRACK_IOU_THRESHOLD = 0.3
STOP_TRACK_TTL_SECONDS = 5.0
STOP_CONGESTION_LIMIT = 100
VEHICLE_NAMES = {
    0: "truck",
    1: "trailer",
    2: "bus",
    3: "car",
    4: "motorcycle",
}
WINDOW_NAME = "Vehicle Detection"
ZONE_COLOR = (0, 255, 255)
ZONE_ALPHA = 0.28
ZONE_GRID_STEP = 18
SCREENSHOT_DIR = Path(__file__).resolve().parent / "truck_screenshots"


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


def box_center(box):
    x1, y1, x2, y2 = box
    return (x1 + x2) / 2.0, (y1 + y2) / 2.0


def center_in_box(center, box):
    cx, cy = center
    x1, y1, x2, y2 = box
    return x1 <= cx <= x2 and y1 <= cy <= y2


def is_cross_class_duplicate(box_a, class_a, box_b, class_b):
    if class_a == class_b:
        return False

    center_a = box_center(box_a)
    center_b = box_center(box_b)
    centers_overlap = center_in_box(center_a, box_b) and center_in_box(center_b, box_a)
    boxes_overlap = box_iou(box_a, box_b) >= CROSS_CLASS_IOU_THRESHOLD

    return centers_overlap or boxes_overlap


def remove_cross_class_duplicate_boxes(keep_indexes, boxes_xyxy, class_ids, confidences):
    filtered_indexes = []

    for index in sorted(keep_indexes, key=lambda i: confidences[i], reverse=True):
        box = boxes_xyxy[index]
        class_id = class_ids[index]

        is_duplicate = any(
            is_cross_class_duplicate(
                box,
                class_id,
                boxes_xyxy[kept_index],
                class_ids[kept_index],
            )
            for kept_index in filtered_indexes
        )
        if not is_duplicate:
            filtered_indexes.append(index)

    return filtered_indexes


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

    keep_indexes = remove_cross_class_duplicate_boxes(
        keep_indexes,
        boxes_xyxy,
        class_ids,
        confidences,
    )
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


def on_mouse_click(event, x, y, flags, param):
    if event != cv2.EVENT_LBUTTONDOWN:
        return

    zone_points = param["zone_points"]
    if len(zone_points) >= 4:
        zone_points.clear()

    zone_points.append((x, y))


def get_zone_polygon(zone_points):
    if len(zone_points) != 4:
        return None

    return np.array(zone_points, dtype=np.int32)


def is_center_inside_zone(box, zone_polygon):
    center = box_center(box)
    return cv2.pointPolygonTest(zone_polygon, center, False) >= 0


def count_detections_in_zone(result, zone_polygon):
    counts = {class_id: 0 for class_id in VEHICLE_NAMES}
    if zone_polygon is None or result.boxes is None or result.boxes.cls is None:
        return counts

    boxes_xyxy = result.boxes.xyxy.cpu().numpy()
    class_ids = result.boxes.cls.cpu().numpy().astype(int)

    for box, class_id in zip(boxes_xyxy, class_ids):
        if class_id in counts and is_center_inside_zone(box, zone_polygon):
            counts[class_id] += 1

    return counts


def update_zone_counts(result, zone_polygon, zone_counts, zone_tracks, current_time):
    truck_counted = False
    zone_tracks = [
        track for track in zone_tracks
        if current_time - track["last_seen"] <= ZONE_TRACK_TTL_SECONDS
    ]
    if zone_polygon is None or result.boxes is None or result.boxes.cls is None:
        return zone_counts, zone_tracks, truck_counted

    boxes_xyxy = result.boxes.xyxy.cpu().numpy()
    class_ids = result.boxes.cls.cpu().numpy().astype(int)
    matched_track_indexes = set()

    for box, class_id in zip(boxes_xyxy, class_ids):
        if class_id not in VEHICLE_NAMES or not is_center_inside_zone(box, zone_polygon):
            continue

        best_track_index = None
        best_iou = 0.0

        for track_index, track in enumerate(zone_tracks):
            if track_index in matched_track_indexes:
                continue
            if track["class_id"] != class_id:
                continue

            iou = box_iou(track["box"], box)
            if iou > best_iou:
                best_iou = iou
                best_track_index = track_index

        if best_track_index is None or best_iou < ZONE_TRACK_IOU_THRESHOLD:
            zone_counts[class_id] += 1
            if VEHICLE_NAMES[class_id] == "truck":
                truck_counted = True
            zone_tracks.append({
                "box": box,
                "class_id": class_id,
                "last_seen": current_time,
            })
            matched_track_indexes.add(len(zone_tracks) - 1)
            continue

        zone_tracks[best_track_index]["box"] = box
        zone_tracks[best_track_index]["last_seen"] = current_time
        matched_track_indexes.add(best_track_index)

    return zone_counts, zone_tracks, truck_counted


def save_truck_screenshot(frame, current_time, truck_count):
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = time.strftime("%Y%m%d_%H%M%S", time.localtime(current_time))
    milliseconds = int((current_time - int(current_time)) * 1000)
    filename = f"truck_{truck_count:04d}_{timestamp}_{milliseconds:03d}.jpg"
    cv2.imwrite(str(SCREENSHOT_DIR / filename), frame)


def update_stop_tracks(result, stop_tracks, current_time):
    stop_tracks = [
        track for track in stop_tracks
        if current_time - track["last_seen"] <= STOP_TRACK_TTL_SECONDS
    ]
    if result.boxes is None or result.boxes.cls is None:
        return stop_tracks

    boxes_xyxy = result.boxes.xyxy.cpu().numpy()
    class_ids = result.boxes.cls.cpu().numpy().astype(int)
    matched_track_indexes = set()

    for box, class_id in zip(boxes_xyxy, class_ids):
        if class_id not in VEHICLE_NAMES:
            continue

        best_track_index = None
        best_iou = 0.0
        for track_index, track in enumerate(stop_tracks):
            if track_index in matched_track_indexes:
                continue
            if track["class_id"] != class_id:
                continue

            iou = box_iou(track["box"], box)
            if iou > best_iou:
                best_iou = iou
                best_track_index = track_index

        center = box_center(box)
        if best_track_index is None or best_iou < STOP_TRACK_IOU_THRESHOLD:
            stop_tracks.append({
                "box": box,
                "class_id": class_id,
                "center": center,
                "stopped_since": current_time,
                "last_seen": current_time,
            })
            matched_track_indexes.add(len(stop_tracks) - 1)
            continue

        track = stop_tracks[best_track_index]
        dx = center[0] - track["center"][0]
        dy = center[1] - track["center"][1]
        if (dx * dx + dy * dy) ** 0.5 > STOP_MOVE_THRESHOLD_PX:
            track["center"] = center
            track["stopped_since"] = current_time

        track["box"] = box
        track["last_seen"] = current_time
        matched_track_indexes.add(best_track_index)

    return stop_tracks


def draw_stop_alerts(frame, stop_tracks, total_vehicles, current_time):
    if total_vehicles >= STOP_CONGESTION_LIMIT:
        return

    for track in stop_tracks:
        stopped_seconds = current_time - track["stopped_since"]
        if stopped_seconds < STOP_SECONDS:
            continue

        x1, y1, x2, y2 = track["box"].astype(int)
        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 3)
        cv2.putText(
            frame,
            f"STOPPED {stopped_seconds:.0f}s",
            (x1, max(20, y1 - 10)),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.65,
            (0, 0, 255),
            2,
            lineType=cv2.LINE_AA,
        )


def draw_zone(frame, zone_points):
    if not zone_points:
        return

    points = np.array(zone_points, dtype=np.int32)
    if len(points) < 4:
        for point in points:
            cv2.circle(frame, tuple(point), 4, ZONE_COLOR, -1)
        if len(points) > 1:
            cv2.polylines(frame, [points], False, ZONE_COLOR, 1, lineType=cv2.LINE_AA)
        return

    polygon = points.reshape((-1, 1, 2))
    overlay = frame.copy()
    mask = np.zeros(frame.shape[:2], dtype=np.uint8)
    cv2.fillPoly(mask, [polygon], 255)

    x, y, w, h = cv2.boundingRect(polygon)
    for grid_x in range(x, x + w + 1, ZONE_GRID_STEP):
        cv2.line(overlay, (grid_x, y), (grid_x, y + h), ZONE_COLOR, 1, lineType=cv2.LINE_AA)
    for grid_y in range(y, y + h + 1, ZONE_GRID_STEP):
        cv2.line(overlay, (x, grid_y), (x + w, grid_y), ZONE_COLOR, 1, lineType=cv2.LINE_AA)

    blended = cv2.addWeighted(overlay, ZONE_ALPHA, frame, 1.0 - ZONE_ALPHA, 0)
    frame[mask > 0] = blended[mask > 0]
    cv2.polylines(frame, [polygon], True, ZONE_COLOR, 1, lineType=cv2.LINE_AA)


def draw_zone_counts(frame, zone_counts):
    title_y = 220
    cv2.putText(
        frame,
        "Zone",
        (10, title_y),
        cv2.FONT_HERSHEY_SIMPLEX,
        0.65,
        ZONE_COLOR,
        2,
        lineType=cv2.LINE_AA,
    )

    for line_index, class_id in enumerate(VEHICLE_NAMES):
        text = f"{VEHICLE_NAMES[class_id]}: {zone_counts[class_id]}"
        cv2.putText(
            frame,
            text,
            (10, title_y + 30 + line_index * 30),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.65,
            ZONE_COLOR,
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
    zone_points = []
    zone_counts = {class_id: 0 for class_id in VEHICLE_NAMES}
    zone_tracks = []
    stop_tracks = []
    cv2.setMouseCallback(WINDOW_NAME, on_mouse_click, {"zone_points": zone_points})

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
            display_frame = result.plot()
            total_vehicles = len(result.boxes) if result.boxes is not None else 0
            stop_tracks = update_stop_tracks(result, stop_tracks, current_time)
            zone_polygon = get_zone_polygon(zone_points)
            zone_counts, zone_tracks, truck_counted = update_zone_counts(
                result,
                zone_polygon,
                zone_counts,
                zone_tracks,
                current_time,
            )
            draw_zone(display_frame, zone_points)
            draw_zone_counts(display_frame, zone_counts)
            draw_stop_alerts(display_frame, stop_tracks, total_vehicles, current_time)
            if truck_counted:
                save_truck_screenshot(display_frame, current_time, zone_counts[0])

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
