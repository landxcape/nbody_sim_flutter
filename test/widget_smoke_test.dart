import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nbody_sim_core/models.dart';
import 'package:nbody_sim_flutter/nbody_sim_flutter.dart';

void main() {
  testWidgets('simulation canvas builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SimulationCanvas(
          bodies: const [],
          config: SimulationConfig.scientificDefault,
          selectedBodyId: null,
          cameraMode: CameraMode.fit,
          cameraCenter: Vec2.zero,
          cameraZoom: 1,
          visualTheme: SimulatorVisualTheme.fromColorScheme(
            const ColorScheme.light(),
          ),
          renderOptions: const RenderOptions(),
          trails: const {},
          onSelectBody: (_) {},
          onPanCamera: (_) {},
          onZoomCamera: (_) {},
          onMoveSelectedBody: (_) {},
        ),
      ),
    );

    expect(find.byType(SimulationCanvas), findsOneWidget);
  });
}
