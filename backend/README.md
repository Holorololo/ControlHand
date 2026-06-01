# Backend Python

Este directorio contiene el backend de `proyectoauto` separado del frontend Flutter.

## Archivos

- `backend.py`: backend Flask + OpenCV + MediaPipe.
- `requirements.txt`: dependencias Python.
- `run_backend.bat`: lanzador rapido para Windows.
- `ejemplo_cliente_dart.dart`: cliente de ejemplo para consultar `/state`.

## Instalar dependencias

Desde la raiz del proyecto:

```powershell
.\venv\Scripts\python.exe -m pip install -r backend\requirements.txt
```

Si usas otro entorno virtual, cambia la ruta de `python.exe`.

## Ejecutar el backend

Modo backend local con camara de la PC:

```powershell
.\backend\run_backend.bat --mode backend --input-source desktop --host 0.0.0.0 --port 5000
```

Modo backend para recibir frames del celular:

```powershell
.\backend\run_backend.bat --mode backend --input-source mobile --host 0.0.0.0 --port 5000
```

Modo con ventanas de OpenCV:

```powershell
.\backend\run_backend.bat --mode both --input-source mobile --host 0.0.0.0 --port 5000
```

Tambien puedes usar Python directo:

```powershell
.\venv\Scripts\python.exe backend\backend.py --mode backend --input-source mobile --host 0.0.0.0 --port 5000
```

## Endpoints

- `GET /health`
- `GET /state`
- `GET /camera.jpg`
- `POST /frame`
