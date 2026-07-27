/// Represents a rack-level chassis container as defined in the
/// IETF NI-Location YANG grouping (`nil:locations/racks/rack/contained-chassis`).
///
/// The container `nil:locations/racks/rack/contained-chassis` is a read-only
/// operational state list. Each chassis entry is keyed by [relativePosition]
/// (mandatory uint8, range 0..255, U-slot). Optional fields carry leafref
/// references to associated network elements and components.
///
/// All fields are read-only (config false) — this container represents
/// discovered/observed chassis inventory within a rack, not user-managed
/// configuration.
///
/// @realizes UML::RackChassis
/// @realizes UML::RackChassis::relativePosition
/// @realizes UML::RackChassis::neRef
/// @realizes UML::RackChassis::componentRef
class RackChassis {
  /// Mandatory relative slot position within the rack. This is the list key —
  /// every chassis entry in the `contained-chassis` list MUST have a
  /// non-negative, non-null [relativePosition] of type uint8 (range 0..255).
  /// The value represents the U-slot position within the parent rack.
  final int relativePosition;

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

  /// Creates a new [RackChassis] instance.
  ///
  /// [relativePosition] is mandatory (uint8, 0..255). [neRef] and
  /// [componentRef] are optional leafref strings, conforming to the YANG
  /// schema where only the list key is required.
  const RackChassis({
    required this.relativePosition,
    this.neRef,
    this.componentRef,
  });

  /// Constructs a [RackChassis] from a raw key-value map sourced
  /// from the database's `data_json` column.
  ///
  /// The [relativePosition] is provided separately since it is the list key.
  /// Fields not present in [map] are silently set to `null` — the
  /// caller must handle partial records.
  ///
  /// @param relativePosition The U-slot position within the parent rack.
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [RackChassis] instance with all parsed fields.
  factory RackChassis.fromMap(int relativePosition, Map<String, dynamic> map) {
    return RackChassis(
      relativePosition: relativePosition,
      neRef: map['ne_ref'] as String?,
      componentRef: map['component_ref'] as String?,
    );
  }

  /// Serializes this [RackChassis] to a map suitable for JSON
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
