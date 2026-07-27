/// Represents the rack placement container as defined in the
/// IETF NI-Location YANG grouping (`nil:locations/racks/rack/rack-location`).
///
/// The container `nil:locations/racks/rack/rack-location` is a read-only
/// operational state container under a rack entry. It captures the physical
/// positioning of a rack within a network inventory location via a leafref
/// to the parent location and optional row/column grid coordinates.
///
/// All fields are read-only (config false) — this container represents
/// observed rack placement, not user-managed configuration.
///
/// @realizes UML::RackPlacement
/// @realizes UML::RackPlacement::locationRef
/// @realizes UML::RackPlacement::rowNumber
/// @realizes UML::RackPlacement::columnNumber
class RackPlacement {
  /// Leafref to the parent network inventory location.
  ///
  /// Optional — when `null`, no location association has been established
  /// for this rack entry.
  final String? locationRef;

  /// The row number of this rack within the location's grid layout.
  ///
  /// Value range: 0..4294967295 (uint32). Optional — when `null`, the
  /// row coordinate has not been established.
  final int? rowNumber;

  /// The column number of this rack within the location's grid layout.
  ///
  /// Value range: 0..4294967295 (uint32). Optional — when `null`, the
  /// column coordinate has not been established.
  final int? columnNumber;

  /// Creates a new [RackPlacement] instance.
  ///
  /// All fields are optional — this is a contained child container with
  /// no mandatory list key, conforming to the YANG schema.
  const RackPlacement({
    this.locationRef,
    this.rowNumber,
    this.columnNumber,
  });

  /// Constructs a [RackPlacement] from a raw key-value map sourced
  /// from the database's `data_json` column.
  ///
  /// Fields not present in [map] are silently set to `null` — the
  /// caller must handle partial records.
  ///
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [RackPlacement] instance with all parsed fields.
  factory RackPlacement.fromMap(Map<String, dynamic> map) {
    return RackPlacement(
      locationRef: map['location_ref'] as String?,
      rowNumber: map['row_number'] as int?,
      columnNumber: map['column_number'] as int?,
    );
  }

  /// Serializes this [RackPlacement] to a map suitable for JSON
  /// encoding into the database's `data_json` column.
  ///
  /// Only non-null fields are included in the output, matching the YANG
  /// schema convention where absent leaves are not present rather than
  /// null-valued.
  ///
  /// @returns A map with only the populated fields.
  Map<String, dynamic> toMap() {
    return {
      if (locationRef != null) 'location_ref': locationRef,
      if (rowNumber != null) 'row_number': rowNumber,
      if (columnNumber != null) 'column_number': columnNumber,
    };
  }
}
