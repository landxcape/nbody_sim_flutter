import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:nbody_sim_flutter/theme.dart';
import 'package:nbody_sim_core/models.dart';

/// Interactive 2D renderer for `nbody_sim_core` body/state data.
///
/// The widget is rendering-only and intentionally stateless with respect to
/// simulation ownership: host apps keep engine state and update this widget
/// through inputs.
class SimulationCanvas extends StatefulWidget {
  /// Creates a simulation canvas.
  const SimulationCanvas({
    super.key,
    required this.bodies,
    required this.config,
    required this.selectedBodyId,
    required this.cameraMode,
    required this.cameraCenter,
    required this.cameraZoom,
    required this.visualTheme,
    required this.renderOptions,
    required this.trails,
    required this.onSelectBody,
    required this.onPanCamera,
    required this.onZoomCamera,
    required this.onMoveSelectedBody,
  });

  /// Current bodies to render in world space.
  final List<SimulationBody> bodies;

  /// Global simulation configuration used for overlays and field sampling.
  final SimulationConfig config;

  /// Currently selected body id, or `null` when no selection is active.
  final String? selectedBodyId;

  /// Camera mode used to compute the world-to-screen transform.
  final CameraMode cameraMode;

  /// Camera center in world coordinates for free/follow camera modes.
  final Vec2 cameraCenter;

  /// Multiplicative zoom factor applied on top of base fit scale.
  final double cameraZoom;

  /// Visual tokens used by painter layers.
  final SimulatorVisualTheme visualTheme;

  /// Render feature toggles and quality options.
  final RenderOptions renderOptions;

  /// Historical positions keyed by body id for optional trail rendering.
  final Map<String, List<Vec2>> trails;

  /// Called when user taps and selects a body (or clears selection).
  final ValueChanged<String?> onSelectBody;

  /// Called when user pans camera; delta is provided in world coordinates.
  final ValueChanged<Vec2> onPanCamera;

  /// Called for wheel/pinch zoom requests; receives a multiplicative factor.
  final ValueChanged<double> onZoomCamera;

  /// Called when user drags the selected body; receives world position.
  final ValueChanged<Vec2> onMoveSelectedBody;

  @override
  State<SimulationCanvas> createState() => _SimulationCanvasState();
}

class _SimulationCanvasState extends State<SimulationCanvas> {
  String? _draggingBodyId;
  double _lastScale = 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final transform = _WorldTransform.forView(
          bodies: widget.bodies,
          size: size,
          cameraMode: widget.cameraMode,
          cameraCenter: widget.cameraCenter,
          cameraZoom: widget.cameraZoom,
          selectedBodyId: widget.selectedBodyId,
          padding: 24,
        );

        return Listener(
          onPointerSignal: (event) {
            if (event is! PointerScrollEvent) {
              return;
            }
            final factor = math.pow(1.0015, -event.scrollDelta.dy).toDouble();
            widget.onZoomCamera(factor.clamp(0.84, 1.18));
          },
          child: GestureDetector(
            onTapUp: (details) {
              final nearestId = _nearestBodyId(
                tap: details.localPosition,
                transform: transform,
              );
              widget.onSelectBody(nearestId);
            },
            onScaleStart: (details) {
              _lastScale = 1;
              _draggingBodyId = _nearestBodyId(
                tap: details.localFocalPoint,
                transform: transform,
              );
              if (_draggingBodyId != null) {
                widget.onSelectBody(_draggingBodyId);
              }
            },
            onScaleUpdate: (details) {
              final scaleDelta = details.scale / _lastScale;
              _lastScale = details.scale;

              if ((scaleDelta - 1).abs() > 0.001) {
                widget.onZoomCamera(scaleDelta.clamp(0.86, 1.16));
              }

              if (_draggingBodyId != null &&
                  details.pointerCount == 1 &&
                  details.scale == 1) {
                final world = transform.screenToWorld(details.localFocalPoint);
                widget.onMoveSelectedBody(world);
                return;
              }

              final worldDelta = transform.screenDeltaToWorld(
                details.focalPointDelta,
              );
              widget.onPanCamera(Vec2(-worldDelta.x, -worldDelta.y));
            },
            onScaleEnd: (_) {
              _draggingBodyId = null;
            },
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _SimulationPainter(
                  bodies: widget.bodies,
                  config: widget.config,
                  visualTheme: widget.visualTheme,
                  trails: widget.trails,
                  renderOptions: widget.renderOptions,
                  selectedBodyId: widget.selectedBodyId,
                  transform: transform,
                ),
                size: size,
              ),
            ),
          ),
        );
      },
    );
  }

  String? _nearestBodyId({
    required Offset tap,
    required _WorldTransform transform,
  }) {
    String? nearestId;
    var nearestDistance = double.infinity;

    for (final body in widget.bodies.where((body) => body.alive)) {
      final center = transform.worldToScreen(body.position);
      final distance = (center - tap).distance;
      final radiusPx = math.max(8, body.radius * transform.scale);
      if (distance <= radiusPx + 12 && distance < nearestDistance) {
        nearestDistance = distance;
        nearestId = body.id;
      }
    }

    return nearestId;
  }
}

