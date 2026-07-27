import 'geo_location.dart';

/// Stateless service providing validation and lifecycle operations for
/// geographic location data elements defined in RFC 9179.
///
/// All methods are static — the service is a pure function collection
/// with no mutable state, no side effects, and no external dependencies.
/// This design allows callers to use individual validators without
/// constructing or injecting a service instance.
///
/// @realizes UML::GeoLocationService
/// @realizes UML::ReferenceFrame::validateBody
/// @realizes UML::ReferenceFrame::validateDatum
class GeoLocationService {
  /// Regex pattern for YANG `date-and-time` format per RFC 6991.
  ///
  /// Matches strings of the form:
  /// `YYYY-MM-DDTHH:MM:SS[.fraction][Z|(+|-)HH:MM]`
  ///
  /// The fractional seconds component is optional and may have
  /// arbitrary decimal digits. The timezone offset is mandatory for
  /// non-UTC times (Z for UTC, ±HH:MM for offset).
  static const _dateTimePattern =
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$';

  /// Regex pattern for astronomical body names per RFC 9179.
  ///
  /// Permitted characters: ASCII 32–64 (space to @) and 91–126
  /// (left bracket to tilde). Excludes control characters (0–31, 127)
  /// and uppercase letters 65–90 which SHOULD be normalized to
  /// lowercase before validation.
  static const _bodyPattern = r'^[ -@\[-\^_-~]*$';

  /// Validates an astronomical body name against the RFC 9179 pattern
  /// constraint `[ -@\[-\^_-~]*`.
  ///
  /// Null and empty values pass validation silently — the default
  /// `"earth"` is applied downstream by consumers rather than at the
  /// validation layer, matching YANG semantics where the default is a
  /// data-model concern, not a constraint enforcement concern.
  ///
  /// @param value The astronomical body name to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::ReferenceFrame::validateBody
  static String? validateAstronomicalBody(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(_bodyPattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid astronomical body: contains characters outside '
          'the allowed set [ -@[\\-\\^_-~].';
    }
    return null;
  }

  /// Normalizes an astronomical body name to lowercase.
  ///
  /// Per RFC 9179 Section 2.1, uppercase values SHOULD be converted to
  /// lowercase. This is a SHOULD requirement — the system accepts
  /// uppercase input but normalizes it before storage.
  ///
  /// This method is intentionally simple (string.toLowerCase) to avoid
  /// locale-specific casing surprises (Turkish İ/I, etc.). IAU body
  /// names are English-lowercase by convention.
  ///
  /// @param value The raw astronomical body name.
  /// @returns The lowercase-normalized name.
  static String normalizeAstronomicalBody(String value) {
    return value.toLowerCase();
  }

  /// Validates whether an alternate system can be set given the feature
  /// enablement state.
  ///
  /// The `alternate-systems` YANG feature is a conditional guard —
  /// when the feature is not enabled, the `alternate-system` leaf must
  /// not be written. This method enforces that constraint.
  ///
  /// @param value The alternate system identifier being set, or `null`.
  /// @param featureEnabled Whether the `alternate-systems` feature is active.
  /// @returns An error message if the feature gate is violated, or
  ///          `null` if acceptable.
  static String? validateAlternateSystem(String? value, bool featureEnabled) {
    if (value != null && !featureEnabled) {
      return 'Alternate system set but feature is not enabled.';
    }
    return null;
  }

  /// Validates a timestamp string against the YANG `date-and-time`
  /// format (RFC 6991).
  ///
  /// Two-stage validation: first checks the regex pattern for structural
  /// conformance (lexical representation), then attempts a DateTime.parse
  /// to verify semantic validity (e.g., month 13 would fail).
  ///
  /// @param value The timestamp string to validate.
  /// @returns An error message if validation fails, or `null` if valid.
  ///
  /// @realizes UML::GeoLocation::queryLocation (timestamp validation path)
  static String? validateTimestamp(String value) {
    final regex = RegExp(_dateTimePattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid timestamp format. Expected RFC 6991 date-and-time '
          '(e.g. 2022-02-11T12:00:00Z).';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return 'Invalid timestamp: cannot parse as a valid date-time.';
    }
    return null;
  }

