import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/reference_frame.dart';

void main() {
  group('ReferenceFrame model', () {
    test('fromMap parses astronomical_body and alternate_system', () {
      final map = {
        'astronomical_body': 'moon',
        'alternate_system': 'IAU',
      };
      final frame = ReferenceFrame.fromMap(map);

      expect(frame.astronomicalBody, equals('moon'));
      expect(frame.alternateSystem, equals('IAU'));
      expect(frame.hasAlternateSystems, isTrue);
    });

    test('fromMap handles missing alternate_system', () {
      final map = {
        'astronomical_body': 'earth',
      };
      final frame = ReferenceFrame.fromMap(map);

      expect(frame.astronomicalBody, equals('earth'));
      expect(frame.alternateSystem, isNull);
      expect(frame.hasAlternateSystems, isFalse);
    });

    test('fromMap handles empty map (both fields null)', () {
      final map = <String, dynamic>{};
      final frame = ReferenceFrame.fromMap(map);

      expect(frame.astronomicalBody, isNull);
      expect(frame.alternateSystem, isNull);
      expect(frame.hasAlternateSystems, isFalse);
    });

    test('toMap includes astronomical_body and alternate_system when present', () {
      final map = {
        'astronomical_body': 'earth',
        'alternate_system': 'IAU',
      };
      final frame = ReferenceFrame.fromMap(map);
      final result = frame.toMap();

      expect(result['astronomical_body'], equals('earth'));
      expect(result['alternate_system'], equals('IAU'));
    });

    test('toMap omits alternate_system when null', () {
      final map = {
        'astronomical_body': 'earth',
      };
      final frame = ReferenceFrame.fromMap(map);
      final result = frame.toMap();

      expect(result['astronomical_body'], equals('earth'));
      expect(result.containsKey('alternate_system'), isFalse);
    });

    test('toMap handles null astronomical_body', () {
      final map = <String, dynamic>{};
      final frame = ReferenceFrame.fromMap(map);
      final result = frame.toMap();

      expect(result, isEmpty);
    });

    test('toMap handles special characters like "67p/churyumov-gerasimenko"', () {
      final map = {
        'astronomical_body': '67p/churyumov-gerasimenko',
      };
      final frame = ReferenceFrame.fromMap(map);
      final result = frame.toMap();

      expect(result['astronomical_body'], equals('67p/churyumov-gerasimenko'));
    });

    test('hasAlternateSystems returns false when alternate_system is null', () {
      final map = <String, dynamic>{'astronomical_body': 'earth'};
      final frame = ReferenceFrame.fromMap(map);

      expect(frame.hasAlternateSystems, isFalse);
    });

    test('hasAlternateSystems returns true when alternate_system is present', () {
      final map = <String, dynamic>{
        'astronomical_body': 'mars',
        'alternate_system': 'IAU',
      };
      final frame = ReferenceFrame.fromMap(map);

      expect(frame.hasAlternateSystems, isTrue);
    });
  });
}
