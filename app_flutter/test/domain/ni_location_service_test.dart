import 'package:flutter_test/flutter_test.dart';
import 'package:app_flutter/domain/ni_location_service.dart';
import 'package:app_flutter/domain/geo_location.dart';

void main() {
  group('NiLocationService', () {
    group('validateNiGeoLocation', () {
      test('rejects when neither ellipsoid nor Cartesian coordinates provided', () {
        final error = NiLocationService.validateNiGeoLocation(
          ellipsoidLatitude: null,
          ellipsoidLongitude: null,
          cartesianX: null,
        );
        expect(error, isNotNull);
        expect(error, contains('ellipsoid'));
      });

      test('accepts ellipsoid-only coordinates', () {
        final error = NiLocationService.validateNiGeoLocation(
          ellipsoidLatitude: 35.0,
          ellipsoidLongitude: 139.0,
          cartesianX: null,
        );
        expect(error, isNull);
      });

      test('accepts Cartesian-only coordinates', () {
        final error = NiLocationService.validateNiGeoLocation(
          ellipsoidLatitude: null,
          ellipsoidLongitude: null,
          cartesianX: 1.0,
        );
        expect(error, isNull);
      });

      test('accepts both ellipsoid and Cartesian coordinates', () {
        final error = NiLocationService.validateNiGeoLocation(
          ellipsoidLatitude: 35.0,
          ellipsoidLongitude: 139.0,
          cartesianX: 1.0,
        );
        expect(error, isNull);
      });

      test('detects ellipsoid presence via latitude alone', () {
        final error = NiLocationService.validateNiGeoLocation(
          ellipsoidLatitude: 35.0,
          ellipsoidLongitude: null,
          cartesianX: null,
        );
        expect(error, isNull);
      });

      test('detects ellipsoid presence via longitude alone', () {
        final error = NiLocationService.validateNiGeoLocation(
          ellipsoidLatitude: null,
          ellipsoidLongitude: 139.0,
          cartesianX: null,
        );
        expect(error, isNull);
      });
    });

    group('createGeoLocation', () {
      test('maps NI geo-location data to GeoLocation domain model', () {
        final location = NiLocationService.createGeoLocation(
          entityId: 'ni-geo-1',
          timestamp: '2022-02-11T12:00:00Z',
          validUntil: '2022-02-12T12:00:00Z',
        );
        expect(location, isA<GeoLocation>());
        expect(location.entityId, equals('ni-geo-1'));
        expect(location.timestamp, equals('2022-02-11T12:00:00Z'));
        expect(location.validUntil, equals('2022-02-12T12:00:00Z'));
      });

      test('handles null optional fields gracefully', () {
        final location = NiLocationService.createGeoLocation(
          entityId: 'ni-geo-2',
        );
        expect(location.entityId, equals('ni-geo-2'));
        expect(location.timestamp, isNull);
        expect(location.validUntil, isNull);
        expect(location.hasTemporalContext, isFalse);
      });

      test('GeoLocation hasTemporalContext is true when timestamp provided', () {
        final location = NiLocationService.createGeoLocation(
          entityId: 'ni-geo-3',
          timestamp: '2022-02-11T12:00:00Z',
        );
        expect(location.hasTemporalContext, isTrue);
      });

      test('returns correct type', () {
        final location = NiLocationService.createGeoLocation(
          entityId: 'ni-geo-4',
        );
        expect(location.runtimeType, GeoLocation);
      });
    });
  });
}
