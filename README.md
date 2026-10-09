# nbody_sim_flutter

Flutter UI widgets, camera controls, and visual themes for rendering 2D simulations with `nbody_sim_core`.

## Features
1. `SimulationCanvas` for interactive 2D N-body rendering.
2. `CameraControls` for quick fit/zoom actions.
3. `SimulatorVisualTheme` and `buildSimulatorTheme(...)` for visual tokens.

## Install

```yaml
dependencies:
  nbody_sim_flutter: ^0.1.4
  nbody_sim_core: ^0.1.4
```

## What This Package Owns

1. Canvas rendering and gestures.
2. Camera interaction plumbing (tap select, pan, zoom, drag selected body).
3. Visual theme tokens and default Material theme setup.

## What This Package Does Not Own

1. Physics engine execution (owned by `nbody_sim_core`).
2. App workflows (play/pause/reset, scenario import/export panels, inspector forms).
3. Product-specific layout/routes.

## Quick Start

```dart
import 'package:nbody_sim_flutter/nbody_sim_flutter.dart';
import 'package:nbody_sim_core/models.dart';

SimulationCanvas(
  bodies: const [],
  config: SimulationConfig.scientificDefault,
  selectedBodyId: null,
  cameraMode: CameraMode.fit,
  cameraCenter: Vec2.zero,
  cameraZoom: 1,
  visualTheme: SimulatorVisualTheme.fromColorScheme(
    Theme.of(context).colorScheme,
  ),
  renderOptions: const RenderOptions(),
  trails: const {},
  onSelectBody: (_) {},
  onPanCamera: (_) {},
  onZoomCamera: (_) {},
  onMoveSelectedBody: (_) {},
);
```

## Full Integration Pattern

Typical pattern:
1. Run physics using `SimulationEngine` from `nbody_sim_core`.
2. Hold state in your own controller/bloc/provider.
3. Feed state into `SimulationCanvas`.
4. Wire callbacks back into your controller (`select`, `pan`, `zoom`, `move selected body`).

## Theme Integration

```dart
MaterialApp(
  theme: buildSimulatorTheme(Brightness.light),
  darkTheme: buildSimulatorTheme(Brightness.dark),
  themeMode: ThemeMode.system,
  home: const YourSimulationPage(),
);
```

## Theme Configuration

You can fully configure visuals in two ways:

1. Build directly from your app `ColorScheme`:

```dart
final visualTheme = SimulatorVisualTheme.fromColorScheme(
  Theme.of(context).colorScheme,
);
```

2. Override specific tokens:

```dart
final customVisualTheme = SimulatorVisualTheme.fromColorScheme(
  Theme.of(context).colorScheme,
).copyWith(
  gridColor: Colors.white.withValues(alpha: 0.12),
  vectorColor: Colors.cyanAccent.withValues(alpha: 0.45),
);
```

Token groups available on `SimulatorVisualTheme`:
1. Canvas gradients (`canvasGradientStart`, `canvasGradientMid`, `canvasGradientEnd`)
2. Panel/chip colors (`hudSurface`, `hudBorder`, `hudChipSurface`, `hudChipBorder`, `hudOnChip`)
3. Simulation overlays (`gridColor`, `vectorColor`, `selectionColor`, `fieldOverlayColor`, `lensingColor`)

## Camera Controls Example

```dart
CameraControls(
  onFit: fitCamera,
  onZoomIn: () => zoomBy(1.1),
  onZoomOut: () => zoomBy(0.9),
);
```

## Camera Mode Semantics

`SimulationCanvas` supports these modes from `nbody_sim_core`:
1. `CameraMode.fit`
   - Auto-fits alive bodies in view.
   - Ignores manual `cameraCenter`/`cameraZoom` while active.
2. `CameraMode.free`
   - Uses your `cameraCenter` and `cameraZoom`.
   - Intended for user-driven panning/zooming.
3. `CameraMode.followSelected`
   - Tracks the currently selected body when available.
   - Falls back to `cameraCenter` when no selected body exists.

## Interaction Contract of `SimulationCanvas`

`SimulationCanvas` expects:
1. `bodies`, `config`, `renderOptions`, camera state, trails, visual theme.
2. Selection and camera callbacks:
   - `onSelectBody(String? id)`
   - `onPanCamera(Vec2 delta)`
   - `onZoomCamera(double factor)`
   - `onMoveSelectedBody(Vec2 worldPosition)`

Built-in behavior:
1. Tap near body => selects nearest body.
2. Wheel/pinch => emits zoom factors.
3. Drag empty space => emits pan deltas.
4. Drag selected body => emits world position updates.

