import argparse
import threading
import time
from dataclasses import asdict, dataclass
from typing import Callable, Optional

import cv2
from flask import Flask, Response, jsonify, request
from flask_cors import CORS
import mediapipe as mp
import numpy as np

CAM_WIDTH = 900
CAM_HEIGHT = 600
ROAD_Y = 420
AUTO_START_X = 50
AUTO_Y = 350
AUTO_SPEED = 8
PREVIEW_STREAM_WIDTH = 480
PREVIEW_JPEG_QUALITY = 70
PROCESSING_MAX_WIDTH = 640
DEFAULT_HTTP_PORT = 5000

WINDOW_HAND = "Camara y Mano"
WINDOW_CAR = "Auto"

COLOR_GREEN = (0, 255, 0)
COLOR_RED = (0, 0, 255)
COLOR_WHITE = (255, 255, 255)
COLOR_BLUE = (255, 0, 0)
COLOR_YELLOW = (0, 255, 255)
COLOR_BLACK = (0, 0, 0)
COLOR_GRAY = (50, 50, 50)


@dataclass
class AutoState:
    timestamp: float
    hand_detected: bool
    hand_state: str
    fingers_up: int
    car_moving: bool
    car_x: int
    car_y: int
    speed: int

    def to_dict(self):
        return asdict(self)

    @classmethod
    def waiting(cls, speed=AUTO_SPEED):
        return cls(
            timestamp=time.time(),
            hand_detected=False,
            hand_state="Esperando camara",
            fingers_up=0,
            car_moving=False,
            car_x=AUTO_START_X,
            car_y=AUTO_Y,
            speed=speed,
        )


