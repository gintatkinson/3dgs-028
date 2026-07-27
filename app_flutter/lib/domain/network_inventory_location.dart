/// Represents a network inventory location entity as defined in the
/// IETF NI-Location YANG grouping (ietf-network-inventory-location).
///
/// The container `nil:locations/location` is a read-only operational state
/// list. Each location is keyed by [id] (mandatory). All other fields carry
/// optional metadata describing the physical or logical location.
///
/// Temporal fields use the `yang:date-and-time` format (RFC 6991):
/// `YYYY-MM-DDTHH:MM:SS[.fraction](Z|(+|-)HH:MM)`.
///
/// @realizes UML::NetworkInventoryLocation
/// @realizes UML::NetworkInventoryLocation::id
/// @realizes UML::NetworkInventoryLocation::timestamp
/// @realizes UML::NetworkInventoryLocation::validUntil
class NetworkInventoryLocation {
  /// Mandatory location identifier. This is the list key — every location
  /// entry in the `nil:locations/location` list MUST have a non-empty [id].
  final String id;

  /// Universally unique identifier for this location.
  final String? uuid;

  /// Human-readable name for the location.
  final String? name;

  /// Alternative name or short label for the location.
  final String? alias;

  /// Free-form description providing additional context.
  final String? description;

  /// Categorization of the location type (e.g. "site", "building", "room").
  final String? type;

  /// Leafref to a parent location's [id], establishing a hierarchy.
  /// When `null` the location is a top-level entry.
  final String? parent;

  /// The reference time when this location record was created or last updated.
  ///
  /// Value of type `yang:date-and-time` (RFC 6991). Optional — when absent,
  /// the location data does not carry temporal context.
  final String? timestamp;

  /// The timestamp for which this location record remains valid.
  ///
  /// Value of type `yang:date-and-time` (RFC 6991). Optional — when absent,
  /// the location has no specific expiration time. When present alongside
  /// [timestamp], the temporal relationship `timestamp < valid-until` SHOULD
  /// hold.
  final String? validUntil;

  /// Creates a new [NetworkInventoryLocation] instance.
  ///
  /// [id] is mandatory. All other fields are optional, conforming to the
  /// YANG schema where only the list key is required.
  const NetworkInventoryLocation({
    required this.id,
    this.uuid,
    this.name,
    this.alias,
    this.description,
    this.type,
    this.parent,
    this.timestamp,
    this.validUntil,
  });

  /// Constructs a [NetworkInventoryLocation] from a raw key-value map
  /// sourced from the database's `data_json` column.
  ///
  /// The [id] is provided separately since it is the list key. Fields not
  /// present in [map] are silently set to `null` — the caller must handle
  /// partial records.
  ///
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [NetworkInventoryLocation] instance with all parsed fields.
  factory NetworkInventoryLocation.fromMap(String id, Map<String, dynamic> map) {
    return NetworkInventoryLocation(
      id: id,
      uuid: map['uuid'] as String?,
      name: map['name'] as String?,
      alias: map['alias'] as String?,
      description: map['description'] as String?,
      type: map['type'] as String?,
      parent: map['parent'] as String?,
      timestamp: map['timestamp'] as String?,
      validUntil: map['valid_until'] as String?,
    );
  }

  /// Serializes this [NetworkInventoryLocation] to a map suitable for JSON
  /// encoding into the database's `data_json` column.
  ///
  /// Only non-null fields are included in the output, matching the YANG
  /// schema convention where absent leaves are not present rather than
  /// null-valued.
  ///
  /// @returns A map with only the populated fields.
  Map<String, dynamic> toMap() {
    return {
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (alias != null) 'alias': alias,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (parent != null) 'parent': parent,
      if (timestamp != null) 'timestamp': timestamp,
      if (validUntil != null) 'valid_until': validUntil,
    };
  }

  /// Whether this location's validity has expired.
  ///
  /// Returns [true] when [validUntil] is present, parseable as a UTC
  /// date-time, and strictly before `DateTime.now().toUtc()`.
  ///
  /// Returns [false] when [validUntil] is `null` (no expiration set) or
  /// when the string cannot be parsed (graceful degradation — the caller
  /// should not crash on malformed data).
  ///
  /// The comparison uses UTC to avoid timezone-offset ambiguity across
  /// different consumer locations.
  ///
  /// @realizes UML::NetworkInventoryLocation::checkExpiration
  bool get isExpired {
    if (validUntil == null) return false;
    final parsed = DateTime.tryParse(validUntil!);
    if (parsed == null) return false;
    return parsed.toUtc().isBefore(DateTime.now().toUtc());
  }

  /// Whether this location is a top-level entry (has no parent).
  ///
  /// Returns [true] when [parent] is `null`, indicating the location sits
  /// at the root of the location hierarchy.
  bool get isTopLevel => parent == null;

  /// Whether this location record carries temporal context.
  ///
  /// When [true], [timestamp] is present and consumers can reason about
  /// the age of the data. When [false], no creation/update timestamp was
  /// recorded.
  bool get hasTemporalContext => timestamp != null;
}
