import argparse

from backend import (
    DEFAULT_HTTP_PORT,
    GestureAutoBackend,
    GestureAutoRuntime,
    create_app,
)


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
