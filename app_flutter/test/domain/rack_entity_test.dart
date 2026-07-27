import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/rack_entity.dart';

void main() {
  group('RackEntity model', () {
    test('T1: fromMap parses all fields from snake_case map', () {
      final map = {
        'rack_class': 'rack-standard',
        'uuid': '550e8400-e29b-41d4-a716-446655440000',
        'name': 'Rack A-12',
        'alias': 'A12',
        'description': 'Standard rack in aisle A',
        'height': 2200,
        'width': 600,
        'depth': 1000,
        'max_voltage': 230,
        'max_allocated_power': 5000,
        'timestamp': '2022-02-11T12:00:00Z',
        'valid_until': '2022-02-12T12:00:00Z',
      };
      final rack = RackEntity.fromMap('rack-a12', map);

      expect(rack.id, equals('rack-a12'));
      expect(rack.rackClass, equals('rack-standard'));
      expect(rack.uuid, equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(rack.name, equals('Rack A-12'));
      expect(rack.alias, equals('A12'));
      expect(rack.description, equals('Standard rack in aisle A'));
      expect(rack.height, equals(2200));
      expect(rack.width, equals(600));
      expect(rack.depth, equals(1000));
      expect(rack.maxVoltage, equals(230));
      expect(rack.maxAllocatedPower, equals(5000));
      expect(rack.timestamp, equals('2022-02-11T12:00:00Z'));
      expect(rack.validUntil, equals('2022-02-12T12:00:00Z'));
      expect(rack.hasTemporalContext, isTrue);
    });

    test('T2: fromMap with only id sets all optional fields to null', () {
      final map = <String, dynamic>{};
      final rack = RackEntity.fromMap('lone-rack', map);

      expect(rack.id, equals('lone-rack'));
      expect(rack.rackClass, isNull);
      expect(rack.uuid, isNull);
      expect(rack.name, isNull);
      expect(rack.alias, isNull);
      expect(rack.description, isNull);
      expect(rack.height, isNull);
      expect(rack.width, isNull);
      expect(rack.depth, isNull);
      expect(rack.maxVoltage, isNull);
      expect(rack.maxAllocatedPower, isNull);
      expect(rack.timestamp, isNull);
      expect(rack.validUntil, isNull);
      expect(rack.hasTemporalContext, isFalse);
    });

    test('T3: isExpired returns true when valid-until is in the past', () {
      final map = {
        'timestamp': '2020-01-01T00:00:00Z',
        'valid_until': '2020-01-02T00:00:00Z',
      };
      final rack = RackEntity.fromMap('expired-rack', map);

      expect(rack.isExpired, isTrue);
    });

    test('T4: isExpired returns false when no valid-until set', () {
      final map = {
        'timestamp': '2099-01-01T00:00:00Z',
      };
      final rack = RackEntity.fromMap('no-expiry-rack', map);

      expect(rack.isExpired, isFalse);
      expect(rack.hasTemporalContext, isTrue);
    });

    test('T5: isExpired returns false when valid-until is unparseable', () {
      final map = {
        'valid_until': 'not-a-date',
      };
      final rack = RackEntity.fromMap('bad-date-rack', map);

      expect(rack.isExpired, isFalse);
    });

    test('T6: dimension fields handle uint16 boundary values', () {
      final map = {
        'height': 0,
        'width': 65535,
        'depth': 42,
      };
      final rack = RackEntity.fromMap('dimensions', map);

      expect(rack.height, equals(0));
      expect(rack.width, equals(65535));
      expect(rack.depth, equals(42));
    });

    test('T7: power fields handle uint16 boundary values', () {
      final map = {
        'max_voltage': 0,
        'max_allocated_power': 65535,
      };
      final rack = RackEntity.fromMap('power', map);

      expect(rack.maxVoltage, equals(0));
      expect(rack.maxAllocatedPower, equals(65535));
    });

    test('toMap includes only non-null fields', () {
      final rack = RackEntity(
        id: 'test-rack',
        name: 'Test Rack',
        rackClass: 'rack-secure-medium',
        height: 2000,
      );

      final map = rack.toMap();

      expect(map.containsKey('uuid'), isFalse);
      expect(map.containsKey('alias'), isFalse);
      expect(map.containsKey('description'), isFalse);
      expect(map.containsKey('width'), isFalse);
      expect(map.containsKey('depth'), isFalse);
      expect(map.containsKey('max_voltage'), isFalse);
      expect(map.containsKey('max_allocated_power'), isFalse);
      expect(map.containsKey('timestamp'), isFalse);
      expect(map.containsKey('valid_until'), isFalse);
      expect(map['name'], equals('Test Rack'));
      expect(map['rack_class'], equals('rack-secure-medium'));
      expect(map['height'], equals(2000));
    });

    test('toMap includes all fields when all are set', () {
      final rack = RackEntity(
        id: 'full-rack',
        rackClass: 'rack-secure-high',
        uuid: 'abc-123',
        name: 'Full Rack',
        alias: 'FR',
        description: 'All fields populated',
        height: 2200,
        width: 600,
        depth: 1000,
        maxVoltage: 230,
        maxAllocatedPower: 5000,
        timestamp: '2022-02-11T12:00:00Z',
        validUntil: '2022-02-12T12:00:00Z',
      );

      final map = rack.toMap();

      expect(map['rack_class'], equals('rack-secure-high'));
      expect(map['uuid'], equals('abc-123'));
      expect(map['name'], equals('Full Rack'));
      expect(map['alias'], equals('FR'));
      expect(map['description'], equals('All fields populated'));
      expect(map['height'], equals(2200));
      expect(map['width'], equals(600));
      expect(map['depth'], equals(1000));
      expect(map['max_voltage'], equals(230));
      expect(map['max_allocated_power'], equals(5000));
      expect(map['timestamp'], equals('2022-02-11T12:00:00Z'));
      expect(map['valid_until'], equals('2022-02-12T12:00:00Z'));
      expect(map.length, equals(12));
    });
  });
}
