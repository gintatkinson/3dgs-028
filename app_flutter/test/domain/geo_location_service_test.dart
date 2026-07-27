import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

void main() {
  group('GeoLocationService validation', () {
    test('T4: validateTimestamp rejects "not-a-date"', () {
      final error = GeoLocationService.validateTimestamp('not-a-date');
      expect(error, isNotNull);
      expect(error, contains('Invalid'));
    });

    test('T5: validateTimestamp accepts "2022-02-11T12:00:00Z"', () {
      final error = GeoLocationService.validateTimestamp('2022-02-11T12:00:00Z');
      expect(error, isNull);
    });

    test('T6: validateTemporalRelationship rejects inverted (valid-until before timestamp)', () {
      final error = GeoLocationService.validateTemporalRelationship(
        '2022-02-12T12:00:00Z',
        '2022-02-11T12:00:00Z',
      );
      expect(error, isNotNull);
      expect(error, contains('inconsistency'));
    });

    test('validateTemporalRelationship accepts valid ordering', () {
      final error = GeoLocationService.validateTemporalRelationship(
        '2022-02-11T12:00:00Z',
        '2022-02-12T12:00:00Z',
      );
      expect(error, isNull);
    });

    test('validateTimestamp accepts date with milliseconds', () {
      final error = GeoLocationService.validateTimestamp('2022-02-11T12:00:00.123Z');
      expect(error, isNull);
    });

    test('validateTimestamp accepts date with timezone offset', () {
      final error = GeoLocationService.validateTimestamp('2022-02-11T12:00:00+05:30');
      expect(error, isNull);
    });

    test('checkExpiration returns true for expired location', () {
      final location = GeoLocationService.createLocation(
        entityId: 'test',
        timestamp: '2020-01-01T00:00:00Z',
        validUntil: '2020-01-02T00:00:00Z',
      );
      expect(GeoLocationService.checkExpiration(location), isTrue);
    });

    test('prepareSavePayload returns map with provided fields', () {
      final payload = GeoLocationService.prepareSavePayload(
        timestamp: '2022-02-11T12:00:00Z',
        validUntil: '2022-02-12T12:00:00Z',
      );
      expect(payload['timestamp'], equals('2022-02-11T12:00:00Z'));
      expect(payload['valid_until'], equals('2022-02-12T12:00:00Z'));
    });

    test('prepareSavePayload omits null fields', () {
      final payload = GeoLocationService.prepareSavePayload(
        timestamp: '2022-02-11T12:00:00Z',
      );
      expect(payload.containsKey('timestamp'), isTrue);
      expect(payload.containsKey('valid_until'), isFalse);
    });
  });
}
