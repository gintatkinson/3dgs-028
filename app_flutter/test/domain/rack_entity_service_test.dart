import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

void main() {
  group('GeoLocationService rack validation', () {
    group('validateRackId', () {
      test('accepts non-empty string', () {
        expect(GeoLocationService.validateRackId('rack-01'), isNull);
      });

      test('rejects null', () {
        final error = GeoLocationService.validateRackId(null);
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('rejects empty string', () {
        final error = GeoLocationService.validateRackId('');
        expect(error, isNotNull);
        expect(error, contains('required'));
      });

      test('accepts whitespace-only string', () {
        expect(GeoLocationService.validateRackId('   '), isNull);
      });
    });

    group('validateRackClass', () {
      test('accepts rack-standard', () {
        expect(
          GeoLocationService.validateRackClass('rack-standard'),
          isNull,
        );
      });

      test('accepts rack-secure-baseline', () {
        expect(
          GeoLocationService.validateRackClass('rack-secure-baseline'),
          isNull,
        );
      });

      test('accepts rack-secure-medium', () {
        expect(
          GeoLocationService.validateRackClass('rack-secure-medium'),
          isNull,
        );
      });

      test('accepts rack-secure-high', () {
        expect(
          GeoLocationService.validateRackClass('rack-secure-high'),
          isNull,
        );
      });

      test('rejects invalid rack class', () {
        final error = GeoLocationService.validateRackClass('invalid-class');
        expect(error, isNotNull);
        expect(error, contains('rack-standard'));
        expect(error, contains('rack-secure-baseline'));
      });

      test('accepts null', () {
        expect(GeoLocationService.validateRackClass(null), isNull);
      });

      test('accepts empty string', () {
        expect(GeoLocationService.validateRackClass(''), isNull);
      });
    });

    group('validateUint16', () {
      test('accepts 0', () {
        expect(GeoLocationService.validateUint16('0'), isNull);
      });

      test('accepts 65535', () {
        expect(GeoLocationService.validateUint16('65535'), isNull);
      });

      test('accepts mid-range value', () {
        expect(GeoLocationService.validateUint16('32000'), isNull);
      });

      test('rejects negative value', () {
        final error = GeoLocationService.validateUint16('-1');
        expect(error, isNotNull);
        expect(error, contains('negative'));
      });

      test('rejects value above 65535', () {
        final error = GeoLocationService.validateUint16('65536');
        expect(error, isNotNull);
        expect(error, contains('65535'));
      });

      test('rejects non-numeric string', () {
        final error = GeoLocationService.validateUint16('abc');
        expect(error, isNotNull);
        expect(error, contains('integer'));
      });

      test('accepts null', () {
        expect(GeoLocationService.validateUint16(null), isNull);
      });

      test('accepts empty string', () {
        expect(GeoLocationService.validateUint16(''), isNull);
      });

      test('rejects floating-point string', () {
        final error = GeoLocationService.validateUint16('3.14');
        expect(error, isNotNull);
        expect(error, contains('integer'));
      });
    });
  });
}
