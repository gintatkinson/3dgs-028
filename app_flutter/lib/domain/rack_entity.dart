/// Represents a rack entity as defined in the
/// IETF NI-Location YANG grouping (`nil:locations/racks/rack`).
///
/// The container `nil:locations/racks/rack` is a read-only operational state
/// list. Each rack entry is keyed by [id] (mandatory). All other fields carry
/// optional metadata describing the physical dimensions, power capacity,
/// and security classification of the rack.
///
/// Temporal fields use the `yang:date-and-time` format (RFC 6991):
/// `YYYY-MM-DDTHH:MM:SS[.fraction](Z|(+|-)HH:MM)`.
///
/// Physical dimension fields ([height], [width], [depth]) are uint16
/// values in millimeters (mm). Power fields ([maxVoltage], [maxAllocatedPower])
/// are uint16 values in volts (V) and watts (W) respectively.
///
/// @realizes UML::RackEntity
/// @realizes UML::RackEntity::id
/// @realizes UML::RackEntity::rackClass
/// @realizes UML::RackEntity::height
/// @realizes UML::RackEntity::width
/// @realizes UML::RackEntity::depth
/// @realizes UML::RackEntity::maxVoltage
/// @realizes UML::RackEntity::maxAllocatedPower
/// @realizes UML::RackEntity::timestamp
/// @realizes UML::RackEntity::validUntil
class RackEntity {
  /// Mandatory rack identifier. This is the list key — every rack
  /// entry in the `nil:locations/racks/rack` list MUST have a non-empty [id].
  final String id;

  /// Identityref classification of the rack's security and compliance level.
  ///
  /// Permitted values: `rack-standard`, `rack-secure-baseline`,
  /// `rack-secure-medium`, `rack-secure-high`. Optional — when `null`,
  /// the rack has no explicit classification.
  final String? rackClass;

  /// Universally unique identifier for this rack.
  final String? uuid;

  /// Human-readable name for the rack.
  final String? name;

  /// Alternative name or short label for the rack.
  final String? alias;

  /// Free-form description providing additional context.
  final String? description;

  /// Physical height of the rack in millimeters (mm).
  ///
  /// Value range: 0..65535 (uint16). Optional — when `null`, the
  /// dimension has not been reported.
  final int? height;

  /// Physical width of the rack in millimeters (mm).
  ///
  /// Value range: 0..65535 (uint16). Optional — when `null`, the
  /// dimension has not been reported.
  final int? width;

  /// Physical depth of the rack in millimeters (mm).
  ///
  /// Value range: 0..65535 (uint16). Optional — when `null`, the
  /// dimension has not been reported.
  final int? depth;

  /// Maximum voltage supported by the rack in volts (V).
  ///
  /// Value range: 0..65535 (uint16). Optional — when `null`, the
  /// voltage rating has not been reported.
  final int? maxVoltage;

  /// Maximum allocated power for the rack in watts (W).
  ///
  /// Value range: 0..65535 (uint16). Optional — when `null`, the
  /// power budget has not been reported.
  final int? maxAllocatedPower;

  /// The reference time when this rack record was created or last updated.
  ///
  /// Value of type `yang:date-and-time` (RFC 6991). Optional — when absent,
  /// the rack data does not carry temporal context.
  final String? timestamp;

  /// The timestamp for which this rack record remains valid.
  ///
  /// Value of type `yang:date-and-time` (RFC 6991). Optional — when absent,
  /// the rack has no specific expiration time. When present alongside
  /// [timestamp], the temporal relationship `timestamp < valid-until` SHOULD
  /// hold.
  final String? validUntil;

  /// Creates a new [RackEntity] instance.
  ///
  /// [id] is mandatory. All other fields are optional, conforming to the
  /// YANG schema where only the list key is required.
  const RackEntity({
    required this.id,
    this.rackClass,
    this.uuid,
    this.name,
    this.alias,
    this.description,
    this.height,
    this.width,
    this.depth,
    this.maxVoltage,
    this.maxAllocatedPower,
    this.timestamp,
    this.validUntil,
  });

  /// Constructs a [RackEntity] from a raw key-value map
  /// sourced from the database's `data_json` column.
  ///
  /// The [id] is provided separately since it is the list key. Fields not
  /// present in [map] are silently set to `null` — the caller must handle
  /// partial records.
  ///
  /// Integer fields ([height], [width], [depth], [maxVoltage],
  /// [maxAllocatedPower]) are parsed from the map as-is; the map values
  /// are expected to already be of type [int].
  ///
  /// @param id The rack identifier for this entry.
  /// @param map The decoded `data_json` map from the `properties` table.
  /// @returns A typed [RackEntity] instance with all parsed fields.
  factory RackEntity.fromMap(String id, Map<String, dynamic> map) {
    return RackEntity(
      id: id,
      rackClass: map['rack_class'] as String?,
      uuid: map['uuid'] as String?,
      name: map['name'] as String?,
      alias: map['alias'] as String?,
      description: map['description'] as String?,
      height: map['height'] as int?,
      width: map['width'] as int?,
      depth: map['depth'] as int?,
      maxVoltage: map['max_voltage'] as int?,
      maxAllocatedPower: map['max_allocated_power'] as int?,
      timestamp: map['timestamp'] as String?,
      validUntil: map['valid_until'] as String?,
    );
  }

  /// Serializes this [RackEntity] to a map suitable for JSON
  /// encoding into the database's `data_json` column.
  ///
  /// Only non-null fields are included in the output, matching the YANG
  /// schema convention where absent leaves are not present rather than
  /// null-valued.
  ///
  /// @returns A map with only the populated fields.
  Map<String, dynamic> toMap() {
    return {
      if (rackClass != null) 'rack_class': rackClass,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (alias != null) 'alias': alias,
      if (description != null) 'description': description,
      if (height != null) 'height': height,
      if (width != null) 'width': width,
      if (depth != null) 'depth': depth,
      if (maxVoltage != null) 'max_voltage': maxVoltage,
      if (maxAllocatedPower != null) 'max_allocated_power': maxAllocatedPower,
      if (timestamp != null) 'timestamp': timestamp,
      if (validUntil != null) 'valid_until': validUntil,
    };
  }

  /// Whether this rack's validity has expired.
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
  /// @realizes UML::RackEntity::checkExpiration
  bool get isExpired {
    if (validUntil == null) return false;
    final parsed = DateTime.tryParse(validUntil!);
    if (parsed == null) return false;
    return parsed.toUtc().isBefore(DateTime.now().toUtc());
  }

  /// Whether this rack record carries temporal context.
  ///
  /// When [true], [timestamp] is present and consumers can reason about
  /// the age of the data. When [false], no creation/update timestamp was
  /// recorded.
  bool get hasTemporalContext => timestamp != null;
}