class _SimulationPainter extends CustomPainter {
  _SimulationPainter({
    required this.bodies,
    required this.config,
    required this.visualTheme,
    required this.trails,
    required this.renderOptions,
    required this.selectedBodyId,
    required this.transform,
  });

  final List<SimulationBody> bodies;
  final SimulationConfig config;
  final SimulatorVisualTheme visualTheme;
  final Map<String, List<Vec2>> trails;
  final RenderOptions renderOptions;
  final String? selectedBodyId;
  final _WorldTransform transform;

  @override
  void paint(Canvas canvas, Size size) {
    final aliveBodies = bodies
        .where((body) => body.alive)
        .toList(growable: false);
    final denseScene = aliveBodies.length >= 650;

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          visualTheme.canvasGradientStart,
          visualTheme.canvasGradientMid,
          visualTheme.canvasGradientEnd,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, backgroundPaint);
    if (renderOptions.showFieldOverlay) {
      _drawFieldOverlay(canvas, size, aliveBodies, denseScene: denseScene);
    }
    _drawGrid(canvas, size);
    if (renderOptions.showTrails) {
      _drawTrails(canvas, aliveBodies, denseScene: denseScene);
    }

    final vectorStride = denseScene
        ? math.max(1, (aliveBodies.length / 120).ceil())
        : 1;
    for (var index = 0; index < aliveBodies.length; index++) {
      final body = aliveBodies[index];
      final center = transform.worldToScreen(body.position);
      final radius = math.max(2.5, body.radius * transform.scale);
      final color = Color(body.colorValue);

      final shouldRenderGlow =
          !denseScene ||
          renderOptions.quality == RenderQuality.high ||
          selectedBodyId == body.id;
      if (shouldRenderGlow) {
        final glowRadius = radius * (2.2 + (renderOptions.glowAlpha * 3.5));
        final glowShader = RadialGradient(
          colors: [
            color.withValues(alpha: renderOptions.glowAlpha),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius));
        canvas.drawCircle(
          center,
          glowRadius,
          Paint()
            ..shader = glowShader
            ..blendMode = BlendMode.plus,
        );
      }

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      if (!denseScene || selectedBodyId == body.id) {
        canvas.drawCircle(
          center,
          radius + 1,
          Paint()
            ..color = color.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      if (renderOptions.showVelocityVectors &&
          (!denseScene ||
              selectedBodyId == body.id ||
              index % vectorStride == 0)) {
        final velocityScale = math.max(
          2.0,
          math.min(transform.scale * 0.28, 16),
        );
        final velocityEnd =
            center +
            Offset(
              body.velocity.x * velocityScale,
              -body.velocity.y * velocityScale,
            );
        canvas.drawLine(
          center,
          velocityEnd,
          Paint()
            ..color = visualTheme.vectorColor
            ..strokeWidth = 1.4,
        );
      }

      if (selectedBodyId == body.id) {
        canvas.drawCircle(
          center,
          radius + 4,
          Paint()
            ..color = visualTheme.selectionColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    if (renderOptions.showLensingOverlay) {
      if (!denseScene || renderOptions.quality != RenderQuality.low) {
        _drawLensingOverlay(canvas, aliveBodies);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final spacing = _gridSpacing();
    final paint = Paint()
      ..color = visualTheme.gridColor
      ..strokeWidth = 1;

    final startX = transform.offset.dx % spacing;
    for (double x = startX; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final startY = transform.offset.dy % spacing;
    for (double y = startY; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawTrails(
    Canvas canvas,
    List<SimulationBody> aliveBodies, {
    required bool denseScene,
  }) {
    final bodyStride = denseScene
        ? math.max(1, (aliveBodies.length / 220).ceil())
        : 1;
    final pointStride = denseScene
        ? (renderOptions.quality == RenderQuality.low ? 3 : 2)
        : 1;
    final selectedId = selectedBodyId;

    for (var index = 0; index < aliveBodies.length; index++) {
      final body = aliveBodies[index];
      if (bodyStride > 1 && body.id != selectedId && index % bodyStride != 0) {
        continue;
      }

      final pathPoints = trails[body.id];
      if (pathPoints == null || pathPoints.length < 2) {
        continue;
      }

      final color = Color(body.colorValue).withValues(alpha: 0.35);
      final path = Path()
        ..moveTo(
          transform.worldToScreen(pathPoints.first).dx,
          transform.worldToScreen(pathPoints.first).dy,
        );

      for (var i = pointStride; i < pathPoints.length; i += pointStride) {
        final point = pathPoints[i];
        final screen = transform.worldToScreen(point);
        path.lineTo(screen.dx, screen.dy);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.3,
      );
    }
  }

  void _drawFieldOverlay(
    Canvas canvas,
    Size size,
    List<SimulationBody> aliveBodies, {
    required bool denseScene,
  }) {
    if (aliveBodies.isEmpty) {
      return;
    }

    final sampledBodies = denseScene && aliveBodies.length > 320
        ? <SimulationBody>[
            for (
              var i = 0;
              i < aliveBodies.length;
              i += (aliveBodies.length / 320).ceil()
            )
              aliveBodies[i],
          ]
        : aliveBodies;

    final cols = math.max(8, renderOptions.fieldSamples * 3);
    final rows = math.max(6, (cols * size.height / size.width).round());
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;
    final values = List<double>.filled(cols * rows, 0);
    var maxField = 0.0;

    final epsilon2 = config.softeningEpsilon * config.softeningEpsilon;
    var index = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final sampleScreen = Offset(
          (x + 0.5) * cellWidth,
          (y + 0.5) * cellHeight,
        );
        final sampleWorld = transform.screenToWorld(sampleScreen);
        var field = 0.0;
        for (final body in sampledBodies) {
          final delta = body.position - sampleWorld;
          final distSq = delta.normSquared + epsilon2;
          if (distSq > 0) {
            field += (config.gravityConstant * body.mass) / distSq;
          }
        }

        values[index] = field;
        if (field > maxField) {
          maxField = field;
        }
        index++;
      }
    }

    if (maxField <= 0) {
      return;
    }

    index = 0;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final normalized = (values[index] / maxField).clamp(0.0, 1.0);
        final eased = math.sqrt(normalized);
        final color = Color.lerp(
          Colors.transparent,
          visualTheme.fieldOverlayColor,
          eased,
        );
        if (color != null) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
            Paint()..color = color,
          );
        }
        index++;
      }
    }
  }

  void _drawLensingOverlay(Canvas canvas, List<SimulationBody> aliveBodies) {
    for (final body in aliveBodies.where((item) => item.mass > 20)) {
      final center = transform.worldToScreen(body.position);
      final baseRadius = math.max(8.0, body.radius * transform.scale * 1.8);
      final ringRadius = baseRadius * (1.4 + math.log(body.mass) / 5);

      final ring = RadialGradient(
        colors: [
          Colors.transparent,
          visualTheme.lensingColor,
          Colors.transparent,
        ],
        stops: const [0.45, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: ringRadius));

      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..shader = ring
          ..blendMode = BlendMode.screen,
      );
    }
  }

  double _gridSpacing() {
    final worldStep = _niceNumber(80 / transform.scale);
    return math.max(16, worldStep * transform.scale);
  }

  static double _niceNumber(double value) {
    final exponent = math.pow(10, (math.log(value) / math.ln10).floor());
    final fraction = value / exponent;
    double niceFraction;
    if (fraction < 1.5) {
      niceFraction = 1;
    } else if (fraction < 3) {
      niceFraction = 2;
    } else if (fraction < 7) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }
    return niceFraction * exponent;
  }

  @override
  bool shouldRepaint(covariant _SimulationPainter oldDelegate) {
    return oldDelegate.bodies != bodies ||
        oldDelegate.config != config ||
        oldDelegate.visualTheme != visualTheme ||
        oldDelegate.trails != trails ||
        oldDelegate.renderOptions != renderOptions ||
        oldDelegate.selectedBodyId != selectedBodyId ||
        oldDelegate.transform != transform;
  }
}

class _WorldTransform {
  const _WorldTransform({required this.scale, required this.offset});

