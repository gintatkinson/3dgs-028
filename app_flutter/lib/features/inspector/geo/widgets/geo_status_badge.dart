import 'package:flutter/material.dart';

/// Shows the temporal status of a geo-location record.
///
/// Displays one of four states:
/// - **Fresh** (green): has a timestamp and has not expired.
/// - **No Temp Context** (grey): no timestamp present.
/// - **Expired** (red): valid-until is in the past.
/// - **No Valid Until** (grey): has timestamp but no expiry set.
///
/// @realizes UML::GeoStatusBadge
class GeoStatusBadge extends StatelessWidget {
  final bool isExpired;
  final bool hasTemporalContext;
  final bool hasValidUntil;

  const GeoStatusBadge({
    super.key,
    required this.isExpired,
    required this.hasTemporalContext,
    required this.hasValidUntil,
  });

  @override
  Widget build(BuildContext context) {
    if (isExpired) {
      return _badge('Expired', Colors.red);
    }
    if (!hasTemporalContext) {
      return _badge('No Temp Context', Colors.grey);
    }
    if (!hasValidUntil) {
      return _badge('No Valid Until', Colors.grey);
    }
    return _badge('Fresh', Colors.green);
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
