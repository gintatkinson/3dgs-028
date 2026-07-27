/// Defines the frame of reference for geographic location values as
/// specified in RFC 9179, Section 2.1.
///
/// The reference frame determines the meaning and precision of all
/// location coordinates — the definition of zero-height, and the
/// interpretation of latitude, longitude, and Cartesian values.
///
/// The frame specifies which astronomical body the location is relative
/// to, with Earth as the default. An optional alternate system enables
/// non-standard reference frames such as virtual realities or simulations.
///
/// Notable astronomical body values defined by the International
/// Astronomical Union: `"sun"`, `"earth"`, `"moon"`, `"enceladus"`,
/// `"ceres"`, `"67p/churyumov-gerasimenko"`.
///
/// @realizes UML::ReferenceFrame
/// @realizes UML::ReferenceFrame::astronomicalBody
/// @realizes UML::ReferenceFrame::alternateSystem
class ReferenceFrame {
  /// The astronomical body defining the coordinate system origin.
  ///
  /// Constrained by pattern `[ -@\[-\^_-~]*` (ASCII characters 32–64
  /// and 91–126). Default value is `"earth"`. Uppercase SHOULD be
  /// converted to lowercase per the schema description guidance.
  ///
  /// The preceding article 'the' in IAU names SHOULD NOT be included
  /// (e.g., use `"moon"` not `"the-moon"`).
  final String? astronomicalBody;

  /// An optional system identifier for non-standard reference frames.
  ///
  /// Only present when the device supports the `alternate-systems`
  /// feature (YANG `if-feature` guard). When present, the meaning of
  /// [astronomicalBody] and all downstream coordinate values is defined
  /// by that system rather than the natural universe.
  ///
  /// Normally absent for standard geo-location use cases.
  final String? alternateSystem;

  /// Creates a new [ReferenceFrame] instance.
  ///
  /// All fields are optional — when both are null, defaults of
  /// `astronomicalBody = "earth"` and the natural universe system apply.
  const ReferenceFrame({
    this.astronomicalBody,
    this.alternateSystem,
  });

  /// Whether a non-standard alternate coordinate system is active.
  ///
  /// Returns [true] when [alternateSystem] is present, indicating that
  /// coordinate values should be interpreted within that system rather
  /// than the natural universe.
  bool get hasAlternateSystems => alternateSystem != null;

  /// Constructs a [ReferenceFrame] from a raw key-value database map.
  ///
  /// Field names use snake_case (`astronomical_body`, `alternate_system`)
  /// matching the YANG leaf names as stored in the database.
  ///
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [ReferenceFrame] with all parsed fields.
  factory ReferenceFrame.fromMap(Map<String, dynamic> map) {
    return ReferenceFrame(
      astronomicalBody: map['astronomical_body'] as String?,
      alternateSystem: map['alternate_system'] as String?,
    );
  }

  /// Serializes this [ReferenceFrame] to a map for JSON encoding.
  ///
  /// Only non-null fields are included, matching YANG schema conventions
  /// where absent leaves are simply not present.
  ///
  /// @returns A map with snake_case keys matching the database column names.
  Map<String, dynamic> toMap() {
    return {
      if (astronomicalBody != null) 'astronomical_body': astronomicalBody,
      if (alternateSystem != null) 'alternate_system': alternateSystem,
    };
  }
}
