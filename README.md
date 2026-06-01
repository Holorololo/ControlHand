# MovilControl

Frontend Flutter con `GetX` para consumir el backend de `proyectoauto`, expuesto por `Flask`.

La arquitectura ya soporta estos escenarios:

- el backend Python corre en tu computadora y usa la camara de la PC,
- Flutter corre en Windows o en un celular,
- el celular consume el backend por HTTP.
- si Flutter corre en el celular, tambien puede usar la camara del telefono y enviar los frames al backend de la PC.

## Arquitectura

- `backend/`: backend Python con OpenCV + MediaPipe + Flask.
- `lib/app/services/auto_state_polling_service.dart`: cliente HTTP, polling, preview y reconexion.
- `lib/app/modules/home/controllers/home_controller.dart`: estado reactivo con GetX.
- `lib/app/modules/home/views/home_view.dart`: pantalla principal que compone el dashboard Flutter.

## Endpoints del backend

Cuando `proyectoauto` esta corriendo, publica:

- `GET /health`
- `GET /state`
- `GET /camera.jpg`

Por defecto el cliente apunta a:

```text
http://127.0.0.1:5000
```

## Flujo de trabajo

1. En `Windows desktop`, puedes abrir Flutter directamente:

```powershell
flutter run -d windows
```

Si el host es `127.0.0.1`, Flutter intentara arrancar el backend automaticamente con:

```powershell
.\venv\Scripts\python.exe backend\backend.py --mode backend --host 0.0.0.0 --port 5000
```

2. En `Android fisico` por USB, usa este lanzador:

```powershell
.\tool\run_android_with_backend.ps1
```

Ese script:

- inicia `proyectoauto` en tu PC,
- verifica `http://127.0.0.1:5000/health`,
- ejecuta `adb reverse tcp:5000 tcp:5000`,
- lanza `flutter run`.

3. Si prefieres iniciar el backend manualmente en tu PC:

```powershell
.\venv\Scripts\python.exe backend\backend.py --mode backend --input-source mobile --host 0.0.0.0 --port 5000
```

Tambien puedes usar el helper que lo deja listo para celular por Wi-Fi y te muestra la IP correcta:

```powershell
.\tool\start_backend_for_mobile.ps1
```

4. Si quieres abrir tambien las ventanas de OpenCV:

```powershell
.\venv\Scripts\python.exe backend\backend.py --mode both --input-source mobile --host 0.0.0.0 --port 5000
```

## Conectar desde movil

Tienes tres formas practicas:

1. `ADB reverse` en desarrollo Android por USB:
   deja el host en `127.0.0.1` y el puerto en `5000`, pero lanza la app con `.\tool\run_android_with_backend.ps1`.

2. `Misma red Wi-Fi`:
   corre Flask con `--input-source mobile --host 0.0.0.0`, averigua la IP de tu PC con `ipconfig` y en Flutter pon algo como `192.168.1.25` y puerto `5000`.
   Tambien debes permitir el puerto `5000` en Windows Firewall.
   Si quieres automatizar eso, usa `.\tool\start_backend_for_mobile.ps1`.

3. `Backend remoto fuera de tu red local`:
   usa una VPN tipo Tailscale o un tunel HTTPS y apunta Flutter al dominio o IP remota.
   Hoy el backend no tiene autenticacion, asi que no conviene exponer `5000` a Internet de forma abierta.

## Lo importante para Android

- En Android, `127.0.0.1` significa "el propio telefono", no tu computadora.
- La app movil no puede ejecutar `python.exe`.
- Si quieres usar la camara del celular, el backend debe arrancar con `--input-source mobile`.
- La app movil abre la camara del telefono y sube frames JPEG al endpoint `POST /frame`.
- Android ya tiene `INTERNET` y `usesCleartextTraffic="true"`, asi que `http://IP_DE_TU_PC:5000` funciona en LAN.

## Lanzar con host remoto preconfigurado

Si no quieres escribir la IP manualmente cada vez, puedes iniciar Flutter con `dart-define`:

```powershell
flutter run -d android --dart-define=BACKEND_HOST=192.168.1.25 --dart-define=BACKEND_PORT=5000
```

Con eso la app abrira ya apuntando a tu PC. En movil el autoconnect solo se hace si defines el host explicitamente.

El nuevo helper tambien puede lanzar Flutter por ti:

```powershell
.\tool\start_backend_for_mobile.ps1 -RunFlutter
```

Si tienes varios adaptadores de red, puedes forzar la IP:

```powershell
.\tool\start_backend_for_mobile.ps1 -HostIp 192.168.1.25 -RunFlutter
```

## Que falta para compartirlo "remotamente" de verdad

En red local ya esta casi listo. Para uso remoto mas serio te faltaria:

- autenticacion o al menos un token simple,
- HTTPS si sales de la LAN,
- revisar el polling HTTP si quieres menos latencia o mas eficiencia,
- opcionalmente pasar a WebSocket o streaming MJPEG si luego quieres una experiencia mas fluida.

## Estado actual

- Python mantiene camara + MediaPipe + deteccion.
- Flask expone estado y preview por HTTP.
- Flutter maneja UI, arranque del backend en desktop, conexion, reconexion y render del estado.
- Si apuntas a una IP remota, Flutter ya no intenta iniciar Python local por error.
- En movil, Flutter puede usar la camara del telefono y enviar frames al backend remoto.

## Nota de entorno

Para compilar `windows` necesitas la toolchain de Visual Studio C++ instalada. Si falta, revisa:

```powershell
flutter doctor
```
