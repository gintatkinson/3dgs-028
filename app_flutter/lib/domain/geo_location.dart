/// Represents a geographic location entity as defined in RFC 9179
/// (ietf-geo-location YANG grouping).
///
/// This is the root container for all geo-location data. It stores temporal
/// attributes recording when the location was measured ([timestamp]) and
/// optionally when the measurement expires ([validUntil]).
///
/// Both temporal fields use the `yang:date-and-time` format (RFC 6991):
/// `YYYY-MM-DDTHH:MM:SS[.fraction](Z|(+|-)HH:MM)`.
///
/// The container has no mandatory children — all descendant containers and
/// leaves are optional, allowing partial location specifications.
///
/// {@macro rfc9179_section_2_3}
///
/// @realizes UML::GeoLocation
/// @realizes UML::GeoLocation::timestamp
/// @realizes UML::GeoLocation::validUntil
class GeoLocation {
  /// Unique identifier for this location entity within the data store.
  final String entityId;

  /// The reference time when the location was recorded.
  ///
  /// Value of type `yang:date-and-time` (RFC 6991). Optional — when absent,
  /// the location data does not carry temporal context and consumers must not
  /// assume freshness or recency.
  final String? timestamp;

  /// The timestamp for which this geo-location remains valid.
  ///
  /// Value of type `yang:date-and-time` (RFC 6991). Optional — when absent,
  /// the geo-location has no specific expiration time and is considered valid
  /// indefinitely. When present alongside [timestamp], the temporal
  /// relationship `timestamp < valid-until` SHOULD hold.
  ///
  /// Consumers comparing the current time against this value can detect
  /// logically expired data.
  final String? validUntil;

  /// Creates a new [GeoLocation] instance.
  ///
  /// All fields except [entityId] are optional, conforming to the YANG
  /// schema where no child of the `geo-location` container is mandatory.
  const GeoLocation({
    required this.entityId,
    this.timestamp,
    this.validUntil,
  });

  /// Constructs a [GeoLocation] from a raw key-value map sourced from the
  /// database's `data_json` column.
  ///
  /// The [entityId] is provided separately since it is the row key, not
  /// stored inside the JSON payload. Fields not present in [map] are
  /// silently set to `null` — the caller must handle partial records.
  ///
  /// @param entityId The node identifier from the `node_id` column.
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [GeoLocation] instance with all parsed fields.
  factory GeoLocation.fromMap(String entityId, Map<String, dynamic> map) {
    return GeoLocation(
      entityId: entityId,
      timestamp: map['timestamp'] as String?,
      validUntil: map['valid_until'] as String?,
    );
  }

  /// Serializes this [GeoLocation] to a map suitable for JSON encoding
  /// into the database's `data_json` column.
  ///
  /// Only non-null fields are included in the output, matching the YANG
  /// schema convention where absent leaves are simply not present rather
  /// than null-valued.
  ///
  /// @returns A map with only the populated temporal fields.
  Map<String, dynamic> toMap() {
    return {
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
  /// @realizes UML::GeoLocation::checkExpiration
  bool get isExpired {
    if (validUntil == null) return false;
    final parsed = DateTime.tryParse(validUntil!);
    if (parsed == null) return false;
    return parsed.toUtc().isBefore(DateTime.now().toUtc());
  }

  /// Whether this location record carries temporal context.
  ///
  /// When [true], [timestamp] is present and consumers can reason about
  /// the age of the data. When [false], no measurement time was recorded.
  bool get hasTemporalContext => timestamp != null;
}
