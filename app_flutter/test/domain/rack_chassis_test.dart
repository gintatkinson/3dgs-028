import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/rack_chassis.dart';

void main() {
  group('RackChassis model', () {
    test('T1: fromMap parses all fields from snake_case map', () {
      final map = {
        'ne_ref': 'ne-42',
        'component_ref': 'comp-7',
      };
      final chassis = RackChassis.fromMap(7, map);

      expect(chassis.relativePosition, equals(7));
      expect(chassis.neRef, equals('ne-42'));
      expect(chassis.componentRef, equals('comp-7'));
    });

    test('T2: fromMap with only relativePosition sets optional fields to null', () {
      final map = <String, dynamic>{};
      final chassis = RackChassis.fromMap(42, map);

      expect(chassis.relativePosition, equals(42));
      expect(chassis.neRef, isNull);
      expect(chassis.componentRef, isNull);
    });

    test('T3: fromMap with relativePosition 0 is valid (uint8 min)', () {
      final map = {
        'ne_ref': 'ne-zero',
      };
      final chassis = RackChassis.fromMap(0, map);

      expect(chassis.relativePosition, equals(0));
      expect(chassis.neRef, equals('ne-zero'));
      expect(chassis.componentRef, isNull);
    });

    test('T4: fromMap handles uint8 maximum relativePosition', () {
      final map = <String, dynamic>{};
      final chassis = RackChassis.fromMap(255, map);

      expect(chassis.relativePosition, equals(255));
    });

    test('toMap includes only non-null fields', () {
      final chassis = RackChassis(
        relativePosition: 1,
        neRef: 'ne-1',
      );

      final map = chassis.toMap();

      expect(map.containsKey('component_ref'), isFalse);
      expect(map['ne_ref'], equals('ne-1'));
      expect(map.length, equals(1));
    });

    test('toMap includes all fields when all are set', () {
      final chassis = RackChassis(
        relativePosition: 7,
        neRef: 'ne-7',
        componentRef: 'comp-7',
      );

      final map = chassis.toMap();

      expect(map['ne_ref'], equals('ne-7'));
      expect(map['component_ref'], equals('comp-7'));
      expect(map.length, equals(2));
    });

    test('toMap returns empty map when no optional fields set', () {
      final chassis = RackChassis(relativePosition: 99);

      final map = chassis.toMap();

      expect(map, isEmpty);
    });
  });
}
