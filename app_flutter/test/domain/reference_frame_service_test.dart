import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

void main() {
  group('ReferenceFrame service validation', () {
    group('validateAstronomicalBody', () {
      test('returns null for "earth"', () {
        final error = GeoLocationService.validateAstronomicalBody('earth');
        expect(error, isNull);
      });

      test('returns null for "moon"', () {
        final error = GeoLocationService.validateAstronomicalBody('moon');
        expect(error, isNull);
      });

      test('returns null for "67p/churyumov-gerasimenko"', () {
        final error = GeoLocationService.validateAstronomicalBody('67p/churyumov-gerasimenko');
        expect(error, isNull);
      });

      test('returns null for special characters like lowercase letters and digits', () {
        final error = GeoLocationService.validateAstronomicalBody('abc123');
        expect(error, isNull);
      });

      test('returns null for printable ASCII symbols only', () {
        final error = GeoLocationService.validateAstronomicalBody('test!@#\$%^&*()_+-=[]{}|;:,.<>?/~`');
        expect(error, isNull);
      });

      test('rejects null byte (0x00)', () {
        final error = GeoLocationService.validateAstronomicalBody('test\x00name');
        expect(error, isNotNull);
        expect(error, contains('Invalid'));
      });

      test('rejects control characters like newline', () {
        final error = GeoLocationService.validateAstronomicalBody('test\nname');
        expect(error, isNotNull);
        expect(error, contains('Invalid'));
      });

      test('rejects tab character', () {
        final error = GeoLocationService.validateAstronomicalBody('test\tname');
        expect(error, isNotNull);
        expect(error, contains('Invalid'));
      });

      test('rejects DEL character (0x7f)', () {
        final error = GeoLocationService.validateAstronomicalBody('test\x7fname');
        expect(error, isNotNull);
        expect(error, contains('Invalid'));
      });

      test('returns null for null value', () {
        final error = GeoLocationService.validateAstronomicalBody(null);
        expect(error, isNull);
      });

      test('returns null for empty string', () {
        final error = GeoLocationService.validateAstronomicalBody('');
        expect(error, isNull);
      });

      test('returns null for space character', () {
        final error = GeoLocationService.validateAstronomicalBody(' ');
        expect(error, isNull);
      });
    });

    group('normalizeAstronomicalBody', () {
      test('lowercases "EARTH" to "earth"', () {
        expect(GeoLocationService.normalizeAstronomicalBody('EARTH'), equals('earth'));
      });

      test('lowercases "Moon" to "moon"', () {
        expect(GeoLocationService.normalizeAstronomicalBody('Moon'), equals('moon'));
      });

      test('lowercases "MARS" to "mars"', () {
        expect(GeoLocationService.normalizeAstronomicalBody('MARS'), equals('mars'));
      });

      test('lowercases mixed case "EaRtH" to "earth"', () {
        expect(GeoLocationService.normalizeAstronomicalBody('EaRtH'), equals('earth'));
      });

      test('preserves special characters while lowercasing', () {
        expect(
          GeoLocationService.normalizeAstronomicalBody('67P/Churyumov-Gerasimenko'),
          equals('67p/churyumov-gerasimenko'),
        );
      });
    });

    group('validateAlternateSystem', () {
      test('returns null when feature is enabled and value is present', () {
        final error = GeoLocationService.validateAlternateSystem('IAU', true);
        expect(error, isNull);
      });

      test('returns error when feature is disabled but value is present', () {
        final error = GeoLocationService.validateAlternateSystem('IAU', false);
        expect(error, isNotNull);
        expect(error, contains('Alternate system'));
      });

      test('returns null when feature is disabled and value is null', () {
        final error = GeoLocationService.validateAlternateSystem(null, false);
        expect(error, isNull);
      });

      test('returns null when value is null regardless of feature flag', () {
        expect(GeoLocationService.validateAlternateSystem(null, true), isNull);
        expect(GeoLocationService.validateAlternateSystem(null, false), isNull);
      });
    });
  });
}
