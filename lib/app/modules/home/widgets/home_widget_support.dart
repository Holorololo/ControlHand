import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../services/auto_socket_service.dart';
import '../../../services/mobile_camera_relay_service.dart';
import '../../../theme/app_theme.dart';

enum HomeTone { good, warn, alert, soft }

HomeTone connectionTone(SocketConnectionStatus status) {
  return switch (status) {
    SocketConnectionStatus.connected => HomeTone.good,
    SocketConnectionStatus.connecting => HomeTone.warn,
    SocketConnectionStatus.disconnected => HomeTone.alert,
  };
}

HomeTone cameraTone(MobileCameraRelayStatus status) {
  return switch (status) {
    MobileCameraRelayStatus.streaming => HomeTone.good,
    MobileCameraRelayStatus.ready => HomeTone.soft,
    MobileCameraRelayStatus.initializing => HomeTone.warn,
    MobileCameraRelayStatus.failed => HomeTone.alert,
    MobileCameraRelayStatus.permissionDenied => HomeTone.alert,
    MobileCameraRelayStatus.idle => HomeTone.soft,
    MobileCameraRelayStatus.unsupported => HomeTone.alert,
  };
}

HomeTone backendTone(String label) {
  if (label.contains('Fallo') || label.contains('inactivo')) {
    return HomeTone.alert;
  }
  if (label.contains('Buscando') || label.contains('Iniciando')) {
    return HomeTone.warn;
  }
  if (label.contains('externo')) {
    return HomeTone.soft;
  }
  return HomeTone.good;
}

class HomeTonePalette {
  const HomeTonePalette({
    required this.background,
    required this.border,
    required this.foreground,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Color text;
}

HomeTonePalette toneColors(HomeTone tone) {
  return switch (tone) {
    HomeTone.good => const HomeTonePalette(
      background: Color(0x142AF5B3),
      border: Color(0x332AF5B3),
      foreground: AppTheme.success,
      text: Color(0xFFD7FFF4),
    ),
    HomeTone.warn => const HomeTonePalette(
      background: Color(0x14FFC857),
      border: Color(0x33FFC857),
      foreground: AppTheme.warning,
      text: Color(0xFFFFF2CC),
    ),
    HomeTone.alert => const HomeTonePalette(
      background: Color(0x14FF5D8F),
      border: Color(0x33FF5D8F),
      foreground: AppTheme.danger,
      text: Color(0xFFFFDCE8),
    ),
    HomeTone.soft => const HomeTonePalette(
      background: Color(0x1200D9FF),
      border: Color(0x3300D9FF),
      foreground: AppTheme.primarySoft,
      text: AppTheme.text,
    ),
  };
}

class PanelShell extends StatelessWidget {
  const PanelShell({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
          const BoxShadow(
            color: Color(0x60000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.stroke),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x68000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SurfaceFrame extends StatelessWidget {
  const SurfaceFrame({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.panelStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: child,
    );
  }
}

class MiniMetric extends StatelessWidget {
  const MiniMetric({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SurfaceFrame(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricBadge extends StatelessWidget {
  const MetricBadge({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: RichText(
        text: TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SurfaceTile extends StatelessWidget {
  const SurfaceTile({
    required this.title,
    required this.body,
    this.monospace = false,
    super.key,
  });

  final String title;
  final String body;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return SurfaceFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            body,
            style: TextStyle(
              color: monospace ? AppTheme.primarySoft : AppTheme.muted,
              height: 1.5,
              fontSize: 13.5,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class AlertStrip extends StatelessWidget {
  const AlertStrip({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFFB4C8),
          fontSize: 13,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class GlassTag extends StatelessWidget {
  const GlassTag({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: AppTheme.primarySoft, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusDotChip extends StatelessWidget {
  const StatusDotChip({required this.label, required this.tone, super.key});

  final String label;
  final HomeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = toneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.foreground,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.foreground.withValues(alpha: 0.45),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text(
            label,
            style: TextStyle(
              color: colors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SoftChip extends StatelessWidget {
  const SoftChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.muted,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class BrandCluster extends StatelessWidget {
  const BrandCluster({required this.compact, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GlassTag(
          icon: Icons.memory_rounded,
          label: compact ? 'MOVILCONTROL' : 'MOVILCONTROL // NEON DRIVE',
        ),
        SizedBox(height: compact ? 10 : 12),
        Text(
          compact ? 'Panel remoto' : 'Camara, gestos y backend remoto',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontSize: compact ? 20 : 28),
        ),
      ],
    );
  }
}

class NeonBackdrop extends StatelessWidget {
  const NeonBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: -80,
          left: -50,
          child: GlowOrb(
            size: 240,
            color: AppTheme.primary.withValues(alpha: 0.16),
          ),
        ),
        Positioned(
          top: 140,
          right: -30,
          child: GlowOrb(
            size: 180,
            color: AppTheme.secondary.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          bottom: -100,
          left: 40,
          child: GlowOrb(
            size: 260,
            color: AppTheme.primarySoft.withValues(alpha: 0.12),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: GridPainter())),
        ),
      ],
    );
  }
}

class LiveCameraFill extends StatelessWidget {
  const LiveCameraFill({required this.controller, super.key});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    final width = previewSize?.height ?? 720;
    final height = previewSize?.width ?? 1280;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: width,
        height: height,
        child: CameraPreview(controller),
      ),
    );
  }
}

class PreviewImage extends StatelessWidget {
  const PreviewImage({required this.bytes, super.key});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}

class CameraWaitingSurface extends StatelessWidget {
  const CameraWaitingSurface({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.24),
                ),
              ),
              child: Icon(icon, color: AppTheme.primarySoft, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message.isEmpty
                  ? 'Preparando el flujo de camara para el modo remoto.'
                  : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TargetReticle extends StatelessWidget {
  const TargetReticle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.32),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 48,
                height: 2,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: 48,
                height: 2,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 48,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 2,
                height: 48,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoadStrip extends StatelessWidget {
  const RoadStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF111419),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(
            6,
            (_) => Container(
              width: 28,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.text.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CyberCar extends StatelessWidget {
  const CyberCar({required this.moving, super.key});

  final bool moving;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 280),
      offset: moving ? Offset.zero : const Offset(-0.02, 0),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 280),
        scale: moving ? 1 : 0.97,
        child: SizedBox(
          width: 112,
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 18,
                right: 18,
                top: 0,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                bottom: -2,
                child: WheelGlow(moving: moving),
              ),
              Positioned(
                right: 14,
                bottom: -2,
                child: WheelGlow(moving: moving),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WheelGlow extends StatelessWidget {
  const WheelGlow({required this.moving, super.key});

  final bool moving;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: const Duration(milliseconds: 260),
      turns: moving ? 0.12 : 0,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF05070D),
          border: Border.all(color: AppTheme.primarySoft, width: 2),
        ),
      ),
    );
  }
}

class GlowOrb extends StatelessWidget {
  const GlowOrb({required this.size, required this.color, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 42.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
