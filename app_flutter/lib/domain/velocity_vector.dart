import 'dart:math' as math;

/// Velocity vector container in m/s as defined in RFC 9179 under the
/// `ietf-geo-location:geo-location/velocity` YANG container.
///
/// Velocity is expressed in three orthogonal components oriented with
/// the north-east-up (NEU) coordinate system relative to the WGS-84
/// ellipsoid at the device's position:
///
/// - [vNorth]: Northward velocity component. Decimal64 with 12 fraction
///   digits. Optional.
/// - [vEast]: Eastward velocity component. Decimal64 with 12 fraction
///   digits. Optional.
/// - [vUp]: Upward velocity component. Decimal64 with 12 fraction
///   digits. Optional.
///
/// All fields are optional per the YANG schema. The container provides
/// derived computed values [speed] and [heading] which are NOT stored in
/// the database — they are computed on-the-fly from [vNorth] and [vEast].
///
/// ### Edge cases for heading
///
/// - Both vNorth and vEast are 0 → heading is undefined (returns `null`).
/// - vNorth = 0, vEast > 0 → heading = 90°.
/// - vNorth = 0, vEast < 0 → heading = 270°.
///
/// {@macro rfc9179_section_2_3}
///
/// @realizes UML::VelocityVector
/// @realizes UML::VelocityVector::vNorth
/// @realizes UML::VelocityVector::vEast
/// @realizes UML::VelocityVector::vUp
class VelocityVector {
  /// Northward velocity component in m/s.
  ///
  /// Decimal64 with up to 12 fraction digits. Optional.
  final double? vNorth;

  /// Eastward velocity component in m/s.
  ///
  /// Decimal64 with up to 12 fraction digits. Optional.
  final double? vEast;

  /// Upward (vertical) velocity component in m/s.
  ///
  /// Decimal64 with up to 12 fraction digits. Optional.
  final double? vUp;

  /// Creates a new [VelocityVector] instance.
  ///
  /// All fields are optional, conforming to the YANG schema where
  /// no leaf in the velocity container is mandatory.
  const VelocityVector({
    this.vNorth,
    this.vEast,
    this.vUp,
  });

  /// Computes the horizontal speed from the north and east components.
  ///
  /// Speed is the magnitude of the horizontal velocity vector:
  /// `sqrt(vNorth² + vEast²)`. Returns `null` when either [vNorth] or
  /// [vEast] is `null` — both components are required for a meaningful
  /// horizontal speed calculation.
  ///
  /// This is a derived value and is NOT stored in the database.
  ///
  /// @realizes UML::VelocityVector::computeSpeed
  double? computeSpeed() {
    if (vNorth == null || vEast == null) return null;
    return math.sqrt(vNorth! * vNorth! + vEast! * vEast!);
  }

  /// Computes the direction of horizontal motion in radians.
  ///
  /// Heading is the angle from true north measured clockwise: 0 = north,
  /// π/2 = east, π = south, 3π/2 = west. Uses [math.atan2] on
  /// (vEast, vNorth) to correctly handle all quadrants.
  ///
  /// Returns `null` when either [vNorth] or [vEast] is `null`, or when
  /// both are zero (division-by-zero undefined).
  ///
  /// @realizes UML::VelocityVector::computeHeading
  double? computeHeading() {
    if (vNorth == null || vEast == null) return null;
    if (vNorth! == 0.0 && vEast! == 0.0) return null;
    return math.atan2(vEast!, vNorth!);
  }

  /// Computes the direction of horizontal motion in degrees.
  ///
  /// Converts [computeHeading] from radians to degrees using
  /// `radians * 180 / π`. Result is in [0, 360) range — negative
  /// radians are automatically wrapped by `atan2` returning positive
  /// angles for the north-east-up frame.
  ///
  /// Returns `null` when heading is undefined (see [computeHeading]).
  ///
  /// @realizes UML::VelocityVector::computeHeadingDegrees
  double? computeHeadingDegrees() {
    final heading = computeHeading();
    if (heading == null) return null;
    var degrees = heading * 180.0 / math.pi;
    if (degrees < 0) degrees += 360.0;
    return degrees;
  }

  /// Constructs a [VelocityVector] from a raw key-value database map.
  ///
  /// Field names use snake_case (`v_north`, `v_east`, `v_up`) matching
  /// the YANG leaf names as stored in the database's `data_json` column.
  ///
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [VelocityVector] with all parsed fields.
  factory VelocityVector.fromMap(Map<String, dynamic> map) {
    return VelocityVector(
      vNorth: map['v_north'] as double?,
      vEast: map['v_east'] as double?,
      vUp: map['v_up'] as double?,
    );
  }

  /// Serializes this [VelocityVector] to a map for JSON encoding.
  ///
  /// Only non-null fields are included in the output, matching YANG
  /// schema conventions where absent leaves are simply not present
  /// rather than null-valued. Derived values (speed, heading) are
  /// intentionally excluded — they are computed, not stored.
  ///
  /// @returns A map with snake_case keys matching the database column names.
  Map<String, dynamic> toMap() {
    return {
      if (vNorth != null) 'v_north': vNorth,
      if (vEast != null) 'v_east': vEast,
      if (vUp != null) 'v_up': vUp,
    };
  }
}