  /// Validates that the `valid-until` timestamp is chronologically after
  /// the `timestamp` value.
  ///
  /// The YANG schema does NOT enforce this constraint at the data-model
  /// level — it is a SHOULD requirement documented in the specification
  /// description text. This method provides application-level enforcement.
  ///
  /// Returns `null` (no error) when either value cannot be parsed as a
  /// DateTime — the caller should validate individual timestamps first
  /// with [validateTimestamp] before calling this method.
  ///
  /// @param timestamp The measurement timestamp.
  /// @param validUntil The expiration timestamp to compare.
  /// @returns An error message if `validUntil < timestamp`, or `null`
  ///          if the relationship is valid or unparseable.
  static String? validateTemporalRelationship(
    String timestamp,
    String validUntil,
  ) {
    final ts = DateTime.tryParse(timestamp);
    final vu = DateTime.tryParse(validUntil);
    // Graceful degradation: if either value is unparseable, let
    // the individual timestamp validators catch and report it.
    if (ts == null || vu == null) return null;
    if (vu.toUtc().isBefore(ts.toUtc())) {
      return 'Temporal inconsistency: valid-until ($validUntil) is '
          'before timestamp ($timestamp).';
    }
    return null;
  }

  /// Checks whether a geo-location record has logically expired.
  ///
  /// Delegates to [GeoLocation.isExpired] which compares [validUntil]
  /// against the current UTC time. This method exists as a service-level
  /// convenience so that callers do not need direct model access for
  /// simple expiration checks.
  ///
  /// @param location The geo-location record to check.
  /// @returns [true] if the record has expired, [false] otherwise.
  ///
  /// @realizes UML::GeoLocation::checkExpiration
  static bool checkExpiration(GeoLocation location) {
    return location.isExpired;
  }

  /// Prepares a save payload map containing only the temporal fields.
  ///
  /// Used by repository adapters to construct minimal database payloads
  /// without exposing internal serialization format to callers.
  ///
  /// @param timestamp Optional measurement timestamp.
  /// @param validUntil Optional expiration timestamp.
  /// @returns A map suitable for JSON encoding into `data_json`.
  static Map<String, dynamic> prepareSavePayload({
    String? timestamp,
    String? validUntil,
  }) {
    return {
      if (timestamp != null) 'timestamp': timestamp,
      if (validUntil != null) 'valid_until': validUntil,
    };
  }

  /// Validates a geodetic datum name against the RFC 9179 pattern
  /// constraint `[ -@\[-\^_-~]*`, applying IANA normalization first.
  ///
  /// IANA normalization converts to lowercase and replaces spaces with
  /// dashes per the IANA geodetic datum registry conventions. The
  /// normalized value is then checked against the character set pattern.
  ///
  /// Null and empty values pass validation silently — the default
  /// datum is applied downstream by the [GeodeticSystem] constructor
  /// rather than at the validation layer.
  ///
  /// @param value The geodetic datum name to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::GeodeticSystem::validateDatum
  static String? validateGeodeticDatum(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = normalizeGeodeticDatum(value);
    final regex = RegExp(_bodyPattern);
    if (!regex.hasMatch(normalized)) {
      return 'Invalid geodetic datum: contains characters outside '
          'the allowed set [ -@[\\-\\^_-~].';
    }
    return null;
  }

  /// Normalizes a geodetic datum name per IANA registry conventions.
  ///
  /// IANA-registered geodetic datum names use lowercase ASCII with
  /// dashes instead of spaces. This method converts to lowercase and
  /// replaces every space character with a dash, ensuring canonical
  /// representation before storage or comparison.
  ///
  /// This is intentionally a combined transformation — datum names
  /// like `"WGS 84"` must become `"wgs-84"` to match the IANA
  /// registry entry format.
  ///
  /// @param value The raw geodetic datum name.
  /// @returns The canonical IANA-normalized datum name.
  ///
  /// @realizes UML::GeodeticSystem::normalizeDatum
  static String normalizeGeodeticDatum(String value) {
    return value.toLowerCase().replaceAll(' ', '-');
  }