class GestureAutoBackend:
    def __init__(
        self,
        camera_index=0,
        camera_width=CAM_WIDTH,
        camera_height=CAM_HEIGHT,
        auto_speed=AUTO_SPEED,
        min_detection_confidence=0.7,
        min_tracking_confidence=0.7,
        stable_frames=3,
        preview_stream_width=PREVIEW_STREAM_WIDTH,
        preview_jpeg_quality=PREVIEW_JPEG_QUALITY,
        processing_max_width=PROCESSING_MAX_WIDTH,
    ):
        self.camera_index = camera_index
        self.camera_width = camera_width
        self.camera_height = camera_height
        self.auto_speed = auto_speed
        self.stable_frames = max(1, stable_frames)
        self.preview_stream_width = max(0, preview_stream_width)
        self.preview_jpeg_quality = max(30, min(95, preview_jpeg_quality))
        self.processing_max_width = max(0, processing_max_width)

        self.auto_x = AUTO_START_X
        self.auto_y = AUTO_Y

        self._last_raw_state = None
        self._raw_state_count = 0
        self._stable_hand_state = "No se detecta mano"
        self._stable_fingers_up = 0
        self._stable_car_moving = False
        self._stable_hand_detected = False

        self.mp_hands = mp.solutions.hands
        self.mp_draw = mp.solutions.drawing_utils
        self.hands = self.mp_hands.Hands(
            static_image_mode=False,
            max_num_hands=1,
            min_detection_confidence=min_detection_confidence,
            min_tracking_confidence=min_tracking_confidence,
        )

    def close(self):
        self.hands.close()

    def contar_dedos(self, landmarks, hand_label):
        dedos = []

        if hand_label == "Right":
            dedos.append(1 if landmarks[4].x < landmarks[3].x else 0)
        else:
            dedos.append(1 if landmarks[4].x > landmarks[3].x else 0)

        dedos.append(1 if landmarks[8].y < landmarks[6].y else 0)
        dedos.append(1 if landmarks[12].y < landmarks[10].y else 0)
        dedos.append(1 if landmarks[16].y < landmarks[14].y else 0)
        dedos.append(1 if landmarks[20].y < landmarks[18].y else 0)

        return dedos.count(1)

    def _raw_hand_state(self, results):
        state = {
            "hand_detected": False,
            "hand_state": "No se detecta mano",
            "fingers_up": 0,
            "car_moving": False,
        }

        if not results.multi_hand_landmarks:
            return state

        hand_landmarks = results.multi_hand_landmarks[0]
        handedness = results.multi_handedness[0]
        hand_label = handedness.classification[0].label
        fingers_up = self.contar_dedos(hand_landmarks.landmark, hand_label)

        if fingers_up >= 4:
            hand_state = "MANO ABIERTA"
            car_moving = True
        elif fingers_up <= 1:
            hand_state = "MANO CERRADA"
            car_moving = False
        else:
            hand_state = "MANO SEMIABIERTA"
            car_moving = False

        state["hand_detected"] = True
        state["hand_state"] = hand_state
        state["fingers_up"] = fingers_up
        state["car_moving"] = car_moving
        return state

    def _apply_stability(self, raw_state):
        raw_key = (
            raw_state["hand_detected"],
            raw_state["hand_state"],
            raw_state["fingers_up"],
            raw_state["car_moving"],
        )

        if raw_key == self._last_raw_state:
            self._raw_state_count += 1
        else:
            self._last_raw_state = raw_key
            self._raw_state_count = 1

        if self._raw_state_count >= self.stable_frames:
            self._stable_hand_detected = raw_state["hand_detected"]
            self._stable_hand_state = raw_state["hand_state"]
            self._stable_fingers_up = raw_state["fingers_up"]
            self._stable_car_moving = raw_state["car_moving"]

        return {
            "hand_detected": self._stable_hand_detected,
            "hand_state": self._stable_hand_state,
            "fingers_up": self._stable_fingers_up,
            "car_moving": self._stable_car_moving,
        }

    def dibujar_mano(self, frame, results):
        if not results.multi_hand_landmarks:
            return frame

        for hand_landmarks in results.multi_hand_landmarks:
            self.mp_draw.draw_landmarks(
                frame,
                hand_landmarks,
                self.mp_hands.HAND_CONNECTIONS,
            )

        return frame

    def dibujar_auto(self, frame, x, y):
        cv2.rectangle(frame, (x, y), (x + 120, y + 40), COLOR_BLUE, -1)

        pts = np.array(
            [
                [x + 20, y],
                [x + 40, y - 25],
                [x + 85, y - 25],
                [x + 100, y],
            ],
            dtype=np.int32,
        )
        cv2.fillPoly(frame, [pts], COLOR_YELLOW)

        cv2.circle(frame, (x + 25, y + 45), 12, COLOR_BLACK, -1)
        cv2.circle(frame, (x + 95, y + 45), 12, COLOR_BLACK, -1)

        cv2.rectangle(frame, (x + 43, y - 22), (x + 62, y - 2), COLOR_WHITE, -1)
        cv2.rectangle(frame, (x + 65, y - 22), (x + 83, y - 2), COLOR_WHITE, -1)

    def crear_escena_auto(self, state):
        scene = np.zeros((self.camera_height, self.camera_width, 3), dtype=np.uint8)
        scene[:] = (20, 140, 20)

        cv2.rectangle(
            scene,
            (0, ROAD_Y - 40),
            (self.camera_width, ROAD_Y + 40),
            COLOR_GRAY,
            -1,
        )

        for i in range(0, self.camera_width, 80):
            cv2.line(scene, (i, ROAD_Y), (i + 40, ROAD_Y), COLOR_WHITE, 4)

        self.dibujar_auto(scene, state.car_x, state.car_y)

        if state.car_moving:
            texto_auto = "AUTO: AVANZANDO"
            color_auto = COLOR_GREEN
        else:
            texto_auto = "AUTO: DETENIDO"
            color_auto = COLOR_RED

        cv2.putText(
            scene,
            texto_auto,
            (30, 60),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.9,
            color_auto,
            3,
        )
        cv2.putText(
            scene,
            f"Control: {state.hand_state}",
            (30, 105),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            COLOR_WHITE,
            2,
        )
        cv2.putText(
            scene,
            "Abre la mano para avanzar",
            (30, 150),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            COLOR_WHITE,
            2,
        )
        cv2.putText(
            scene,
            "Cierra la mano para detener",
            (30, 185),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            COLOR_WHITE,
            2,
        )
        return scene

    def dibujar_panel_mano(self, frame, state):
        if state.car_moving:
            texto_auto = "AUTO: AVANZANDO"
            color_auto = COLOR_GREEN
        else:
            texto_auto = "AUTO: DETENIDO"
            color_auto = COLOR_RED

        cv2.putText(
            frame,
            state.hand_state,
            (30, 60),
            cv2.FONT_HERSHEY_SIMPLEX,
            1.0,
            COLOR_GREEN,
            3,
        )
        cv2.putText(
            frame,
            f"Dedos levantados: {state.fingers_up}",
            (30, 110),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.8,
            COLOR_WHITE,
            2,
        )
        cv2.putText(
            frame,
            texto_auto,
            (30, 160),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.9,
            color_auto,
            3,
        )
        cv2.putText(
            frame,
            "Q para salir",
            (30, 210),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            COLOR_WHITE,
            2,
        )
        return frame

    def encode_preview_frame(self, frame):
        if frame is None:
            return None

        source_height, source_width = frame.shape[:2]
        preview_frame = frame
        target_width = source_width
        target_height = source_height

        if self.preview_stream_width > 0 and source_width > self.preview_stream_width:
            target_width = self.preview_stream_width
            scale = target_width / float(source_width)
            target_height = max(1, int(source_height * scale))
            preview_frame = cv2.resize(
                frame,
                (target_width, target_height),
                interpolation=cv2.INTER_AREA,
            )

        success, encoded = cv2.imencode(
            ".jpg",
            preview_frame,
            [int(cv2.IMWRITE_JPEG_QUALITY), self.preview_jpeg_quality],
        )

        if not success:
            return None

        return encoded.tobytes(), target_width, target_height

    def fit_frame_to_canvas(self, frame):
        source_height, source_width = frame.shape[:2]
        if source_height <= 0 or source_width <= 0:
            return frame

        target_ratio = self.camera_width / float(self.camera_height)
        source_ratio = source_width / float(source_height)

        if abs(source_ratio - target_ratio) > 0.01:
            if source_ratio > target_ratio:
                cropped_width = max(1, int(round(source_height * target_ratio)))
                offset_x = max(0, (source_width - cropped_width) // 2)
                frame = frame[:, offset_x : offset_x + cropped_width]
            else:
                cropped_height = max(1, int(round(source_width / target_ratio)))
                offset_y = max(0, (source_height - cropped_height) // 2)
                frame = frame[offset_y : offset_y + cropped_height, :]

        return frame

    def resize_for_processing(self, frame):
        if self.processing_max_width <= 0:
            return frame

        source_height, source_width = frame.shape[:2]
        if source_width <= self.processing_max_width:
            return frame

        scale = self.processing_max_width / float(source_width)
        target_height = max(1, int(source_height * scale))
        return cv2.resize(
            frame,
            (self.processing_max_width, target_height),
            interpolation=cv2.INTER_AREA,
        )

    def process_frame(self, frame):
        frame = cv2.flip(frame, 1)
        frame = self.fit_frame_to_canvas(frame)
        frame = self.resize_for_processing(frame)

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.hands.process(rgb)

        raw_state = self._raw_hand_state(results)
        stable_state = self._apply_stability(raw_state)

        if stable_state["car_moving"]:
            self.auto_x += self.auto_speed

        if self.auto_x > self.camera_width:
            self.auto_x = -140

        state = AutoState(
            timestamp=time.time(),
            hand_detected=stable_state["hand_detected"],
            hand_state=stable_state["hand_state"],
            fingers_up=stable_state["fingers_up"],
            car_moving=stable_state["car_moving"],
            car_x=self.auto_x,
            car_y=self.auto_y,
            speed=self.auto_speed,
        )

        hand_frame = self.dibujar_mano(frame, results)
        hand_frame = self.dibujar_panel_mano(hand_frame, state)
        auto_frame = self.crear_escena_auto(state)
        return state, hand_frame, auto_frame

    def run(
        self,
        show_windows=False,
        frame_callback: Optional[Callable[[AutoState, np.ndarray, np.ndarray], None]] = None,
        stop_event: Optional[threading.Event] = None,
    ):
        cap = cv2.VideoCapture(self.camera_index)
        cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.camera_width)
        cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.camera_height)

        if not cap.isOpened():
            raise RuntimeError("No se pudo abrir la camara.")

        local_stop_event = stop_event or threading.Event()

        try:
            while not local_stop_event.is_set():
                ret, frame = cap.read()
                if not ret:
                    raise RuntimeError("No se pudo leer la camara.")

                state, hand_frame, auto_frame = self.process_frame(frame)

                if frame_callback is not None:
                    frame_callback(state, hand_frame, auto_frame)

                if show_windows:
                    cv2.imshow(WINDOW_HAND, hand_frame)
                    cv2.imshow(WINDOW_CAR, auto_frame)

                    if cv2.waitKey(1) & 0xFF == ord("q"):
                        break
        finally:
            cap.release()
            cv2.destroyAllWindows()


