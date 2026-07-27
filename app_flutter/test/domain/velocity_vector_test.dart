import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/velocity_vector.dart';

void main() {
  group('VelocityVector model', () {
    test('fromMap parses all three fields', () {
      final map = {
        'v_north': 10.0,
        'v_east': 5.0,
        'v_up': 1.5,
      };
      final vv = VelocityVector.fromMap(map);

      expect(vv.vNorth, equals(10.0));
      expect(vv.vEast, equals(5.0));
      expect(vv.vUp, equals(1.5));
    });

    test('fromMap handles missing fields as null', () {
      final map = <String, dynamic>{
        'v_north': 10.0,
      };
      final vv = VelocityVector.fromMap(map);

      expect(vv.vNorth, equals(10.0));
      expect(vv.vEast, isNull);
      expect(vv.vUp, isNull);
    });

    test('fromMap handles empty map (all null)', () {
      final map = <String, dynamic>{};
      final vv = VelocityVector.fromMap(map);

      expect(vv.vNorth, isNull);
      expect(vv.vEast, isNull);
      expect(vv.vUp, isNull);
    });

    test('toMap includes all non-null fields', () {
      final map = {
        'v_north': 10.0,
        'v_east': 5.0,
        'v_up': 1.5,
      };
      final vv = VelocityVector.fromMap(map);
      final result = vv.toMap();

      expect(result['v_north'], equals(10.0));
      expect(result['v_east'], equals(5.0));
      expect(result['v_up'], equals(1.5));
    });

    test('toMap omits null fields', () {
      final map = <String, dynamic>{
        'v_north': 10.0,
      };
      final vv = VelocityVector.fromMap(map);
      final result = vv.toMap();

      expect(result['v_north'], equals(10.0));
      expect(result.containsKey('v_east'), isFalse);
      expect(result.containsKey('v_up'), isFalse);
    });

    test('toMap handles empty model', () {
      final map = <String, dynamic>{};
      final vv = VelocityVector.fromMap(map);
      final result = vv.toMap();

      expect(result, isEmpty);
    });

    test('toMap round-trip preserves all fields', () {
      final original = {
        'v_north': 100.123456789012,
        'v_east': -50.987654321098,
        'v_up': 25.5,
      };
      final vv = VelocityVector.fromMap(original);
      final result = vv.toMap();

      expect(result, equals(original));
    });

    test('toMap does not include derived values (speed, heading)', () {
      final map = {
        'v_north': 3.0,
        'v_east': 4.0,
      };
      final vv = VelocityVector.fromMap(map);
      final result = vv.toMap();

      expect(result.containsKey('speed'), isFalse);
      expect(result.containsKey('heading'), isFalse);
    });

    group('computeSpeed', () {
      test('returns correct speed for 3-4-5 triangle', () {
        const vv = VelocityVector(vNorth: 3.0, vEast: 4.0);
        final speed = vv.computeSpeed();

        expect(speed, isNotNull);
        expect(speed, closeTo(5.0, 1e-12));
      });

      test('returns null when vNorth is null', () {
        const vv = VelocityVector(vEast: 4.0);
        final speed = vv.computeSpeed();

        expect(speed, isNull);
      });

      test('returns null when vEast is null', () {
        const vv = VelocityVector(vNorth: 3.0);
        final speed = vv.computeSpeed();

        expect(speed, isNull);
      });

      test('returns null when both are null', () {
        const vv = VelocityVector();
        final speed = vv.computeSpeed();

        expect(speed, isNull);
      });

      test('returns 0 when both are 0', () {
        const vv = VelocityVector(vNorth: 0.0, vEast: 0.0);
        final speed = vv.computeSpeed();

        expect(speed, equals(0.0));
      });

      test('handles negative vNorth', () {
        const vv = VelocityVector(vNorth: -3.0, vEast: 4.0);
        final speed = vv.computeSpeed();

        expect(speed, closeTo(5.0, 1e-12));
      });

      test('handles negative vEast', () {
        const vv = VelocityVector(vNorth: 3.0, vEast: -4.0);
        final speed = vv.computeSpeed();

        expect(speed, closeTo(5.0, 1e-12));
      });
    });

    group('computeHeading', () {
      test('north direction (vNorth>0, vEast=0) returns 0 rad', () {
        const vv = VelocityVector(vNorth: 10.0, vEast: 0.0);
        final heading = vv.computeHeading();

        expect(heading, isNotNull);
        expect(heading, closeTo(0.0, 1e-12));
      });

      test('east direction (vNorth=0, vEast>0) returns π/2 rad', () {
        const vv = VelocityVector(vNorth: 0.0, vEast: 10.0);
        final heading = vv.computeHeading();

        expect(heading, isNotNull);
        expect(heading, closeTo(math.pi / 2, 1e-12));
      });

      test('south direction (vNorth<0, vEast=0) returns π rad', () {
        const vv = VelocityVector(vNorth: -10.0, vEast: 0.0);
        final heading = vv.computeHeading();

        expect(heading, isNotNull);
        expect(heading, closeTo(math.pi, 1e-12));
      });

      test('west direction (vNorth=0, vEast<0) returns -π/2 rad', () {
        const vv = VelocityVector(vNorth: 0.0, vEast: -10.0);
        final heading = vv.computeHeading();

        expect(heading, isNotNull);
        expect(heading, closeTo(-math.pi / 2, 1e-12));
      });

      test('returns null when vNorth and vEast are both 0', () {
        const vv = VelocityVector(vNorth: 0.0, vEast: 0.0);
        final heading = vv.computeHeading();

        expect(heading, isNull);
      });

      test('returns null when vNorth is null', () {
        const vv = VelocityVector(vEast: 4.0);
        final heading = vv.computeHeading();

        expect(heading, isNull);
      });

      test('returns null when vEast is null', () {
        const vv = VelocityVector(vNorth: 3.0);
        final heading = vv.computeHeading();

        expect(heading, isNull);
      });
    });

    group('computeHeadingDegrees', () {
      test('north direction returns 0°', () {
        const vv = VelocityVector(vNorth: 10.0, vEast: 0.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNotNull);
        expect(deg, closeTo(0.0, 1e-10));
      });

      test('east direction (vNorth=0, vEast>0) returns 90°', () {
        const vv = VelocityVector(vNorth: 0.0, vEast: 10.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNotNull);
        expect(deg, closeTo(90.0, 1e-10));
      });

      test('south direction returns 180°', () {
        const vv = VelocityVector(vNorth: -10.0, vEast: 0.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNotNull);
        expect(deg, closeTo(180.0, 1e-10));
      });

      test('west direction (vNorth=0, vEast<0) returns 270°', () {
        const vv = VelocityVector(vNorth: 0.0, vEast: -10.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNotNull);
        expect(deg, closeTo(270.0, 1e-10));
      });

      test('returns null when both vNorth and vEast are 0', () {
        const vv = VelocityVector(vNorth: 0.0, vEast: 0.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNull);
      });

      test('returns null when vNorth is null', () {
        const vv = VelocityVector(vEast: 4.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNull);
      });

      test('returns null when vEast is null', () {
        const vv = VelocityVector(vNorth: 3.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNull);
      });

      test('northeast quadrant returns between 0° and 90°', () {
        const vv = VelocityVector(vNorth: 1.0, vEast: 1.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNotNull);
        expect(deg, closeTo(45.0, 1e-10));
      });

      test('southeast quadrant returns between 90° and 180°', () {
        const vv = VelocityVector(vNorth: -1.0, vEast: 1.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNotNull);
        expect(deg, closeTo(135.0, 1e-10));
      });

      test('southwest quadrant returns between 180° and 270°', () {
        const vv = VelocityVector(vNorth: -1.0, vEast: -1.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNotNull);
        expect(deg, closeTo(225.0, 1e-10));
      });

      test('northwest quadrant returns between 270° and 360°', () {
        const vv = VelocityVector(vNorth: 1.0, vEast: -1.0);
        final deg = vv.computeHeadingDegrees();

        expect(deg, isNotNull);
        expect(deg, closeTo(315.0, 1e-10));
      });
    });
  });
}
