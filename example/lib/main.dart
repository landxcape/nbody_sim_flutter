import 'package:flutter/material.dart';
import 'package:nbody_sim_core/models.dart';
import 'package:nbody_sim_flutter/nbody_sim_flutter.dart';

void main() {
  runApp(const MaterialApp(home: _Example()));
}

class _Example extends StatelessWidget {
  const _Example();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SimulationCanvas(
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
      ),
    );
  }
}
