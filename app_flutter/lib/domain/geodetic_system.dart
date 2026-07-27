/// Defines the geodetic reference system used for coordinate interpretation,
/// as specified in RFC 9179 under the `ietf-geo-location:geo-location/
/// reference-frame/geodetic-system` schema container.
///
/// The geodetic system specifies which datum defines the coordinate
/// origin and axis orientation. This enables precise coordinate
/// conversion between different mapping systems.
///
/// ### Field semantics
///
/// - [geodeticDatum]: The IANA-registered geodetic datum name. Default
///   is `"wgs-84"` for Earth contexts. Lunar contexts use `"me"`.
///   Must match the pattern `[ -@\\[-\^_-~]*` (lowercase, spaces
///   normalized to dashes per IANA conventions).
/// - [coordAccuracy]: Horizontal coordinate accuracy in meters
///   (decimal64 with 6 fraction digits). Optional (unitless, implied
///   meters). Must be non-negative. Not applicable in Cartesian
///   coordinate contexts.
/// - [heightAccuracy]: Vertical accuracy in meters (decimal64 with 6
///   fraction digits, unit "meters"). Optional, must be non-negative.
///   Not used with Cartesian coordinate systems.
///
/// All fields are optional per the YANG schema; absent fields are
/// simply not serialized.
///
/// @realizes UML::GeodeticSystem
/// @realizes UML::GeodeticSystem::geodeticDatum
/// @realizes UML::GeodeticSystem::coordAccuracy
/// @realizes UML::GeodeticSystem::heightAccuracy
class GeodeticSystem {
  /// The IANA-registered geodetic datum name (e.g., `"wgs-84"`, `"me"`).
  ///
  /// When [isEarth] is true and no explicit datum is provided, defaults
  /// to `"wgs-84"`. The value is always stored in IANA-normalized form
  /// (lowercase, spaces replaced with dashes). Must match pattern
  /// `[ -@\\[-\^_-~]*` — same character set as astronomical body names.
  final String? geodeticDatum;

  /// Horizontal (2D) coordinate accuracy in meters.
  ///
  /// Decimal64 with up to 6 fraction digits. Unit is implicit meters.
  /// Optional — when absent, no accuracy information is available.
  /// Must be non-negative. Not used in Cartesian contexts.
  final double? coordAccuracy;

  /// Vertical (height) coordinate accuracy in meters.
  ///
  /// Decimal64 with up to 6 fraction digits. Unit is "meters" per
  /// the YANG schema. Optional — when absent, no vertical accuracy
  /// information is available. Must be non-negative. Not applicable
  /// with Cartesian coordinate systems.
  final double? heightAccuracy;

  /// Creates a new [GeodeticSystem] instance.
  ///
  /// All fields are optional. When [isEarth] is [true] and
  /// [geodeticDatum] is `null`, the datum defaults to `"wgs-84"`,
  /// the standard Earth geodetic reference.
  ///
  /// @param geodeticDatum The IANA datum name (optional).
  /// @param coordAccuracy Horizontal accuracy in meters (optional).
  /// @param heightAccuracy Vertical accuracy in meters (optional).
  /// @param isEarth Whether the reference body is Earth (triggers
  ///                the `"wgs-84"` default when datum is absent).
  GeodeticSystem({
    String? geodeticDatum,
    this.coordAccuracy,
    this.heightAccuracy,
    bool isEarth = false,
  }) : geodeticDatum = geodeticDatum ?? (isEarth ? 'wgs-84' : null);

  /// Constructs a [GeodeticSystem] from a raw key-value database map.
  ///
  /// Field names use snake_case (`geodetic_datum`, `coord_accuracy`,
  /// `height_accuracy`) matching the YANG leaf names as stored in
  /// the database's `data_json` column.
  ///
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @param isEarth Whether the reference body is Earth (triggers the
  ///                `"wgs-84"` default when `geodetic_datum` is absent).
  /// @returns A typed [GeodeticSystem] with all parsed fields.
  factory GeodeticSystem.fromMap(Map<String, dynamic> map, {bool isEarth = false}) {
    return GeodeticSystem(
      geodeticDatum: map['geodetic_datum'] as String?,
      coordAccuracy: map['coord_accuracy'] as double?,
      heightAccuracy: map['height_accuracy'] as double?,
      isEarth: isEarth,
    );
  }

  /// Serializes this [GeodeticSystem] to a map for JSON encoding.
  ///
  /// Only non-null fields are included in the output, matching YANG
  /// schema conventions where absent leaves are simply not present
  /// rather than null-valued.
  ///
  /// @returns A map with snake_case keys matching the database column
  ///          names.
  Map<String, dynamic> toMap() {
    return {
      if (geodeticDatum != null) 'geodetic_datum': geodeticDatum,
      if (coordAccuracy != null) 'coord_accuracy': coordAccuracy,
      if (heightAccuracy != null) 'height_accuracy': heightAccuracy,
    };
  }
}