  /// Validates that a coordinate accuracy value is non-negative.
  ///
  /// Coordinate accuracy is an implied-meters value (decimal64,
  /// 6 fraction digits). Negative accuracy is mathematically
  /// meaningless and is rejected. Zero is valid (perfect accuracy
  /// claim) and positive values express uncertainty.
  ///
  /// Null values pass validation — the field is optional per the
  /// YANG schema.
  ///
  /// @param value The coordinate accuracy value in meters.
  /// @returns An error message if negative, or `null` if acceptable.
  ///
  /// @realizes UML::GeodeticSystem::validateCoordAccuracy
  static String? validateCoordinateAccuracy(double? value) {
    if (value == null) return null;
    if (value < 0) {
      return 'Coordinate accuracy cannot be negative.';
    }
    return null;
  }

  /// Validates that a height accuracy value is non-negative.
  ///
  /// Height accuracy is in meters (decimal64, 6 fraction digits).
  /// Negative accuracy is mathematically meaningless and is rejected.
  /// Not applicable with Cartesian coordinate systems where height
  /// accuracy is derived from the 3D coordinate uncertainties.
  ///
  /// Null values pass validation — the field is optional per the
  /// YANG schema.
  ///
  /// @param value The height accuracy value in meters.
  /// @returns An error message if negative, or `null` if acceptable.
  ///
  /// @realizes UML::GeodeticSystem::validateHeightAccuracy
  static String? validateHeightAccuracy(double? value) {
    if (value == null) return null;
    if (value < 0) {
      return 'Height accuracy cannot be negative.';
    }
    return null;
  }

  /// Validates an ellipsoid latitude value against Earth range bounds.
  ///
  /// Range is [-90, 90] degrees per the WGS-84 ellipsoid specification
  /// and RFC 9179 definition. Null values pass validation — the field
  /// is optional per the YANG schema.
  ///
  /// @param value The latitude value in degrees.
  /// @returns An error message if out of range, or `null` if acceptable.
  ///
  /// @realizes UML::EllipsoidCoordinates::validateLatitude
  static String? validateLatitudeEarth(double? value) {
    if (value == null) return null;
    if (value < -90 || value > 90) {
      return 'Latitude must be between -90 and 90 degrees.';
    }
    return null;
  }

  /// Validates an ellipsoid longitude value against Earth range bounds.
  ///
  /// Range is [-180, 180] degrees per the WGS-84 ellipsoid specification
  /// and RFC 9179 definition. Null values pass validation — the field
  /// is optional per the YANG schema.
  ///
  /// @param value The longitude value in degrees.
  /// @returns An error message if out of range, or `null` if acceptable.
  ///
  /// @realizes UML::EllipsoidCoordinates::validateLongitude
  static String? validateLongitudeEarth(double? value) {
    if (value == null) return null;
    if (value < -180 || value > 180) {
      return 'Longitude must be between -180 and 180 degrees.';
    }
    return null;
  }

  /// Validates a Cartesian coordinate value as a finite double.
  ///
  /// Cartesian coordinates (X, Y, Z) are meters-based values with
  /// decimal64 precision (6 fraction digits). Null values pass
  /// validation — the field is optional per the YANG schema.
  /// Non-finite values (infinity, NaN) are rejected.
  ///
  /// @param value The Cartesian coordinate value in meters.
  /// @returns An error message if the value is non-finite, or `null`
  ///          if acceptable.
  ///
  /// @realizes UML::CartesianCoordinates::validateCartesianValue
  static String? validateCartesianValue(double? value) {
    if (value == null) return null;
    if (value.isNaN || value.isInfinite) {
      return 'Cartesian coordinate must be a valid finite number.';
    }
    return null;
  }

