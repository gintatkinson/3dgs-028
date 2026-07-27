import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

void main() {
  group('EllipsoidCoordinates service validation', () {
    group('validateLatitudeEarth', () {
      test('returns null for null value', () {
        final error = GeoLocationService.validateLatitudeEarth(null);
        expect(error, isNull);
      });

      test('returns null for 0.0 (equator)', () {
        final error = GeoLocationService.validateLatitudeEarth(0.0);
        expect(error, isNull);
      });

      test('returns null for positive boundary 90.0', () {
        final error = GeoLocationService.validateLatitudeEarth(90.0);
        expect(error, isNull);
      });

      test('returns null for negative boundary -90.0', () {
        final error = GeoLocationService.validateLatitudeEarth(-90.0);
        expect(error, isNull);
      });

      test('returns null for valid mid-range value', () {
        final error = GeoLocationService.validateLatitudeEarth(35.6895);
        expect(error, isNull);
      });

      test('rejects value above 90', () {
        final error = GeoLocationService.validateLatitudeEarth(90.0001);
        expect(error, isNotNull);
        expect(error, contains('-90 and 90'));
      });

      test('rejects value below -90', () {
        final error = GeoLocationService.validateLatitudeEarth(-90.0001);
        expect(error, isNotNull);
        expect(error, contains('-90 and 90'));
      });

      test('rejects extreme positive value', () {
        final error = GeoLocationService.validateLatitudeEarth(1000.0);
        expect(error, isNotNull);
      });

      test('rejects extreme negative value', () {
        final error = GeoLocationService.validateLatitudeEarth(-1000.0);
        expect(error, isNotNull);
      });
    });

    group('validateLongitudeEarth', () {
      test('returns null for null value', () {
        final error = GeoLocationService.validateLongitudeEarth(null);
        expect(error, isNull);
      });

      test('returns null for 0.0 (prime meridian)', () {
        final error = GeoLocationService.validateLongitudeEarth(0.0);
        expect(error, isNull);
      });

      test('returns null for positive boundary 180.0', () {
        final error = GeoLocationService.validateLongitudeEarth(180.0);
        expect(error, isNull);
      });

      test('returns null for negative boundary -180.0', () {
        final error = GeoLocationService.validateLongitudeEarth(-180.0);
        expect(error, isNull);
      });

      test('returns null for valid mid-range value', () {
        final error = GeoLocationService.validateLongitudeEarth(139.6917);
        expect(error, isNull);
      });

      test('rejects value above 180', () {
        final error = GeoLocationService.validateLongitudeEarth(180.0001);
        expect(error, isNotNull);
        expect(error, contains('-180 and 180'));
      });

      test('rejects value below -180', () {
        final error = GeoLocationService.validateLongitudeEarth(-180.0001);
        expect(error, isNotNull);
        expect(error, contains('-180 and 180'));
      });

      test('rejects extreme positive value', () {
        final error = GeoLocationService.validateLongitudeEarth(500.0);
        expect(error, isNotNull);
      });

      test('rejects extreme negative value', () {
        final error = GeoLocationService.validateLongitudeEarth(-500.0);
        expect(error, isNotNull);
      });
    });

    group('roundDecimal64', () {
      test('rounds to 16 fraction digits', () {
        final result = GeoLocationService.roundDecimal64(35.68951234567890123, 16);
        expect(result, equals(35.6895123456789012));
      });

      test('rounds to 6 fraction digits', () {
        final result = GeoLocationService.roundDecimal64(40.123456789, 6);
        expect(result, equals(40.123457));
      });

      test('no rounding needed when already within precision', () {
        final result = GeoLocationService.roundDecimal64(35.6895, 16);
        expect(result, equals(35.6895));
      });

      test('rounding with zero fraction digits returns integer', () {
        final result = GeoLocationService.roundDecimal64(35.6895, 0);
        expect(result, equals(36.0));
      });

      test('rounding does not mutate the original', () {
        final original = 35.68951234567890123;
        GeoLocationService.roundDecimal64(original, 16);
        expect(original, equals(35.68951234567890123));
      });

      test('rounding negative values', () {
        final result = GeoLocationService.roundDecimal64(-35.68951234567890123, 16);
        expect(result, equals(-35.6895123456789012));
      });

      test('rounding zero', () {
        final result = GeoLocationService.roundDecimal64(0.0, 16);
        expect(result, equals(0.0));
      });
    });
  });
}