class GestureAutoRuntime:
    def __init__(self, backend: GestureAutoBackend, input_source="desktop", show_windows=False):
        self.backend = backend
        self.input_source = input_source
        self.show_windows = show_windows

        self._state_lock = threading.Lock()
        self._stop_event = threading.Event()
        self._thread = None

        self._state = AutoState.waiting(speed=backend.auto_speed)
        self._camera_preview_jpeg = None
        self._camera_preview_width = None
        self._camera_preview_height = None
        self._camera_preview_version = 0
        self._ready = False
        self._message = "Esperando backend"
        self._last_error = ""

    def start(self):
        if self.input_source == "mobile":
            self._set_runtime_state(
                ready=False,
                message="Esperando frames de la camara del celular...",
                last_error="",
            )
            return

        if self._thread is not None and self._thread.is_alive():
            return

        self._stop_event.clear()
        self._thread = threading.Thread(target=self._run_loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._stop_event.set()
        if self._thread is not None:
            self._thread.join(timeout=3)
            self._thread = None
        cv2.destroyAllWindows()
        self.backend.close()

    def snapshot(self):
        with self._state_lock:
            payload = self._state.to_dict()
            payload.update(
                {
                    "backend_ready": self._ready,
                    "backend_source": self.input_source,
                    "backend_message": self._message,
                    "backend_last_error": self._last_error,
                    "camera_preview_available": self._camera_preview_jpeg is not None,
                    "camera_preview_width": self._camera_preview_width,
                    "camera_preview_height": self._camera_preview_height,
                    "camera_preview_version": self._camera_preview_version,
                }
            )
            return payload

    def health_payload(self):
        with self._state_lock:
            return {
                "ok": True,
                "backend_ready": self._ready,
                "backend_source": self.input_source,
                "backend_message": self._message,
                "backend_last_error": self._last_error,
                "camera_preview_available": self._camera_preview_jpeg is not None,
                "camera_preview_version": self._camera_preview_version,
                "timestamp": self._state.timestamp,
            }

    def camera_preview_jpeg(self):
        with self._state_lock:
            if self._camera_preview_jpeg is None:
                return None
            return bytes(self._camera_preview_jpeg)

    def accepts_mobile_frames(self):
        return self.input_source == "mobile"

    def submit_mobile_frame(self, frame_bytes):
        if self.input_source != "mobile":
            raise RuntimeError("Este backend no esta configurado para recibir frames remotos.")

        if not frame_bytes:
            raise ValueError("No se recibieron bytes JPEG del celular.")

        decoded = cv2.imdecode(
            np.frombuffer(frame_bytes, dtype=np.uint8),
            cv2.IMREAD_COLOR,
        )
        if decoded is None:
            raise ValueError("No se pudo decodificar la imagen enviada por el celular.")

        state, hand_frame, auto_frame = self.backend.process_frame(decoded)
        self._handle_frame(
            state,
            hand_frame,
            auto_frame,
            source_message="Camara del celular enviando frames al backend.",
        )

        if self.show_windows:
            cv2.imshow(WINDOW_HAND, hand_frame)
            cv2.imshow(WINDOW_CAR, auto_frame)
            cv2.waitKey(1)

        return self.snapshot()

    def _run_loop(self):
        self._set_runtime_state(
            ready=False,
            message="Inicializando camara y deteccion...",
            last_error="",
        )

        try:
            self.backend.run(
                show_windows=self.show_windows,
                frame_callback=self._handle_frame,
                stop_event=self._stop_event,
            )
            if not self._stop_event.is_set():
                self._set_runtime_state(
                    ready=False,
                    message="El backend se detuvo.",
                    last_error=self._last_error,
                )
        except Exception as error:  # pragma: no cover - depende de hardware
            self._set_runtime_state(
                ready=False,
                message="No se pudo usar la camara.",
                last_error=str(error),
            )

    def _handle_frame(
        self,
        state,
        hand_frame,
        _auto_frame,
        source_message="Camara y deteccion activas.",
    ):
        preview_payload = self.backend.encode_preview_frame(hand_frame)

        with self._state_lock:
            self._state = state
            if preview_payload is not None:
                preview_jpeg, preview_width, preview_height = preview_payload
                self._camera_preview_jpeg = preview_jpeg
                self._camera_preview_width = preview_width
                self._camera_preview_height = preview_height
                self._camera_preview_version += 1

            self._ready = True
            self._message = source_message
            self._last_error = ""

    def _set_runtime_state(self, ready, message, last_error):
        with self._state_lock:
            self._ready = ready
            self._message = message
            self._last_error = last_error


def create_app(runtime: GestureAutoRuntime):
    app = Flask(__name__)
    CORS(app)

    @app.after_request
    def add_no_cache_headers(response):
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "0"
        return response

    @app.get("/")
    def index():
        return jsonify(
            {
                "service": "proyectoauto",
                "endpoints": {
                    "health": "/health",
                    "state": "/state",
                    "camera": "/camera.jpg",
                    "frame": "/frame",
                },
            }
        )

    @app.get("/health")
    def health():
        return jsonify(runtime.health_payload())

    @app.get("/state")
    def state():
        return jsonify(runtime.snapshot())

    @app.get("/camera.jpg")
    def camera_preview():
        preview_bytes = runtime.camera_preview_jpeg()
        if preview_bytes is None:
            return Response(status=204)

        return Response(preview_bytes, mimetype="image/jpeg")

    @app.post("/frame")
    def submit_frame():
        if not runtime.accepts_mobile_frames():
            return (
                jsonify(
                    {
                        "ok": False,
                        "message": "Este backend esta usando la camara local de la PC.",
                    }
                ),
                409,
            )

        frame_file = request.files.get("frame")
        frame_bytes = frame_file.read() if frame_file is not None else request.get_data(cache=False)

        if not frame_bytes:
            return (
                jsonify(
                    {
                        "ok": False,
                        "message": "Debes enviar un JPEG en el cuerpo de la peticion o como campo frame.",
                    }
                ),
                400,
            )

        try:
            snapshot = runtime.submit_mobile_frame(frame_bytes)
        except ValueError as error:
            return jsonify({"ok": False, "message": str(error)}), 400
        except Exception as error:  # pragma: no cover - depende del dispositivo
            return jsonify({"ok": False, "message": str(error)}), 500

        return jsonify(
            {
                "ok": True,
                "backend_source": snapshot["backend_source"],
                "camera_preview_version": snapshot["camera_preview_version"],
                "timestamp": snapshot["timestamp"],
            }
        )

    return app


def parse_args():
    parser = argparse.ArgumentParser(
        description="ProyectoAuto: control de auto por mano con backend Flask local."
    )
    parser.add_argument(
        "--mode",
        choices=("preview", "backend", "both"),
        default="backend",
        help="preview abre ventanas, backend publica HTTP, both hace ambas cosas.",
    )
    parser.add_argument(
        "--input-source",
        choices=("desktop", "mobile"),
        default="desktop",
        help="desktop usa la webcam de la PC, mobile espera frames enviados desde el celular.",
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Host de escucha para Flask. Usa 0.0.0.0 para permitir movil en red.",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_HTTP_PORT,
        help="Puerto HTTP del backend Flask.",
    )
    parser.add_argument(
        "--camera-index",
        type=int,
        default=0,
        help="Indice de camara para OpenCV.",
    )
    parser.add_argument(
        "--camera-width",
        type=int,
        default=900,
        help="Ancho de captura y vista.",
    )
    parser.add_argument(
        "--camera-height",
        type=int,
        default=600,
        help="Alto de captura y vista.",
    )
    parser.add_argument(
        "--auto-speed",
        type=int,
        default=8,
        help="Velocidad del auto cuando avanza.",
    )
    parser.add_argument(
        "--preview-width",
        type=int,
        default=480,
        help="Ancho maximo del preview JPEG que se sirve a Flutter. Usa 0 para no reescalar.",
    )
    parser.add_argument(
        "--preview-quality",
        type=int,
        default=70,
        help="Calidad JPEG del preview servido a Flutter.",
    )
    parser.add_argument(
        "--stable-frames",
        type=int,
        default=3,
        help="Frames consecutivos requeridos antes de cambiar el estado de la mano.",
    )
    parser.add_argument(
        "--processing-width",
        type=int,
        default=PROCESSING_MAX_WIDTH,
        help="Ancho maximo usado para procesar la mano antes de MediaPipe. Usa 0 para no reescalar.",
    )
    return parser.parse_args()


def build_backend(args):
    return GestureAutoBackend(
        camera_index=args.camera_index,
        camera_width=args.camera_width,
        camera_height=args.camera_height,
        auto_speed=args.auto_speed,
        stable_frames=args.stable_frames,
        preview_stream_width=args.preview_width,
        preview_jpeg_quality=args.preview_quality,
        processing_max_width=args.processing_width,
    )


def run_preview_mode(args):
    if args.input_source != "desktop":
        raise ValueError("El modo preview solo funciona con --input-source desktop.")

    backend = build_backend(args)
    try:
        backend.run(show_windows=True)
    finally:
        backend.close()


def run_http_mode(args, show_windows):
    backend = build_backend(args)
    runtime = GestureAutoRuntime(
        backend,
        input_source=args.input_source,
        show_windows=show_windows,
    )
    app = create_app(runtime)

    runtime.start()
    print(
        f"Backend Flask escuchando en http://{args.host}:{args.port} "
        f"(input-source={args.input_source})"
    )

    try:
        app.run(
            host=args.host,
            port=args.port,
            debug=False,
            threaded=True,
            use_reloader=False,
        )
    finally:
        runtime.stop()


def main():
    args = parse_args()

    if args.mode == "preview":
        run_preview_mode(args)
        return

    run_http_mode(args, show_windows=args.mode == "both")


if __name__ == "__main__":
    main()
