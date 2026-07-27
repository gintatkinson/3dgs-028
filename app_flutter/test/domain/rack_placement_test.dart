import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/rack_placement.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

void main() {
  group('RackPlacement model', () {
    test('T1: fromMap parses all fields from snake_case map', () {
      final map = {
        'location_ref': 'loc-building-a',
        'row_number': 3,
        'column_number': 7,
      };
      final placement = RackPlacement.fromMap(map);

      expect(placement.locationRef, equals('loc-building-a'));
      expect(placement.rowNumber, equals(3));
      expect(placement.columnNumber, equals(7));
    });

    test('T2: fromMap with empty map sets all fields to null', () {
      final map = <String, dynamic>{};
      final placement = RackPlacement.fromMap(map);

      expect(placement.locationRef, isNull);
      expect(placement.rowNumber, isNull);
      expect(placement.columnNumber, isNull);
    });

    test('T3: fromMap handles uint32 boundary values', () {
      final map = {
        'row_number': 0,
        'column_number': 4294967295,
      };
      final placement = RackPlacement.fromMap(map);

      expect(placement.rowNumber, equals(0));
      expect(placement.columnNumber, equals(4294967295));
    });

    test('T4: toMap includes only non-null fields', () {
      final placement = RackPlacement(
        locationRef: 'loc-a1',
        rowNumber: 5,
      );

      final map = placement.toMap();

      expect(map.containsKey('column_number'), isFalse);
      expect(map['location_ref'], equals('loc-a1'));
      expect(map['row_number'], equals(5));
      expect(map.length, equals(2));
    });

    test('T5: toMap includes all fields when all are set', () {
      final placement = RackPlacement(
        locationRef: 'loc-a1',
        rowNumber: 5,
        columnNumber: 10,
      );

      final map = placement.toMap();

      expect(map['location_ref'], equals('loc-a1'));
      expect(map['row_number'], equals(5));
      expect(map['column_number'], equals(10));
      expect(map.length, equals(3));
    });

    test('T6: toMap returns empty map when no fields set', () {
      final placement = RackPlacement();

      final map = placement.toMap();

      expect(map, isEmpty);
    });
  });

  group('GeoLocationService.validateUint32', () {
    test('returns null for null value', () {
      final error = GeoLocationService.validateUint32(null);
      expect(error, isNull);
    });

    test('returns null for zero', () {
      final error = GeoLocationService.validateUint32(0);
      expect(error, isNull);
    });

    test('returns null for max uint32 value', () {
      final error = GeoLocationService.validateUint32(4294967295);
      expect(error, isNull);
    });

    test('returns error for negative value', () {
      final error = GeoLocationService.validateUint32(-1);
      expect(error, isNotNull);
      expect(error, contains('negative'));
    });

    test('returns error for value exceeding uint32 max', () {
      final error = GeoLocationService.validateUint32(4294967296);
      expect(error, isNotNull);
      expect(error, contains('exceeds uint32 maximum'));
    });

    test('returns null for mid-range value', () {
      final error = GeoLocationService.validateUint32(100);
      expect(error, isNull);
    });
  });
}
