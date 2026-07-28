import 'package:flutter/material.dart';

/// Two radio buttons for selecting the coordinate representation mode.
///
/// Supports 'ellipsoid' and 'cartesian' modes. Only one is active at a time.
/// The [onChanged] callback receives the newly selected mode string.
///
/// @realizes UML::CoordinateChoiceToggle
class CoordinateChoiceToggle extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;

  const CoordinateChoiceToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Radio<String>(
            value: 'ellipsoid',
            groupValue: mode,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            visualDensity: VisualDensity.compact,
          ),
          GestureDetector(
            onTap: () => onChanged('ellipsoid'),
            child: const Text('Ellipsoid', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 24),
          Radio<String>(
            value: 'cartesian',
            groupValue: mode,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            visualDensity: VisualDensity.compact,
          ),
          GestureDetector(
            onTap: () => onChanged('cartesian'),
            child: const Text('Cartesian', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
