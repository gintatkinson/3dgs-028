import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

void main() {
  group('GeodeticSystem service validation', () {
    group('validateGeodeticDatum', () {
      test('returns null for null value', () {
        final error = GeoLocationService.validateGeodeticDatum(null);
        expect(error, isNull);
      });

      test('returns null for empty string', () {
        final error = GeoLocationService.validateGeodeticDatum('');
        expect(error, isNull);
      });

      test('accepts "wgs-84" (IANA standard Earth datum)', () {
        final error = GeoLocationService.validateGeodeticDatum('wgs-84');
        expect(error, isNull);
      });

      test('accepts "me" (lunar datum)', () {
        final error = GeoLocationService.validateGeodeticDatum('me');
        expect(error, isNull);
      });

      test('accepts "MOON" (normalized to lowercase)', () {
        final error = GeoLocationService.validateGeodeticDatum('MOON');
        expect(error, isNull);
      });

      test('rejects control characters (newline)', () {
        final error = GeoLocationService.validateGeodeticDatum('tes\nname');
        expect(error, isNotNull);
        expect(error, contains('Invalid'));
      });

      test('rejects DEL character (0x7f)', () {
        final error = GeoLocationService.validateGeodeticDatum('test\x7fname');
        expect(error, isNotNull);
        expect(error, contains('Invalid'));
      });

      test('rejects tab character', () {
        final error = GeoLocationService.validateGeodeticDatum('test\tname');
        expect(error, isNotNull);
        expect(error, contains('Invalid'));
      });

      test('accepts valid space characters with normalization', () {
        final error = GeoLocationService.validateGeodeticDatum('WGS 84');
        expect(error, isNull);
      });

      test('accepts printable ASCII symbols', () {
        final error = GeoLocationService.validateGeodeticDatum('test!@#\$%^&*()_+-=[]{}|;:,.<>?/~`');
        expect(error, isNull);
      });
    });

    group('normalizeGeodeticDatum', () {
      test('lowercases "WGS-84" to "wgs-84"', () {
        expect(
          GeoLocationService.normalizeGeodeticDatum('WGS-84'),
          equals('wgs-84'),
        );
      });

      test('converts spaces to dashes in "WGS 84"', () {
        expect(
          GeoLocationService.normalizeGeodeticDatum('WGS 84'),
          equals('wgs-84'),
        );
      });

      test('lowercases and normalizes "Lunar ME" to "lunar-me"', () {
        expect(
          GeoLocationService.normalizeGeodeticDatum('Lunar ME'),
          equals('lunar-me'),
        );
      });

      test('preserves special characters while normalizing', () {
        expect(
          GeoLocationService.normalizeGeodeticDatum('67P-Churyumov Gerasimenko'),
          equals('67p-churyumov-gerasimenko'),
        );
      });

      test('collapses multiple spaces', () {
        expect(
          GeoLocationService.normalizeGeodeticDatum('EARTH   MOON'),
          equals('earth---moon'),
        );
      });

      test('no-op on already normalized value', () {
        expect(
          GeoLocationService.normalizeGeodeticDatum('wgs-84'),
          equals('wgs-84'),
        );
      });
    });

    group('validateCoordinateAccuracy', () {
      test('returns null for null value', () {
        final error = GeoLocationService.validateCoordinateAccuracy(null);
        expect(error, isNull);
      });

      test('returns null for zero', () {
        final error = GeoLocationService.validateCoordinateAccuracy(0.0);
        expect(error, isNull);
      });

      test('returns null for positive value', () {
        final error = GeoLocationService.validateCoordinateAccuracy(1.5);
        expect(error, isNull);
      });

      test('rejects negative value', () {
        final error = GeoLocationService.validateCoordinateAccuracy(-0.001);
        expect(error, isNotNull);
        expect(error, contains('negative'));
      });

      test('rejects negative maximum double', () {
        final error = GeoLocationService.validateCoordinateAccuracy(-1.7976931348623157e308);
        expect(error, isNotNull);
      });
    });

    group('validateHeightAccuracy', () {
      test('returns null for null value', () {
        final error = GeoLocationService.validateHeightAccuracy(null);
        expect(error, isNull);
      });

      test('returns null for zero', () {
        final error = GeoLocationService.validateHeightAccuracy(0.0);
        expect(error, isNull);
      });

      test('returns null for positive value', () {
        final error = GeoLocationService.validateHeightAccuracy(2.3);
        expect(error, isNull);
      });

      test('rejects negative value', () {
        final error = GeoLocationService.validateHeightAccuracy(-0.5);
        expect(error, isNotNull);
        expect(error, contains('negative'));
      });

      test('rejects negative integer', () {
        final error = GeoLocationService.validateHeightAccuracy(-1.0);
        expect(error, isNotNull);
      });
    });
  });
}