  final double scale;
  final Offset offset;

  Offset worldToScreen(Vec2 world) {
    return Offset((world.x * scale) + offset.dx, offset.dy - (world.y * scale));
  }

  Vec2 screenToWorld(Offset screen) {
    return Vec2(
      (screen.dx - offset.dx) / scale,
      (offset.dy - screen.dy) / scale,
    );
  }

  Vec2 screenDeltaToWorld(Offset delta) {
    return Vec2(delta.dx / scale, -delta.dy / scale);
  }

  static _WorldTransform forView({
    required List<SimulationBody> bodies,
    required Size size,
    required CameraMode cameraMode,
    required Vec2 cameraCenter,
    required double cameraZoom,
    required String? selectedBodyId,
    required double padding,
  }) {
    if (cameraMode == CameraMode.fit) {
      return _fitToBodies(bodies: bodies, size: size, padding: padding);
    }

    final selectedBody = selectedBodyId == null
        ? null
        : bodies.cast<SimulationBody?>().firstWhere(
            (body) => body?.id == selectedBodyId,
            orElse: () => null,
          );

    final worldCenter =
        cameraMode == CameraMode.followSelected && selectedBody != null
        ? selectedBody.position
        : cameraCenter;

    final baseScale = (math.min(size.width, size.height) / 220).clamp(
      0.2,
      12.0,
    );
    final scale = (baseScale * cameraZoom).clamp(0.05, 80.0);
    return _WorldTransform(
      scale: scale,
      offset: Offset(
        (size.width * 0.5) - (worldCenter.x * scale),
        (size.height * 0.5) + (worldCenter.y * scale),
      ),
    );
  }