  /// Rounds a double value to a specified number of fraction digits.
  ///
  /// Uses [num.toStringAsFixed] and reparsing to ensure the result has
  /// exactly [fractionDigits] decimal places of precision. This approach
  /// avoids floating-point representation artifacts that can occur with
  /// mathematical rounding alone.
  ///
  /// For decimal64 fields: use fractionDigits=16 for latitude/longitude
  /// and fractionDigits=6 for height.
  ///
  /// @param value The double value to round.
  /// @param fractionDigits The number of decimal places to retain.
  /// @returns The rounded double value.
  ///
  /// @realizes UML::FieldValidator::roundDecimal64
  static double roundDecimal64(double value, int fractionDigits) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  /// Validates a velocity component value (v-north, v-east, or v-up).
  ///
  /// Velocity components are decimal64 values with 12 fraction digits
  /// in m/s. Null values pass validation — the field is optional per
  /// the YANG schema. Non-finite values (infinity, NaN) are rejected.
  /// No range constraint is applied — any finite double is acceptable
  /// as velocity components span reasonable physical ranges.
  ///
  /// @param value The velocity component value in m/s.
  /// @returns An error message if the value is non-finite, or `null`
  ///          if acceptable.
  ///
  /// @realizes UML::VelocityVector::validateVelocityComponent
  static String? validateVelocityComponent(double? value) {
    if (value == null) return null;
    if (value.isNaN || value.isInfinite) {
      return 'Velocity component must be a valid finite number.';
    }
    return null;
  }

  /// Creates a [GeoLocation] domain model instance from individual fields.
  ///
  /// Convenience factory that avoids callers needing to import and
  /// construct [GeoLocation] directly when all fields are available
  /// as positional/named arguments rather than a map.
  ///
  /// @param entityId The unique entity identifier.
  /// @param timestamp Optional measurement timestamp.
  /// @param validUntil Optional expiration timestamp.
  /// @returns A fully constructed [GeoLocation] instance.
  static GeoLocation createLocation({
    required String entityId,
    String? timestamp,
    String? validUntil,
  }) {
    return GeoLocation(
      entityId: entityId,
      timestamp: timestamp,
      validUntil: validUntil,
    );
  }

