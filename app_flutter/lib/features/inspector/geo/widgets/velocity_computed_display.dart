import 'package:flutter/material.dart';

/// Read-only display of computed speed and heading from velocity components.
///
/// Shows "Speed: X.XX m/s" and "Heading: YY.Y°" when valid. When [undefined]
/// is true, displays "Heading: undefined".
///
/// @realizes UML::VelocityComputedDisplay
class VelocityComputedDisplay extends StatelessWidget {
  final double? speed;
  final double? headingDegrees;
  final bool undefined;

  const VelocityComputedDisplay({
    super.key,
    this.speed,
    this.headingDegrees,
    this.undefined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speed: ${speed != null ? '${speed!.toStringAsFixed(2)} m/s' : '--'}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            'Heading: ${undefined ? 'undefined' : headingDegrees != null ? '${headingDegrees!.toStringAsFixed(1)}°' : '--'}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
