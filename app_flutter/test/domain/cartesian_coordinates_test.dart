import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/cartesian_coordinates.dart';

void main() {
  group('CartesianCoordinates model', () {
    test('fromMap parses all fields', () {
      final map = {
        'x': 100.0,
        'y': 200.0,
        'z': 300.0,
      };
      final coords = CartesianCoordinates.fromMap(map);

      expect(coords.x, equals(100.0));
      expect(coords.y, equals(200.0));
      expect(coords.z, equals(300.0));
    });

    test('fromMap handles missing fields as null', () {
      final map = <String, dynamic>{
        'x': 100.0,
      };
      final coords = CartesianCoordinates.fromMap(map);

      expect(coords.x, equals(100.0));
      expect(coords.y, isNull);
      expect(coords.z, isNull);
    });

    test('fromMap handles empty map (all null)', () {
      final map = <String, dynamic>{};
      final coords = CartesianCoordinates.fromMap(map);

      expect(coords.x, isNull);
      expect(coords.y, isNull);
      expect(coords.z, isNull);
    });

    test('toMap includes all non-null fields', () {
      final map = {
        'x': 100.0,
        'y': 200.0,
        'z': 300.0,
      };
      final coords = CartesianCoordinates.fromMap(map);
      final result = coords.toMap();

      expect(result['x'], equals(100.0));
      expect(result['y'], equals(200.0));
      expect(result['z'], equals(300.0));
    });

    test('toMap omits null fields', () {
      final map = <String, dynamic>{
        'x': 100.0,
      };
      final coords = CartesianCoordinates.fromMap(map);
      final result = coords.toMap();

      expect(result['x'], equals(100.0));
      expect(result.containsKey('y'), isFalse);
      expect(result.containsKey('z'), isFalse);
    });

    test('toMap handles empty model', () {
      final map = <String, dynamic>{};
      final coords = CartesianCoordinates.fromMap(map);
      final result = coords.toMap();

      expect(result, isEmpty);
    });

    test('toMap round-trip preserves all fields', () {
      final original = {
        'x': 500000.123456,
        'y': -200000.654321,
        'z': 1000.0,
      };
      final coords = CartesianCoordinates.fromMap(original);
      final result = coords.toMap();

      expect(result, equals(original));
    });

    test('isComplete returns true when all three are non-null', () {
      const coords = CartesianCoordinates(x: 1.0, y: 2.0, z: 3.0);
      expect(coords.isComplete, isTrue);
    });

    test('isComplete returns false when x is null', () {
      const coords = CartesianCoordinates(y: 2.0, z: 3.0);
      expect(coords.isComplete, isFalse);
    });

    test('isComplete returns false when y is null', () {
      const coords = CartesianCoordinates(x: 1.0, z: 3.0);
      expect(coords.isComplete, isFalse);
    });

    test('isComplete returns false when z is null', () {
      const coords = CartesianCoordinates(x: 1.0, y: 2.0);
      expect(coords.isComplete, isFalse);
    });

    test('isComplete returns false when all are null', () {
      const coords = CartesianCoordinates();
      expect(coords.isComplete, isFalse);
    });

    group('roundToFracDigits', () {
      test('rounds to 6 fraction digits', () {
        const coords = CartesianCoordinates(
          x: 100.123456789,
          y: 200.987654321,
          z: 300.555555555,
        );
        final rounded = coords.roundToFracDigits(6);

        expect(rounded.x, equals(100.123457));
        expect(rounded.y, equals(200.987654));
        expect(rounded.z, equals(300.555556));
      });

      test('handles null fields without rounding them', () {
        const coords = CartesianCoordinates(x: 100.123456789);
        final rounded = coords.roundToFracDigits(6);

        expect(rounded.x, equals(100.123457));
        expect(rounded.y, isNull);
        expect(rounded.z, isNull);
      });

      test('returns same values when already within precision', () {
        const coords = CartesianCoordinates(
          x: 100.123456,
          y: 200.654321,
        );
        final rounded = coords.roundToFracDigits(6);

        expect(rounded.x, equals(100.123456));
        expect(rounded.y, equals(200.654321));
        expect(rounded.z, isNull);
      });

      test('handles negative values', () {
        const coords = CartesianCoordinates(
          x: -100.123456789,
          y: -200.987654321,
          z: -300.555555555,
        );
        final rounded = coords.roundToFracDigits(6);

        expect(rounded.x, equals(-100.123457));
        expect(rounded.y, equals(-200.987654));
        expect(rounded.z, equals(-300.555556));
      });

      test('handles zero values', () {
        const coords = CartesianCoordinates(x: 0.0, y: 0.0, z: 0.0);
        final rounded = coords.roundToFracDigits(6);

        expect(rounded.x, equals(0.0));
        expect(rounded.y, equals(0.0));
        expect(rounded.z, equals(0.0));
      });

      test('does not mutate the original', () {
        const coords = CartesianCoordinates(x: 100.123456789);
        final rounded = coords.roundToFracDigits(6);

        expect(coords.x, equals(100.123456789));
        expect(rounded.x, equals(100.123457));
      });
    });
  });
}
