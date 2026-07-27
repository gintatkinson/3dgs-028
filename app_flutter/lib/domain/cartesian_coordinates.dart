import 'package:app_flutter/domain/geo_location_service.dart';

/// Cartesian (X/Y/Z) coordinates as defined in RFC 9179 under the
/// `ietf-geo-location:geo-location/location/cartesian` YANG choice
/// case container.
///
/// The Cartesian coordinate system is mutually exclusive with the
/// Ellipsoidal coordinate system — a given location MUST NOT contain
/// both a Cartesian and an ellipsoidal coordinate set simultaneously.
/// This mutual exclusion is enforced by the YANG `choice` construct
/// and must be respected by application code.
///
/// ### Field semantics
///
/// - [x]: X-coordinate in meters. Decimal64 with up to 6 fraction
///   digits. Optional.
/// - [y]: Y-coordinate in meters. Decimal64 with up to 6 fraction
///   digits. Optional.
/// - [z]: Z-coordinate in meters. Decimal64 with up to 6 fraction
///   digits. Optional.
///
/// All fields are optional per the YANG schema; absent fields are
/// simply not serialized.
///
/// height-accuracy from the GeodeticSystem container is NOT used
/// with Cartesian coordinates per the RFC specification.
///
/// {@macro rfc9179_section_2_3}
///
/// @realizes UML::CartesianCoordinates
/// @realizes UML::CartesianCoordinates::x
/// @realizes UML::CartesianCoordinates::y
/// @realizes UML::CartesianCoordinates::z
class CartesianCoordinates {
  /// X-coordinate in meters.
  ///
  /// Decimal64 with up to 6 fraction digits. Optional — when absent,
  /// the X-coordinate is not specified.
  final double? x;

  /// Y-coordinate in meters.
  ///
  /// Decimal64 with up to 6 fraction digits. Optional — when absent,
  /// the Y-coordinate is not specified.
  final double? y;

  /// Z-coordinate in meters.
  ///
  /// Decimal64 with up to 6 fraction digits. Optional — when absent,
  /// the Z-coordinate is not specified.
  final double? z;

  /// Creates a new [CartesianCoordinates] instance.
  ///
  /// All fields are optional, conforming to the YANG schema where
  /// no leaf in the cartesian container is mandatory.
  ///
  /// @param x Cartesian X-coordinate in meters (optional).
  /// @param y Cartesian Y-coordinate in meters (optional).
  /// @param z Cartesian Z-coordinate in meters (optional).
  const CartesianCoordinates({
    this.x,
    this.y,
    this.z,
  });

  /// Whether all three coordinate fields are present (non-null).
  ///
  /// A complete Cartesian coordinate requires all three axes (X, Y, Z)
  /// to meaningfully position a point in 3D space. Partial coordinates
  /// are valid per schema but cannot be used for spatial positioning.
  ///
  /// @realizes UML::CartesianCoordinates::isComplete
  bool get isComplete => x != null && y != null && z != null;

  /// Returns a new [CartesianCoordinates] with all present values
  /// rounded to the specified number of fraction digits.
  ///
  /// Null fields are preserved as null — rounding is only applied
  /// to present (non-null) coordinate values. Delegates to
  /// [GeoLocationService.roundDecimal64] for the actual rounding.
  ///
  /// For Cartesian coordinates per RFC 9179, use `fractionDigits = 6`
  /// (decimal64 with 6 fraction digits for each axis).
  ///
  /// @param fractionDigits The number of decimal places to retain.
  /// @returns A new [CartesianCoordinates] with rounded values.
  CartesianCoordinates roundToFracDigits(int fractionDigits) {
    return CartesianCoordinates(
      x: x != null
          ? GeoLocationService.roundDecimal64(x!, fractionDigits)
          : null,
      y: y != null
          ? GeoLocationService.roundDecimal64(y!, fractionDigits)
          : null,
      z: z != null
          ? GeoLocationService.roundDecimal64(z!, fractionDigits)
          : null,
    );
  }

  /// Constructs a [CartesianCoordinates] from a raw key-value
  /// database map.
  ///
  /// Field names use snake_case (`x`, `y`, `z`) matching the
  /// YANG leaf names as stored in the database's `data_json` column.
  ///
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [CartesianCoordinates] with all parsed fields.
  factory CartesianCoordinates.fromMap(Map<String, dynamic> map) {
    return CartesianCoordinates(
      x: map['x'] as double?,
      y: map['y'] as double?,
      z: map['z'] as double?,
    );
  }

  /// Serializes this [CartesianCoordinates] to a map for JSON encoding.
  ///
  /// Only non-null fields are included in the output, matching YANG
  /// schema conventions where absent leaves are simply not present
  /// rather than null-valued.
  ///
  /// @returns A map with snake_case keys matching the database column
  ///          names.
  Map<String, dynamic> toMap() {
    return {
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (z != null) 'z': z,
    };
  }
}
