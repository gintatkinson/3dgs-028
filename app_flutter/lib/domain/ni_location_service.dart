import 'geo_location.dart';

/// Stateless service providing validation and mapping operations for the
/// NI Location geo-location subtype defined in the IETF NI-Location YANG
/// grouping (uses grouping from RFC 9179 ietf-geo-location).
///
/// This service bridges the NetworkInventoryLocation container to the
/// underlying GeoLocation domain model, providing choice-constraint
/// validation (ellipsoid vs Cartesian) per RFC 9179 Section 2.3 and
/// factory methods for constructing [GeoLocation] instances from NI
/// geo-location data.
///
/// All methods are static — the service is a pure function collection
/// with no mutable state, no side effects, and no external dependencies.
///
/// @realizes UML::NiLocationService
/// @realizes UML::NiLocationService::validateNiGeoLocation
/// @realizes UML::NiLocationService::createGeoLocation
class NiLocationService {
  /// Validates that at least one coordinate system (ellipsoid or Cartesian)
  /// is present, enforcing the choice constraint from RFC 9179's
  /// geo-location grouping.
  ///
  /// The ietf-geo-location YANG grouping defines a `choice` between
  /// `ellipsoid-coordinates` (latitude/longitude/height) and
  /// `cartesian-coordinates` (x/y/z). At least one of these coordinate
  /// systems MUST be provided for the geo-location to be meaningful.
  ///
  /// Presence is detected via the primary axis: [ellipsoidLatitude] for
  /// ellipsoid and [cartesianX] for Cartesian. If neither is provided,
  /// the geo-location has no usable coordinate data and validation fails.
  ///
  /// @param ellipsoidLatitude The latitude value (primary axis for ellipsoid detection).
  /// @param ellipsoidLongitude The longitude value (secondary axis, also used for detection).
  /// @param cartesianX The X coordinate value (primary axis for Cartesian detection).
  /// @returns An error message if the choice constraint is violated, or
  ///          `null` if at least one coordinate system is present.
  ///
  /// @realizes UML::NiLocationService::validateNiGeoLocation
  static String? validateNiGeoLocation({
    double? ellipsoidLatitude,
    double? ellipsoidLongitude,
    double? cartesianX,
  }) {
    final hasEllipsoid =
        ellipsoidLatitude != null || ellipsoidLongitude != null;
    final hasCartesian = cartesianX != null;

    if (!hasEllipsoid && !hasCartesian) {
      return 'At least one coordinate system must be provided: '
          'ellipsoid (latitude/longitude) or Cartesian (x/y/z).';
    }
    return null;
  }

  /// Creates a [GeoLocation] domain model instance from NI geo-location
  /// subtype fields.
  ///
  /// Convenience factory that maps the NI Location geo-location subtype
  /// (a container under `network-inventory-location` that uses the
  /// `geo-location` grouping from RFC 9179) to the existing [GeoLocation]
  /// domain model. No new domain model is needed — the NI geo-location
  /// subtype reuses the same temporal and spatial containers already
  /// modeled by [GeoLocation].
  ///
  /// @param entityId The unique entity identifier for this geo-location node.
  /// @param timestamp Optional measurement timestamp (RFC 6991 date-and-time).
  /// @param validUntil Optional expiration timestamp (RFC 6991 date-and-time).
  /// @returns A fully constructed [GeoLocation] instance.
  ///
  /// @realizes UML::NiLocationService::createGeoLocation
  static GeoLocation createGeoLocation({
    required String entityId,
    String? timestamp,
    String? validUntil,
  }) {
    return GeoLocation(
      entityId: entityId,
      timestamp: timestamp,
      validUntil: validUntil,
    );
  }
}
