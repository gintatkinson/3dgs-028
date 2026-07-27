/// Represents a location-level chassis container as defined in the
/// IETF NI-Location YANG grouping (`nil:locations/location/contained-chassis`).
///
/// The container `nil:locations/location/contained-chassis` is a read-only
/// operational state list. Each chassis entry is keyed by [chassisId]
/// (mandatory uint32, unique within the parent location). Optional fields
/// carry leafref references to associated network elements and components.
///
/// All fields are read-only (config false) — this container represents
/// discovered/observed chassis inventory, not user-managed configuration.
///
/// @realizes UML::LocationChassis
/// @realizes UML::LocationChassis::chassisId
/// @realizes UML::LocationChassis::neRef
/// @realizes UML::LocationChassis::componentRef
class LocationChassis {
  /// Mandatory chassis identifier. This is the list key — every chassis
  /// entry in the `contained-chassis` list MUST have a non-negative,
  /// non-null [chassisId] of type uint32 (range 0..4294967295).
  final int chassisId;

  /// Leafref to a network element associated with this chassis.
  ///
  /// Optional — when `null`, no NE relationship has been established
  /// for this chassis entry.
  final String? neRef;

  /// Leafref to a specific component within the associated network element.
  ///
  /// Optional — when `null`, the chassis is associated at the NE level
  /// only, or no component-level granularity has been established.
  final String? componentRef;

  /// Creates a new [LocationChassis] instance.
  ///
  /// [chassisId] is mandatory (uint32). [neRef] and [componentRef] are
  /// optional leafref strings, conforming to the YANG schema where only
  /// the list key is required.
  const LocationChassis({
    required this.chassisId,
    this.neRef,
    this.componentRef,
  });

  /// Constructs a [LocationChassis] from a raw key-value map sourced
  /// from the database's `data_json` column.
  ///
  /// The [chassisId] is provided separately since it is the list key.
  /// Fields not present in [map] are silently set to `null` — the
  /// caller must handle partial records.
  ///
  /// @param chassisId The chassis identifier for this entry.
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [LocationChassis] instance with all parsed fields.
  factory LocationChassis.fromMap(int chassisId, Map<String, dynamic> map) {
    return LocationChassis(
      chassisId: chassisId,
      neRef: map['ne_ref'] as String?,
      componentRef: map['component_ref'] as String?,
    );
  }

  /// Serializes this [LocationChassis] to a map suitable for JSON
  /// encoding into the database's `data_json` column.
  ///
  /// Only non-null fields are included in the output, matching the YANG
  /// schema convention where absent leaves are not present rather than
  /// null-valued.
  ///
  /// @returns A map with only the populated fields.
  Map<String, dynamic> toMap() {
    return {
      if (neRef != null) 'ne_ref': neRef,
      if (componentRef != null) 'component_ref': componentRef,
    };
  }
}
