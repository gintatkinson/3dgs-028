import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/velocity_utility.dart';

void main() {
  group('VelocityUtility', () {
    group('computeSpeed', () {
      test('returns correct speed for positive components', () {
        final speed = VelocityUtility.computeSpeed(3.0, 4.0);

        expect(speed, isNotNull);
        expect(speed, closeTo(5.0, 1e-12));
      });

      test('returns null when vNorth is null', () {
        final speed = VelocityUtility.computeSpeed(null, 4.0);

        expect(speed, isNull);
      });

      test('returns null when vEast is null', () {
        final speed = VelocityUtility.computeSpeed(3.0, null);

        expect(speed, isNull);
      });

      test('returns null when both are null', () {
        final speed = VelocityUtility.computeSpeed(null, null);

        expect(speed, isNull);
      });

      test('returns 0 when both are 0', () {
        final speed = VelocityUtility.computeSpeed(0.0, 0.0);

        expect(speed, equals(0.0));
      });

      test('handles negative vNorth', () {
        final speed = VelocityUtility.computeSpeed(-3.0, 4.0);

        expect(speed, closeTo(5.0, 1e-12));
      });

      test('handles negative vEast', () {
        final speed = VelocityUtility.computeSpeed(3.0, -4.0);

        expect(speed, closeTo(5.0, 1e-12));
      });

      test('handles both negative', () {
        final speed = VelocityUtility.computeSpeed(-3.0, -4.0);

        expect(speed, closeTo(5.0, 1e-12));
      });
    });

    group('computeHeadingDegrees', () {
      test('north direction returns 0°', () {
        final deg = VelocityUtility.computeHeadingDegrees(10.0, 0.0);

        expect(deg, isNotNull);
        expect(deg, closeTo(0.0, 1e-10));
      });

      test('east direction (vNorth=0, vEast>0) returns 90°', () {
        final deg = VelocityUtility.computeHeadingDegrees(0.0, 10.0);

        expect(deg, isNotNull);
        expect(deg, closeTo(90.0, 1e-10));
      });

      test('east direction (vNorth=0, vEast>0) with tiny east returns 90°', () {
        final deg = VelocityUtility.computeHeadingDegrees(0.0, 1e-6);

        expect(deg, isNotNull);
        expect(deg, closeTo(90.0, 1e-10));
      });

      test('south direction returns 180°', () {
        final deg = VelocityUtility.computeHeadingDegrees(-10.0, 0.0);

        expect(deg, isNotNull);
        expect(deg, closeTo(180.0, 1e-10));
      });

      test('west direction (vNorth=0, vEast<0) returns 270°', () {
        final deg = VelocityUtility.computeHeadingDegrees(0.0, -10.0);

        expect(deg, isNotNull);
        expect(deg, closeTo(270.0, 1e-10));
      });

      test('west direction (vNorth=0, vEast<0) with tiny east returns 270°', () {
        final deg = VelocityUtility.computeHeadingDegrees(0.0, -1e-6);

        expect(deg, isNotNull);
        expect(deg, closeTo(270.0, 1e-10));
      });

      test('returns null when both vNorth and vEast are 0 (heading undefined)', () {
        final deg = VelocityUtility.computeHeadingDegrees(0.0, 0.0);

        expect(deg, isNull);
      });

      test('returns null when vNorth is null', () {
        final deg = VelocityUtility.computeHeadingDegrees(null, 4.0);

        expect(deg, isNull);
      });

      test('returns null when vEast is null', () {
        final deg = VelocityUtility.computeHeadingDegrees(3.0, null);

        expect(deg, isNull);
      });

      test('returns null when both are null', () {
        final deg = VelocityUtility.computeHeadingDegrees(null, null);

        expect(deg, isNull);
      });

      test('northeast quadrant returns 45°', () {
        final deg = VelocityUtility.computeHeadingDegrees(1.0, 1.0);

        expect(deg, isNotNull);
        expect(deg, closeTo(45.0, 1e-10));
      });

      test('southeast quadrant returns 135°', () {
        final deg = VelocityUtility.computeHeadingDegrees(-1.0, 1.0);

        expect(deg, isNotNull);
        expect(deg, closeTo(135.0, 1e-10));
      });

      test('southwest quadrant returns 225°', () {
        final deg = VelocityUtility.computeHeadingDegrees(-1.0, -1.0);

        expect(deg, isNotNull);
        expect(deg, closeTo(225.0, 1e-10));
      });

      test('northwest quadrant returns 315°', () {
        final deg = VelocityUtility.computeHeadingDegrees(1.0, -1.0);

        expect(deg, isNotNull);
        expect(deg, closeTo(315.0, 1e-10));
      });
    });
  });
}
