import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/location_chassis.dart';

void main() {
  group('LocationChassis model', () {
    test('T1: fromMap parses all fields from snake_case map', () {
      final map = {
        'ne_ref': 'ne-42',
        'component_ref': 'comp-7',
      };
      final chassis = LocationChassis.fromMap(1, map);

      expect(chassis.chassisId, equals(1));
      expect(chassis.neRef, equals('ne-42'));
      expect(chassis.componentRef, equals('comp-7'));
    });

    test('T2: fromMap with only chassisId sets optional fields to null', () {
      final map = <String, dynamic>{};
      final chassis = LocationChassis.fromMap(42, map);

      expect(chassis.chassisId, equals(42));
      expect(chassis.neRef, isNull);
      expect(chassis.componentRef, isNull);
    });

    test('T3: fromMap with chassisId 0 is valid', () {
      final map = {
        'ne_ref': 'ne-zero',
      };
      final chassis = LocationChassis.fromMap(0, map);

      expect(chassis.chassisId, equals(0));
      expect(chassis.neRef, equals('ne-zero'));
      expect(chassis.componentRef, isNull);
    });

    test('T4: fromMap handles large uint32 chassisId', () {
      final map = <String, dynamic>{};
      final chassis = LocationChassis.fromMap(4294967295, map);

      expect(chassis.chassisId, equals(4294967295));
    });

    test('toMap includes only non-null fields', () {
      final chassis = LocationChassis(
        chassisId: 1,
        neRef: 'ne-1',
      );

      final map = chassis.toMap();

      expect(map.containsKey('component_ref'), isFalse);
      expect(map['ne_ref'], equals('ne-1'));
      expect(map.length, equals(1));
    });

    test('toMap includes all fields when all are set', () {
      final chassis = LocationChassis(
        chassisId: 7,
        neRef: 'ne-7',
        componentRef: 'comp-7',
      );

      final map = chassis.toMap();

      expect(map['ne_ref'], equals('ne-7'));
      expect(map['component_ref'], equals('comp-7'));
      expect(map.length, equals(2));
    });

    test('toMap returns empty map when no optional fields set', () {
      final chassis = LocationChassis(chassisId: 99);

      final map = chassis.toMap();

      expect(map, isEmpty);
    });
  });
}