State ownership note:
1. `SimulationCanvas` emits interaction intents; your app owns state/engine.
2. You can use any state management approach (`ChangeNotifier`, Riverpod, Bloc, etc.).
3. The package does not require `setState`; rebuild strategy is host-app choice.

## Engine Tick Loop Integration (`nbody_sim_core`)

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nbody_sim_core/engine.dart';
import 'package:nbody_sim_core/models.dart';

class SimulationRuntime extends ChangeNotifier {
  SimulationRuntime({
    SimulationEngine? engine,
    this.ticksPerFrame = 1,
  }) : _engine = engine ?? IsolateSimulationEngine();

  final SimulationEngine _engine;
  final int ticksPerFrame;
  Timer? _timer;
  bool _isStepping = false;

  List<SimulationBody> bodies = const [];
  String? selectedId;
  Vec2 cameraCenter = Vec2.zero;
  double cameraZoom = 1;
  CameraMode cameraMode = CameraMode.fit;
  RenderOptions renderOptions = const RenderOptions();
  final Map<String, List<Vec2>> trails = <String, List<Vec2>>{};

  Future<void> initialize(List<SimulationBody> initialBodies) async {
    await _engine.initialize(
      config: SimulationConfig.scientificDefault,
      bodies: initialBodies,
    );
    bodies = _engine.getState().bodies;
    _appendTrailPoints();
    notifyListeners();
  }

  void start() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 16), (_) async {
      if (_isStepping) {
        return;
      }
      _isStepping = true;
      try {
        await _engine.step(ticksPerFrame);
        bodies = _engine.getState().bodies;
        _appendTrailPoints();
        notifyListeners();
      } finally {
        _isStepping = false;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> disposeRuntime() async {
    stop();
    await _engine.dispose();
  }

  void _appendTrailPoints() {
    final maxPoints = renderOptions.trailLength;
    for (final body in bodies.where((b) => b.alive)) {
      final history = trails.putIfAbsent(body.id, () => <Vec2>[]);
      history.add(body.position);
      if (history.length > maxPoints) {
        history.removeRange(0, history.length - maxPoints);
      }
    }
  }
}
```

## Minimal Listenable Example (Recommended)

```dart
class SimulationViewModel extends ChangeNotifier {
  String? selectedId;
  Vec2 cameraCenter = Vec2.zero;
  double cameraZoom = 1;
  List<SimulationBody> bodies = const [];

  void selectBody(String? id) {
    selectedId = id;
    notifyListeners();
  }

  void pan(Vec2 delta) {
    cameraCenter = Vec2(cameraCenter.x + delta.x, cameraCenter.y + delta.y);
    notifyListeners();
  }

  void zoom(double factor) {
    cameraZoom = (cameraZoom * factor).clamp(0.1, 50.0);
    notifyListeners();
  }
}

class DemoPage extends StatelessWidget {
  DemoPage({super.key});

  final model = SimulationViewModel();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model,
      builder: (_, __) => SimulationCanvas(
        bodies: model.bodies,
        config: SimulationConfig.scientificDefault,
        selectedBodyId: model.selectedId,
        cameraMode: CameraMode.fit,
        cameraCenter: model.cameraCenter,
        cameraZoom: model.cameraZoom,
        visualTheme: SimulatorVisualTheme.fromColorScheme(
          Theme.of(context).colorScheme,
        ),
        renderOptions: const RenderOptions(),
        trails: const {},
        onSelectBody: model.selectBody,
        onPanCamera: model.pan,
        onZoomCamera: model.zoom,
        onMoveSelectedBody: (world) {
          // forward to your engine/controller edit pipeline
        },
      ),
    );
  }
}
```

## Notes
1. This package focuses on reusable rendering/theme primitives only.
2. Physics state and engine control come from `nbody_sim_core`.

## Performance Notes

1. The canvas paint surface is wrapped with `RepaintBoundary` to isolate heavy
   repaints from surrounding controls/layout.
2. For dense scenes, keep overlay options selective (`showFieldOverlay`,
   `showLensingOverlay`, `showVelocityVectors`) when targeting mobile devices.

## Trail Lifecycle Guidance

1. Cap trail history per body (for example, `renderOptions.trailLength`).
2. Remove trail entries for deleted bodies to avoid stale memory use.
3. Lower trail length and/or quality on low-end devices for smoother panning.

## Troubleshooting

1. Canvas looks static:
   - Ensure your app is ticking physics and feeding updated `bodies`.
2. Selection feels off:
   - Verify camera state (`cameraCenter`, `cameraZoom`) is updated consistently from callbacks.
3. Colors look wrong:
   - Pass your own `SimulatorVisualTheme` instead of default derived values.
