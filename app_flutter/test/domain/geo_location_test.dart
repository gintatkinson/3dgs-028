import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geo_location.dart';

void main() {
  group('GeoLocation model', () {
    test('T1: fromMap parses valid timestamp and valid-until', () {
      final map = {
        'timestamp': '2022-02-11T12:00:00Z',
        'valid_until': '2022-02-12T12:00:00Z',
      };
      final location = GeoLocation.fromMap('entity-1', map);

      expect(location.entityId, equals('entity-1'));
      expect(location.timestamp, equals('2022-02-11T12:00:00Z'));
      expect(location.validUntil, equals('2022-02-12T12:00:00Z'));
      expect(location.hasTemporalContext, isTrue);
    });

    test('T2: isExpired returns true when valid-until is in the past', () {
      final map = {
        'timestamp': '2020-01-01T00:00:00Z',
        'valid_until': '2020-01-02T00:00:00Z',
      };
      final location = GeoLocation.fromMap('entity-2', map);

      expect(location.isExpired, isTrue);
    });

    test('T3: isExpired returns false when no valid-until', () {
      final map = {
        'timestamp': '2099-01-01T00:00:00Z',
      };
      final location = GeoLocation.fromMap('entity-3', map);

      expect(location.isExpired, isFalse);
      expect(location.hasTemporalContext, isTrue);
    });

    test('fromMap handles missing timestamp', () {
      final map = <String, dynamic>{};
      final location = GeoLocation.fromMap('entity-4', map);

      expect(location.timestamp, isNull);
      expect(location.validUntil, isNull);
      expect(location.hasTemporalContext, isFalse);
      expect(location.isExpired, isFalse);
    });
  });
}