  /// Validates a network inventory location identifier.
  ///
  /// The `id` field is the mandatory list key for the `nil:locations/location`
  /// YANG list. Null and empty values are rejected — every location entry
  /// MUST have a non-empty identifier.
  ///
  /// @param value The location identifier to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::NetworkInventoryLocation::validateId
  static String? validateNiLocationId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Location ID is required and cannot be empty.';
    }
    return null;
  }

  /// Validates a network inventory location type string.
  ///
  /// The `type` field is optional — null and empty values pass validation.
  /// No structural constraint is applied; any non-null string is acceptable.
  ///
  /// @param value The location type string to validate (e.g. "site",
  ///              "building", "room").
  /// @returns `null` in all cases — this is a no-op validator for
  ///          interface consistency with other field validators.
  ///
  /// @realizes UML::NetworkInventoryLocation::validateType
  static String? validateNiType(String? value) {
    return null;
  }

  /// Validates a network inventory location parent leafref.
  ///
  /// The `parent` field is optional — null and empty values pass validation.
  /// No structural constraint is applied; referential integrity is the
  /// responsibility of the data source layer.
  ///
  /// @param value The parent location identifier to validate.
  /// @returns `null` in all cases — this is a no-op validator for
  ///          interface consistency with other field validators.
  ///
  /// @realizes UML::NetworkInventoryLocation::validateParent
  static String? validateNiParent(String? value) {
    return null;
  }

  /// Validates a country code against the ISO 3166-1 alpha-2 pattern.
  ///
  /// The [countryCode] must be exactly two uppercase letters (`[A-Z]{2}`).
  /// Null and empty values pass validation silently — the field is
  /// optional per the YANG schema. Lowercase, digits, and longer or
  /// shorter strings are rejected.
  ///
  /// Example valid values: `"US"`, `"JP"`, `"DE"`.
  /// Example invalid values: `"us"` (lowercase), `"USA"` (too long),
  /// `"U"` (too short), `"U1"` (contains digit).
  ///
  /// @param value The country code string to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::PhysicalAddress::validateCountryCode
  static String? validateCountryCode(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(r'^[A-Z]{2}$');
    if (!regex.hasMatch(value)) {
      return 'Invalid country code "$value": must be exactly two '
          'uppercase letters (ISO 3166-1 alpha-2).';
    }
    return null;
  }

  /// Validates a chassis identifier value against the uint32 constraints
  /// defined for the `nil:locations/location/contained-chassis` list key.
  ///
  /// The [value] is received as a string from the property grid and must
  /// be parseable to a non-negative integer within the uint32 range
  /// (0..4294967295). Null, empty, and non-numeric values are rejected —
  /// the chassis-id is a mandatory list key.
  ///
  /// @param value The chassis identifier string to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::LocationChassis::validateChassisId
  static String? validateChassisId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Chassis ID is required and cannot be empty.';
    }
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Chassis ID must be a valid integer.';
    }
    if (parsed < 0) {
      return 'Chassis ID cannot be negative.';
    }
    if (parsed > 4294967295) {
      return 'Chassis ID exceeds uint32 maximum (4294967295).';
    }
    return null;
  }

  /// Validates a rack-chassis relative-position value against the uint8
  /// constraints defined for the `nil:locations/racks/rack/contained-chassis`
  /// list key.
  ///
  /// The [value] must be a non-negative integer within the uint8 range
  /// (0..255). Null values pass validation — the field is optional when
  /// called as a standalone validator; the parent list key is mandatory at
  /// the data source layer.
  ///
  /// @param value The relative-position value to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::RackChassis::validateRelativePosition
  static String? validateRelativePosition(int? value) {
    if (value == null) return null;
    if (value < 0) {
      return 'Relative position cannot be negative.';
    }
    if (value > 255) {
      return 'Relative position exceeds uint8 maximum (255).';
    }
    return null;
  }

  /// Validates a rack identifier value.
  ///
  /// The `id` field is the mandatory list key for the `nil:locations/racks/rack`
  /// YANG list. Null and empty values are rejected — every rack entry
  /// MUST have a non-empty identifier.
  ///
  /// @param value The rack identifier to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::RackEntity::validateRackId
  static String? validateRackId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Rack ID is required and cannot be empty.';
    }
    return null;
  }

  /// Validates a rack class identityref value.
  ///
  /// The [value] must be one of: `rack-standard`, `rack-secure-baseline`,
  /// `rack-secure-medium`, `rack-secure-high`. Null and empty values pass
  /// validation — the field is optional per the YANG schema.
  ///
  /// @param value The rack class identifier to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::RackEntity::validateRackClass
  static String? validateRackClass(String? value) {
    if (value == null || value.isEmpty) return null;
    const validClasses = [
      'rack-standard',
      'rack-secure-baseline',
      'rack-secure-medium',
      'rack-secure-high',
    ];
    if (!validClasses.contains(value)) {
      return 'Invalid rack class "$value": must be one of '
          'rack-standard, rack-secure-baseline, rack-secure-medium, '
          'rack-secure-high.';
    }
    return null;
  }

  /// Validates a uint32 integer value (range 0..4294967295).
  ///
  /// The [value] is an optional integer. Null values pass validation —
  /// the field is optional per the YANG schema. Values outside the
  /// uint32 range are rejected with a descriptive error message.
  ///
  /// Used for rack placement grid coordinate fields (row-number,
  /// column-number) defined in the `nil:locations/racks/rack/rack-location`
  /// YANG container.
  ///
  /// @param value The integer value to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::RackPlacement::validateUint32
  static String? validateUint32(int? value) {
    if (value == null) return null;
    if (value < 0) {
      return 'Value cannot be negative.';
    }
    if (value > 4294967295) {
      return 'Value exceeds uint32 maximum (4294967295).';
    }
    return null;
  }

  /// Validates a uint16 integer value (range 0..65535).
  ///
  /// The [value] is received as a string from the property grid and must
  /// be parseable to an integer within the uint16 range. Null and empty
  /// values pass validation — the field is optional.
  ///
  /// Used for rack dimension fields (height, width, depth) and power
  /// fields (max-voltage, max-allocated-power) defined in the
  /// `nil:locations/racks/rack` YANG list.
  ///
  /// @param value The string representation of the integer to validate.
  /// @returns An error message string if validation fails, or `null`
  ///          if the value is acceptable.
  ///
  /// @realizes UML::RackEntity::validateUint16
  static String? validateUint16(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return 'Value must be a valid integer.';
    }
    if (parsed < 0) {
      return 'Value cannot be negative.';
    }
    if (parsed > 65535) {
      return 'Value exceeds uint16 maximum (65535).';
    }
    return null;
  }
}
