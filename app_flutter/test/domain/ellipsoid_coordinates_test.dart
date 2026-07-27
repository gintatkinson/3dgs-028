import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/ellipsoid_coordinates.dart';

void main() {
  group('EllipsoidCoordinates model', () {
    test('fromMap parses all fields', () {
      final map = {
        'latitude': 35.6895,
        'longitude': 139.6917,
        'height': 40.0,
      };
      final coords = EllipsoidCoordinates.fromMap(map);

      expect(coords.latitude, equals(35.6895));
      expect(coords.longitude, equals(139.6917));
      expect(coords.height, equals(40.0));
    });

    test('fromMap handles missing fields as null', () {
      final map = <String, dynamic>{
        'latitude': 35.0,
      };
      final coords = EllipsoidCoordinates.fromMap(map);

      expect(coords.latitude, equals(35.0));
      expect(coords.longitude, isNull);
      expect(coords.height, isNull);
    });

    test('fromMap handles empty map (all null)', () {
      final map = <String, dynamic>{};
      final coords = EllipsoidCoordinates.fromMap(map);

      expect(coords.latitude, isNull);
      expect(coords.longitude, isNull);
      expect(coords.height, isNull);
    });

    test('toMap includes all non-null fields', () {
      final map = {
        'latitude': 35.6895,
        'longitude': 139.6917,
        'height': 40.0,
      };
      final coords = EllipsoidCoordinates.fromMap(map);
      final result = coords.toMap();

      expect(result['latitude'], equals(35.6895));
      expect(result['longitude'], equals(139.6917));
      expect(result['height'], equals(40.0));
    });

    test('toMap omits null fields', () {
      final map = <String, dynamic>{
        'latitude': 35.0,
      };
      final coords = EllipsoidCoordinates.fromMap(map);
      final result = coords.toMap();

      expect(result['latitude'], equals(35.0));
      expect(result.containsKey('longitude'), isFalse);
      expect(result.containsKey('height'), isFalse);
    });

    test('toMap handles empty model', () {
      final map = <String, dynamic>{};
      final coords = EllipsoidCoordinates.fromMap(map);
      final result = coords.toMap();

      expect(result, isEmpty);
    });

    test('toMap round-trip preserves all fields', () {
      final original = {
        'latitude': -33.8688,
        'longitude': 151.2093,
        'height': 58.0,
      };
      final coords = EllipsoidCoordinates.fromMap(original);
      final result = coords.toMap();

      expect(result, equals(original));
    });

    test('isOnEarth defaults to true', () {
      final coords = EllipsoidCoordinates(
        latitude: 35.0,
        longitude: 139.0,
      );

      expect(coords.isOnEarth, isTrue);
    });

    test('isWithinEarthRange returns true for valid coordinates', () {
      final coords = EllipsoidCoordinates(
        latitude: 35.6895,
        longitude: 139.6917,
      );

      expect(coords.isWithinEarthRange, isTrue);
    });

    test('isWithinEarthRange returns true for boundary values', () {
      final coords = EllipsoidCoordinates(
        latitude: 90.0,
        longitude: 180.0,
      );

      expect(coords.isWithinEarthRange, isTrue);
    });

    test('isWithinEarthRange returns true for negative boundary values', () {
      final coords = EllipsoidCoordinates(
        latitude: -90.0,
        longitude: -180.0,
      );

      expect(coords.isWithinEarthRange, isTrue);
    });

    test('isWithinEarthRange returns false for latitude > 90', () {
      final coords = EllipsoidCoordinates(
        latitude: 90.0001,
        longitude: 139.0,
      );

      expect(coords.isWithinEarthRange, isFalse);
    });

    test('isWithinEarthRange returns false for latitude < -90', () {
      final coords = EllipsoidCoordinates(
        latitude: -90.0001,
        longitude: 139.0,
      );

      expect(coords.isWithinEarthRange, isFalse);
    });

    test('isWithinEarthRange returns false for longitude > 180', () {
      final coords = EllipsoidCoordinates(
        latitude: 35.0,
        longitude: 180.0001,
      );

      expect(coords.isWithinEarthRange, isFalse);
    });

    test('isWithinEarthRange returns false for longitude < -180', () {
      final coords = EllipsoidCoordinates(
        latitude: 35.0,
        longitude: -180.0001,
      );

      expect(coords.isWithinEarthRange, isFalse);
    });

    test('isWithinEarthRange returns true when latitude is null', () {
      final coords = EllipsoidCoordinates(
        longitude: 139.0,
      );

      expect(coords.isWithinEarthRange, isTrue);
    });

    test('isWithinEarthRange returns true when longitude is null', () {
      final coords = EllipsoidCoordinates(
        latitude: 200.0,
      );

      expect(coords.isWithinEarthRange, isFalse);
    });

    test('isWithinEarthRange returns true for all null fields', () {
      const coords = EllipsoidCoordinates();

      expect(coords.isWithinEarthRange, isTrue);
    });
  });
}
