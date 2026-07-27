import 'geo_location.dart';

class GeoLocationService {
  static const _dateTimePattern =
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$';
  static const _bodyPattern = r'^[ -@\[-\^_-~]*$';

  static String? validateAstronomicalBody(String? value) {
    if (value == null || value.isEmpty) return null;
    final regex = RegExp(_bodyPattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid astronomical body: contains characters outside the allowed set [ -@[\\-\\^_-~].';
    }
    return null;
  }

  static String normalizeAstronomicalBody(String value) {
    return value.toLowerCase();
  }

  static String? validateAlternateSystem(String? value, bool featureEnabled) {
    if (value != null && !featureEnabled) {
      return 'Alternate system set but feature is not enabled.';
    }
    return null;
  }

  static String? validateTimestamp(String value) {
    final regex = RegExp(_dateTimePattern);
    if (!regex.hasMatch(value)) {
      return 'Invalid timestamp format. Expected RFC 6991 date-and-time (e.g. 2022-02-11T12:00:00Z).';
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return 'Invalid timestamp: cannot parse as a valid date-time.';
    }
    return null;
  }

  static String? validateTemporalRelationship(String timestamp, String validUntil) {
    final ts = DateTime.tryParse(timestamp);
    final vu = DateTime.tryParse(validUntil);
    if (ts == null || vu == null) {
      return null;
    }
    if (vu.toUtc().isBefore(ts.toUtc())) {
      return 'Temporal inconsistency: valid-until ($validUntil) is before timestamp ($timestamp).';
    }
    return null;
  }

  static bool checkExpiration(GeoLocation location) {
    return location.isExpired;
  }

  static Map<String, dynamic> prepareSavePayload({String? timestamp, String? validUntil}) {
    return {
      if (timestamp != null) 'timestamp': timestamp,
      if (validUntil != null) 'valid_until': validUntil,
    };
  }

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
