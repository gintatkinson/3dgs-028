import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

void main() {
  group('GeoLocationService country code validation', () {
    group('validateCountryCode', () {
      test('accepts null', () {
        final error = GeoLocationService.validateCountryCode(null);
        expect(error, isNull);
      });

      test('accepts empty string', () {
        final error = GeoLocationService.validateCountryCode('');
        expect(error, isNull);
      });

      test('accepts valid two-letter uppercase code "JP"', () {
        final error = GeoLocationService.validateCountryCode('JP');
        expect(error, isNull);
      });

      test('accepts valid two-letter uppercase code "US"', () {
        final error = GeoLocationService.validateCountryCode('US');
        expect(error, isNull);
      });

      test('accepts valid two-letter uppercase code "DE"', () {
        final error = GeoLocationService.validateCountryCode('DE');
        expect(error, isNull);
      });

      test('accepts valid two-letter uppercase code "ZZ"', () {
        final error = GeoLocationService.validateCountryCode('ZZ');
        expect(error, isNull);
      });

      test('rejects lowercase two-letter code "us"', () {
        final error = GeoLocationService.validateCountryCode('us');
        expect(error, isNotNull);
        expect(error, contains('uppercase'));
      });

      test('rejects mixed-case "Us"', () {
        final error = GeoLocationService.validateCountryCode('Us');
        expect(error, isNotNull);
        expect(error, contains('uppercase'));
      });

      test('rejects three-letter code "USA"', () {
        final error = GeoLocationService.validateCountryCode('USA');
        expect(error, isNotNull);
        expect(error, contains('two'));
      });

      test('rejects single letter "U"', () {
        final error = GeoLocationService.validateCountryCode('U');
        expect(error, isNotNull);
        expect(error, contains('two'));
      });

      test('rejects code with digit "U1"', () {
        final error = GeoLocationService.validateCountryCode('U1');
        expect(error, isNotNull);
        expect(error, contains('uppercase'));
      });

      test('rejects code with digit "12"', () {
        final error = GeoLocationService.validateCountryCode('12');
        expect(error, isNotNull);
        expect(error, contains('uppercase'));
      });

      test('rejects empty-ish whitespace "  "', () {
        final error = GeoLocationService.validateCountryCode('  ');
        expect(error, isNotNull);
      });

      test('rejects four-letter code "JAPN"', () {
        final error = GeoLocationService.validateCountryCode('JAPN');
        expect(error, isNotNull);
        expect(error, contains('two'));
      });
    });
  });
}
