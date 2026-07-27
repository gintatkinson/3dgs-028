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
}
