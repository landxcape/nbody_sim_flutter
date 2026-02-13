import 'package:flutter/material.dart';

/// Compact camera action controls for simulation UIs.
class CameraControls extends StatelessWidget {
  /// Creates camera controls.
  const CameraControls({
    super.key,
    required this.onFit,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  /// Invoked when the user requests a fit-to-content view.
  final VoidCallback onFit;

  /// Invoked when the user requests zoom-in.
  final VoidCallback onZoomIn;

  /// Invoked when the user requests zoom-out.
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onFit,
          icon: const Icon(Icons.center_focus_strong),
          label: const Text('Fit'),
        ),
        IconButton(onPressed: onZoomIn, icon: const Icon(Icons.zoom_in)),
        IconButton(onPressed: onZoomOut, icon: const Icon(Icons.zoom_out)),
      ],
    );
  }
}
