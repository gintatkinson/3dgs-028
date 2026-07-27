/// Ellipsoid (latitude/longitude/height) coordinates as defined in
/// RFC 9179 under the `ietf-geo-location:geo-location/location/ellipsoid`
/// YANG choice case container.
///
/// The ellipsoid coordinate system is mutually exclusive with the
/// Cartesian coordinate system — a given location MUST NOT contain
/// both an ellipsoid and a Cartesian coordinate set simultaneously.
/// This mutual exclusion is enforced by the YANG `choice` construct
/// and must be respected by application code.
///
/// ### Field semantics
///
/// - [latitude]: WGS-84 ellipsoidal latitude in degrees. Range [-90, 90]
///   for Earth. Decimal64 with up to 16 fraction digits. Optional.
/// - [longitude]: WGS-84 ellipsoidal longitude in degrees. Range
///   [-180, 180] for Earth. Decimal64 with up to 16 fraction digits.
///   Optional.
/// - [height]: Ellipsoidal height above the reference geoid in meters.
///   Decimal64 with up to 6 fraction digits. Optional — when absent,
///   no height information is available.
///
/// All fields are optional per the YANG schema; absent fields are
/// simply not serialized.
///
/// {@macro rfc9179_section_2_3}
///
/// @realizes UML::EllipsoidCoordinates
/// @realizes UML::EllipsoidCoordinates::latitude
/// @realizes UML::EllipsoidCoordinates::longitude
/// @realizes UML::EllipsoidCoordinates::height
class EllipsoidCoordinates {
  /// WGS-84 ellipsoidal latitude in degrees.
  ///
  /// Range is [-90, 90] for Earth contexts. Decimal64 with up to 16
  /// fraction digits. Optional — when absent, the latitude is not
  /// specified.
  final double? latitude;

  /// WGS-84 ellipsoidal longitude in degrees.
  ///
  /// Range is [-180, 180] for Earth contexts. Decimal64 with up to 16
  /// fraction digits. Optional — when absent, the longitude is not
  /// specified.
  final double? longitude;

  /// Ellipsoidal height above the reference geoid in meters.
  ///
  /// Decimal64 with up to 6 fraction digits. Optional — when absent,
  /// no height information is available. Can be negative for points
  /// below the reference geoid.
  final double? height;

  /// Creates a new [EllipsoidCoordinates] instance.
  ///
  /// All fields are optional, conforming to the YANG schema where
  /// no leaf in the ellipsoid container is mandatory.
  ///
  /// @param latitude Ellipsoidal latitude in degrees (optional).
  /// @param longitude Ellipsoidal longitude in degrees (optional).
  /// @param height Ellipsoidal height in meters (optional).
  const EllipsoidCoordinates({
    this.latitude,
    this.longitude,
    this.height,
  });

  /// Whether the coordinate context is Earth.
  ///
  /// Defaults to `true` — the vast majority of geo-location use cases
  /// are Earth-referenced. When [another body is the reference
  /// frame](ReferenceFrame.astronomicalBody), the caller should pass
  /// an explicit `isOnEarth` value rather than relying on this default.
  ///
  /// Returns `true` in the default context, meaning coordinate range
  /// validation should use Earth-appropriate bounds.
  bool get isOnEarth => true;

  /// Whether the coordinate values fall within Earth-appropriate ranges.
  ///
  /// Checks [latitude] against [-90, 90] and [longitude] against
  /// [-180, 180]. Null values are considered in-range — only present
  /// values are validated. [height] has no Earth-specific range
  /// constraint (the geoid surface is 0 but tower/mountain/depth
  /// values range far both positive and negative).
  ///
  /// Returns `true` when all present coordinate values are within
  /// their respective Earth ranges. Returns `false` when any
  /// present latitude or longitude falls outside its valid range.
  ///
  /// @realizes UML::EllipsoidCoordinates::isWithinEarthRange
  bool get isWithinEarthRange {
    if (latitude != null && (latitude! < -90 || latitude! > 90)) {
      return false;
    }
    if (longitude != null && (longitude! < -180 || longitude! > 180)) {
      return false;
    }
    return true;
  }

  /// Constructs an [EllipsoidCoordinates] from a raw key-value
  /// database map.
  ///
  /// Field names use snake_case (`latitude`, `longitude`, `height`)
  /// matching the YANG leaf names as stored in the database's
  /// `data_json` column.
  ///
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [EllipsoidCoordinates] with all parsed fields.
  factory EllipsoidCoordinates.fromMap(Map<String, dynamic> map) {
    return EllipsoidCoordinates(
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      height: map['height'] as double?,
    );
  }

  /// Serializes this [EllipsoidCoordinates] to a map for JSON encoding.
  ///
  /// Only non-null fields are included in the output, matching YANG
  /// schema conventions where absent leaves are simply not present
  /// rather than null-valued.
  ///
  /// @returns A map with snake_case keys matching the database column
  ///          names.
  Map<String, dynamic> toMap() {
    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (height != null) 'height': height,
    };
  }
}
