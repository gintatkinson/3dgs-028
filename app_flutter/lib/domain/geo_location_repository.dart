import 'geo_location.dart';

/// Abstract repository contract for persisting and retrieving geographic
/// location entities defined in RFC 9179.
///
/// Implementations MUST provide concrete storage adapters (e.g., SQLite,
/// Firestore). The presentation layer depends on this interface only,
/// never on concrete implementations — enabling swappable backends
/// without modifying UI or ViewModel code.
///
/// All methods are asynchronous because they cross an I/O boundary.
/// Implementations should handle errors internally and return sentinel
/// values ([false], [null]) rather than throwing, so that callers can
/// react gracefully to transient failures.
///
/// Per the Zero-Mocking Live Persistence Mandate (constitution § 1.9),
/// the DI layer must resolve a real adapter (not an in-memory mock) at
/// application bootstrap.
///
/// @realizes UML::Datastore (geo-location persistence subset)
/// @realizes UML::Datastore::storeLocation
/// @realizes UML::Datastore::readGeoLocation
/// @realizes UML::Datastore::markAsExpired
abstract class GeoLocationRepository {
  /// Persists a geo-location record for the given entity.
  ///
  /// Creates a new record or overwrites an existing one (upsert).
  /// The [entityId] is used as the primary key.
  ///
  /// @param entityId The unique node identifier.
  /// @param timestamp Optional measurement timestamp in RFC 6991 format.
  /// @param validUntil Optional expiration timestamp in RFC 6991 format.
  /// @returns [true] if persistence succeeded, [false] on failure.
  Future<bool> storeGeoLocation(
    String entityId, {
    String? timestamp,
    String? validUntil,
  });

  /// Retrieves a geo-location record by entity identifier.
  ///
  /// @param entityId The unique node identifier.
  /// @returns A [GeoLocation] if found, or `null` if the entity does not
  ///          exist or has no geo-location data.
  Future<GeoLocation?> queryGeoLocation(String entityId);

  /// Marks a geo-location record as expired by setting [validUntil] to the
  /// Unix epoch (1970-01-01T00:00:00Z).
  ///
  /// This is an intentional sentinel value — any current time comparison
  /// will evaluate as expired, allowing consumers to filter out the record
  /// without deleting it (preserving audit trail).
  ///
  /// @param entityId The unique node identifier.
  /// @returns [true] if the record was found and marked, [false] if the
  ///          entity does not exist or has no geo-location data.
  Future<bool> markAsExpired(String entityId);
}
