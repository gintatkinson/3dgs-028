import 'package:flutter/material.dart';

/// Visual badge showing dispatch readiness status.
///
/// Maps a [status] string to a color and label pair:
/// - 'ready'       → green background, "READY FOR DISPATCH"
/// - 'incomplete'  → orange background, "INCOMPLETE"
/// - 'stale'       → red background, "STALE"
/// - anything else → grey background, "UNKNOWN"
///
/// Used inline in the NI location tree and detail panels.
///
/// @realizes UML::DispatchBadge
class DispatchBadge extends StatelessWidget {
  final String status;

  const DispatchBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'ready':
        return Colors.green;
      case 'incomplete':
        return Colors.orange;
      case 'stale':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case 'ready':
        return 'READY FOR DISPATCH';
      case 'incomplete':
        return 'INCOMPLETE';
      case 'stale':
        return 'STALE';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
