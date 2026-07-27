import 'geo_location.dart';

abstract class GeoLocationRepository {
  Future<bool> storeGeoLocation(String entityId, {String? timestamp, String? validUntil});
  Future<GeoLocation?> queryGeoLocation(String entityId);
  Future<bool> markAsExpired(String entityId);
}
