import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

void main() {
  group('CartesianCoordinates service validation', () {
    group('validateCartesianValue', () {
      test('returns null for null value', () {
        final error = GeoLocationService.validateCartesianValue(null);
        expect(error, isNull);
      });

      test('returns null for 0.0', () {
        final error = GeoLocationService.validateCartesianValue(0.0);
        expect(error, isNull);
      });

      test('returns null for positive value', () {
        final error = GeoLocationService.validateCartesianValue(500000.123456);
        expect(error, isNull);
      });

      test('returns null for negative value', () {
        final error = GeoLocationService.validateCartesianValue(-200000.654321);
        expect(error, isNull);
      });

      test('returns null for small decimal value', () {
        final error = GeoLocationService.validateCartesianValue(0.000001);
        expect(error, isNull);
      });

      test('returns null for large value', () {
        final error = GeoLocationService.validateCartesianValue(999999999.999999);
        expect(error, isNull);
      });

      test('returns error for Double.nan', () {
        final error = GeoLocationService.validateCartesianValue(double.nan);
        expect(error, isNotNull);
        expect(error, contains('valid finite number'));
      });

      test('returns error for Double.infinity', () {
        final error = GeoLocationService.validateCartesianValue(double.infinity);
        expect(error, isNotNull);
        expect(error, contains('valid finite number'));
      });

      test('returns error for Double.negativeInfinity', () {
        final error = GeoLocationService.validateCartesianValue(double.negativeInfinity);
        expect(error, isNotNull);
        expect(error, contains('valid finite number'));
      });
    });
  });
}
