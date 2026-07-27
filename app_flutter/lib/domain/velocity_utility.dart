import 'dart:math' as math;

/// Pure stateless computation utilities for velocity vector derived
/// values (speed and heading).
///
/// All methods are static — this class is a pure function collection
/// with no mutable state, no side effects, and no external dependencies.
/// It exists to allow callers to compute speed/heading from raw numeric
/// values without constructing a full [VelocityVector] instance.
///
/// ### Edge cases
///
/// - Both components zero → heading is undefined, [computeHeadingDegrees]
///   returns `null`.
/// - One component zero → heading is 90° (vNorth=0, vEast>0) or
///   270° (vNorth=0, vEast<0) as specified.
/// - Null inputs → both methods return `null`.
///
/// @realizes UML::VelocityUtility
class VelocityUtility {
  /// Computes horizontal speed from north and east velocity components.
  ///
  /// `speed = sqrt(vNorth² + vEast²)`. Returns `null` when either
  /// component is `null` — both are required for meaningful speed.
  ///
  /// @param vNorth Northward velocity component (m/s).
  /// @param vEast Eastward velocity component (m/s).
  /// @returns Speed in m/s, or `null` if either input is `null`.
  ///
  /// @realizes UML::VelocityUtility::computeSpeed
  static double? computeSpeed(double? vNorth, double? vEast) {
    if (vNorth == null || vEast == null) return null;
    return math.sqrt(vNorth * vNorth + vEast * vEast);
  }

  /// Computes the direction of horizontal motion in degrees [0, 360).
  ///
  /// Heading is the clockwise angle from true north (0° = north,
  /// 90° = east, 180° = south, 270° = west). Uses `atan2(vEast, vNorth)`
  /// internally to correctly handle all four quadrants.
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` when either component is `null`.
  /// - Returns `null` when both components are zero (division-by-zero,
  ///   heading is undefined).
  /// - Returns 90° when vNorth=0 and vEast>0.
  /// - Returns 270° when vNorth=0 and vEast<0.
  ///
  /// @param vNorth Northward velocity component (m/s).
  /// @param vEast Eastward velocity component (m/s).
  /// @returns Heading in degrees [0, 360), or `null` if undefined.
  ///
  /// @realizes UML::VelocityUtility::computeHeadingDegrees
  static double? computeHeadingDegrees(double? vNorth, double? vEast) {
    if (vNorth == null || vEast == null) return null;
    if (vNorth == 0.0 && vEast == 0.0) return null;
    final radians = math.atan2(vEast, vNorth);
    var degrees = radians * 180.0 / math.pi;
    if (degrees < 0) degrees += 360.0;
    return degrees;
  }
}
