import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/network_inventory_location.dart';

void main() {
  group('NetworkInventoryLocation model', () {
    test('T1: fromMap parses all fields from snake_case map', () {
      final map = {
        'uuid': '550e8400-e29b-41d4-a716-446655440000',
        'name': 'Tokyo Data Center',
        'alias': 'TDC',
        'description': 'Primary data center in Tokyo',
        'type': 'site',
        'parent': 'asia-pacific',
        'timestamp': '2022-02-11T12:00:00Z',
        'valid_until': '2022-02-12T12:00:00Z',
      };
      final location = NetworkInventoryLocation.fromMap('tokyo-dc', map);

      expect(location.id, equals('tokyo-dc'));
      expect(location.uuid, equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(location.name, equals('Tokyo Data Center'));
      expect(location.alias, equals('TDC'));
      expect(location.description, equals('Primary data center in Tokyo'));
      expect(location.type, equals('site'));
      expect(location.parent, equals('asia-pacific'));
      expect(location.timestamp, equals('2022-02-11T12:00:00Z'));
      expect(location.validUntil, equals('2022-02-12T12:00:00Z'));
      expect(location.hasTemporalContext, isTrue);
    });

    test('T2: fromMap with only id sets all optional fields to null', () {
      final map = <String, dynamic>{};
      final location = NetworkInventoryLocation.fromMap('lone-id', map);

      expect(location.id, equals('lone-id'));
      expect(location.uuid, isNull);
      expect(location.name, isNull);
      expect(location.alias, isNull);
      expect(location.description, isNull);
      expect(location.type, isNull);
      expect(location.parent, isNull);
      expect(location.timestamp, isNull);
      expect(location.validUntil, isNull);
      expect(location.hasTemporalContext, isFalse);
    });

    test('T3: isExpired returns true when valid-until is in the past', () {
      final map = {
        'timestamp': '2020-01-01T00:00:00Z',
        'valid_until': '2020-01-02T00:00:00Z',
      };
      final location = NetworkInventoryLocation.fromMap('expired', map);

      expect(location.isExpired, isTrue);
    });

    test('T4: isExpired returns false when no valid-until set', () {
      final map = {
        'timestamp': '2099-01-01T00:00:00Z',
      };
      final location = NetworkInventoryLocation.fromMap('no-expiry', map);

      expect(location.isExpired, isFalse);
      expect(location.hasTemporalContext, isTrue);
    });

    test('T5: isTopLevel returns true when parent is null', () {
      final map = {
        'name': 'Root Location',
      };
      final location = NetworkInventoryLocation.fromMap('root', map);

      expect(location.isTopLevel, isTrue);
    });

    test('T6: isTopLevel returns false when parent is set', () {
      final map = {
        'name': 'Sub Location',
        'parent': 'root-location',
      };
      final location = NetworkInventoryLocation.fromMap('sub', map);

      expect(location.isTopLevel, isFalse);
    });

    test('toMap includes only non-null fields', () {
      final location = NetworkInventoryLocation(
        id: 'test-loc',
        name: 'Test',
        type: 'room',
        timestamp: '2022-02-11T12:00:00Z',
      );

      final map = location.toMap();

      expect(map.containsKey('uuid'), isFalse);
      expect(map.containsKey('alias'), isFalse);
      expect(map.containsKey('description'), isFalse);
      expect(map.containsKey('parent'), isFalse);
      expect(map.containsKey('valid_until'), isFalse);
      expect(map['name'], equals('Test'));
      expect(map['type'], equals('room'));
      expect(map['timestamp'], equals('2022-02-11T12:00:00Z'));
    });

    test('toMap includes all fields when all are set', () {
      final location = NetworkInventoryLocation(
        id: 'full-loc',
        uuid: 'abc-123',
        name: 'Full Location',
        alias: 'FL',
        description: 'All fields populated',
        type: 'site',
        parent: 'global',
        timestamp: '2022-02-11T12:00:00Z',
        validUntil: '2022-02-12T12:00:00Z',
      );

      final map = location.toMap();

      expect(map['uuid'], equals('abc-123'));
      expect(map['name'], equals('Full Location'));
      expect(map['alias'], equals('FL'));
      expect(map['description'], equals('All fields populated'));
      expect(map['type'], equals('site'));
      expect(map['parent'], equals('global'));
      expect(map['timestamp'], equals('2022-02-11T12:00:00Z'));
      expect(map['valid_until'], equals('2022-02-12T12:00:00Z'));
      expect(map.length, equals(8));
    });

    test('isExpired returns false when valid-until is unparseable', () {
      final map = {
        'valid_until': 'not-a-date',
      };
      final location = NetworkInventoryLocation.fromMap('bad-date', map);

      expect(location.isExpired, isFalse);
    });
  });
}
