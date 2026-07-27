import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/geodetic_system.dart';

void main() {
  group('GeodeticSystem model', () {
    test('fromMap parses all fields', () {
      final map = {
        'geodetic_datum': 'wgs-84',
        'coord_accuracy': 1.5,
        'height_accuracy': 2.3,
      };
      final system = GeodeticSystem.fromMap(map);

      expect(system.geodeticDatum, equals('wgs-84'));
      expect(system.coordAccuracy, equals(1.5));
      expect(system.heightAccuracy, equals(2.3));
    });

    test('fromMap handles missing fields as null', () {
      final map = <String, dynamic>{
        'geodetic_datum': 'me',
      };
      final system = GeodeticSystem.fromMap(map);

      expect(system.geodeticDatum, equals('me'));
      expect(system.coordAccuracy, isNull);
      expect(system.heightAccuracy, isNull);
    });

    test('fromMap handles empty map (all null)', () {
      final map = <String, dynamic>{};
      final system = GeodeticSystem.fromMap(map);

      expect(system.geodeticDatum, isNull);
      expect(system.coordAccuracy, isNull);
      expect(system.heightAccuracy, isNull);
    });

    test('fromMap with isEarth=true defaults geodetic_datum to "wgs-84"', () {
      final map = <String, dynamic>{};
      final system = GeodeticSystem.fromMap(map, isEarth: true);

      expect(system.geodeticDatum, equals('wgs-84'));
      expect(system.coordAccuracy, isNull);
      expect(system.heightAccuracy, isNull);
    });

    test('fromMap with isEarth=true respects explicit geodetic_datum', () {
      final map = {
        'geodetic_datum': 'me',
      };
      final system = GeodeticSystem.fromMap(map, isEarth: true);

      expect(system.geodeticDatum, equals('me'));
    });

    test('fromMap with isEarth=false leaves geodetic_datum null by default', () {
      final map = <String, dynamic>{};
      final system = GeodeticSystem.fromMap(map, isEarth: false);

      expect(system.geodeticDatum, isNull);
    });

    test('toMap includes all non-null fields', () {
      final map = {
        'geodetic_datum': 'wgs-84',
        'coord_accuracy': 1.5,
        'height_accuracy': 2.3,
      };
      final system = GeodeticSystem.fromMap(map);
      final result = system.toMap();

      expect(result['geodetic_datum'], equals('wgs-84'));
      expect(result['coord_accuracy'], equals(1.5));
      expect(result['height_accuracy'], equals(2.3));
    });

    test('toMap omits null fields', () {
      final map = <String, dynamic>{
        'geodetic_datum': 'me',
      };
      final system = GeodeticSystem.fromMap(map);
      final result = system.toMap();

      expect(result['geodetic_datum'], equals('me'));
      expect(result.containsKey('coord_accuracy'), isFalse);
      expect(result.containsKey('height_accuracy'), isFalse);
    });

    test('toMap handles empty model', () {
      final map = <String, dynamic>{};
      final system = GeodeticSystem.fromMap(map);
      final result = system.toMap();

      expect(result, isEmpty);
    });

    test('default datum only applied for Earth body context', () {
      final map = <String, dynamic>{};
      final earth = GeodeticSystem.fromMap(map, isEarth: true);
      final lunar = GeodeticSystem.fromMap(map, isEarth: false);

      expect(earth.geodeticDatum, equals('wgs-84'));
      expect(lunar.geodeticDatum, isNull);
    });

    test('toMap round-trip preserves all fields', () {
      final original = {
        'geodetic_datum': 'me',
        'coord_accuracy': 0.001,
        'height_accuracy': 999.999,
      };
      final system = GeodeticSystem.fromMap(original);
      final result = system.toMap();

      expect(result, equals(original));
    });
  });
}