  static _WorldTransform _fitToBodies({
    required List<SimulationBody> bodies,
    required Size size,
    required double padding,
  }) {
    if (bodies.where((body) => body.alive).isEmpty) {
      final fallbackScale = math.min(size.width, size.height) / 200;
      return _WorldTransform(
        scale: fallbackScale,
        offset: Offset(size.width / 2, size.height / 2),
      );
    }

    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;

    for (final body in bodies.where((body) => body.alive)) {
      minX = math.min(minX, body.position.x - body.radius);
      maxX = math.max(maxX, body.position.x + body.radius);
      minY = math.min(minY, body.position.y - body.radius);
      maxY = math.max(maxY, body.position.y + body.radius);
    }

    final worldWidth = math.max(maxX - minX, 1);
    final worldHeight = math.max(maxY - minY, 1);
    final scaleX = (size.width - (padding * 2)) / worldWidth;
    final scaleY = (size.height - (padding * 2)) / worldHeight;
    final scale = math.max(math.min(scaleX, scaleY), 0.001);

    final centerX = (minX + maxX) * 0.5;
    final centerY = (minY + maxY) * 0.5;

    return _WorldTransform(
      scale: scale,
      offset: Offset(
        (size.width * 0.5) - (centerX * scale),
        (size.height * 0.5) + (centerY * scale),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _WorldTransform &&
        other.scale == scale &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(scale, offset);
}
