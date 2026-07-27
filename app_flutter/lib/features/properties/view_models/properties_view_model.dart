import 'package:flutter/material.dart';
import 'package:app_flutter/domain/data_source.dart';
import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:app_flutter/domain/geo_location_service.dart';
import 'package:app_flutter/domain/ni_location_service.dart';

/// Loads a [TypeDescriptor] from the data source and exposes its fields to the
/// property grid widget.
///
/// Exists to decouple the property grid from the data-fetching logic. Use this
/// view model whenever the property panel needs to display a node's fields.
///
/// Edge cases: if [typeName] is unknown to the data source, `loadType` sets
/// [_currentType] to `null`; [fields] then returns an empty list and [hasType]
/// returns `false`. No error is surfaced to the caller — the grid reacts by
/// showing nothing.
///
/// State changes: each call to [loadType] replaces the previous type and calls
/// [notifyListeners]; the widget layer is expected to rebuild in response.
///
/// @realizes UML::PropertyGrid (schema-driven form rendering)
class PropertiesViewModel extends ChangeNotifier {
  PropertiesViewModel(this._dataSource);
  final DataSource _dataSource;

  TypeDescriptor? _currentType;
  bool _disposed = false;
  int _requestId = 0;

  /// The fields of the currently loaded type. Returns an empty list when no
  /// type has been loaded or `loadType` returned `null`.
  List<FieldDescriptor> get fields => _currentType?.fields ?? [];

  /// Whether a type has been loaded (i.e., [loadType] completed with a
  /// non-null [TypeDescriptor]).
  bool get hasType => _currentType != null;

  /// Fetches the [TypeDescriptor] for [typeName] from the data source and
  /// notifies listeners.
  ///
  /// If the data source returns `null` (unknown type), [_currentType] is set
  /// to `null`, [fields] becomes empty, and [hasType] becomes false. Does not
  /// throw — callers should check [hasType] if they need to distinguish.
  /// Replaces any previously loaded type unconditionally.
  Future<void> loadType(String typeName) async {
    final requestId = ++_requestId;
    final result = await _dataSource.typeFor(typeName);
    if (_disposed) return;
    if (_requestId != requestId) return;
    _currentType = result;
    notifyListeners();
  }

  /// Persists property data for [nodeId] after running type-specific
  /// validation, then delegates to [DataSource.saveProperties].
  ///
  /// Validation dispatch is based on the currently loaded type
  /// ([_currentType.typeName]) and is applied BEFORE any write occurs.
  /// This ensures type-specific constraints (timestamp format, body name
  /// pattern, etc.) are enforced at the ViewModel layer.
  ///
  /// Returns a validation error string on rejection, or `null` on
  /// successful save. Callers should not proceed with UI updates when
  /// a non-null error is returned.
  ///
  /// ### Type-specific validation dispatch table:
  ///
  /// | Type | Validation | Normalization |
  /// |------|-----------|---------------|
  /// | GeoLocation | [GeoLocationService.validateTimestamp] on `timestamp` | — |
  /// | ReferenceFrame | [GeoLocationService.validateAstronomicalBody] + [GeoLocationService.normalizeAstronomicalBody] on `astronomical_body` | Lowercase |
  /// | EllipsoidCoordinates | [GeoLocationService.validateLatitudeEarth] on `latitude`, [GeoLocationService.validateLongitudeEarth] on `longitude` | [GeoLocationService.roundDecimal64] (lat/lon: 16 frac, height: 6 frac) |
  /// | CartesianCoordinates | [GeoLocationService.validateCartesianValue] on `x`, `y`, `z` | [GeoLocationService.roundDecimal64] (6 frac) |
  /// | GeodeticSystem | [GeoLocationService.validateGeodeticDatum] on `geodetic_datum`, [GeoLocationService.validateCoordinateAccuracy] on `coord_accuracy`, [GeoLocationService.validateHeightAccuracy] on `height_accuracy` | [GeoLocationService.normalizeGeodeticDatum] |
  /// | NetworkInventoryLocation | [GeoLocationService.validateNiLocationId] on `id`, [GeoLocationService.validateTimestamp] on `timestamp`, [GeoLocationService.validateTemporalRelationship] | — |
  /// | NI_GeoLocation | [NiLocationService.validateNiGeoLocation] choice constraint, [GeoLocationService.validateAstronomicalBody] on `astronomical_body`, [GeoLocationService.validateGeodeticDatum] on `geodetic_datum`, [GeoLocationService.validateLatitudeEarth] on `latitude`, [GeoLocationService.validateLongitudeEarth] on `longitude`, [GeoLocationService.validateCartesianValue] on `x`/`y`/`z`, [GeoLocationService.validateVelocityComponent] on `v_north`/`v_east`/`v_up`, [GeoLocationService.validateTimestamp] on `timestamp`, [GeoLocationService.validateTemporalRelationship] | [GeoLocationService.normalizeAstronomicalBody], [GeoLocationService.normalizeGeodeticDatum], [GeoLocationService.roundDecimal64] |
  /// | PhysicalAddress | [GeoLocationService.validateCountryCode] on `country_code` | — |
  /// | VelocityVector | [GeoLocationService.validateVelocityComponent] on `v_north`, `v_east`, `v_up` | [GeoLocationService.roundDecimal64] (12 frac) |
  /// | LocationChassis | [GeoLocationService.validateChassisId] on `chassis_id` | — |
  /// | RackEntity | [GeoLocationService.validateRackId] on `id`, [GeoLocationService.validateRackClass] on `rack_class`, [GeoLocationService.validateUint16] on `height`/`width`/`depth`/`max_voltage`/`max_allocated_power` | — |
  /// | RackPlacement | [GeoLocationService.validateUint32] on `row_number`/`column_number` | — |
  /// | RackChassis | [GeoLocationService.validateRelativePosition] on `relative_position` | — |
  ///
  /// This dispatch pattern is intentionally a linear chain rather than a
  /// registry/map: the number of types with custom validation is small
  /// (<10) and a map-based dispatch adds indirection without reducing
  /// cyclomatic complexity.
  ///
  /// @param nodeId The node identifier to persist.
  /// @param data The key-value property map to save.
  /// @returns An error message string if validation fails, or `null` on
  ///          success.
  ///
  /// @realizes UML::PropertiesViewModel::saveProperties
  /// @realizes UML::GeoLocation::setCartesianLocation (validation path)
  /// @realizes UML::ReferenceFrame::validateBody
  Future<String?> saveProperties(
    String nodeId,
    Map<String, dynamic> data,
  ) async {
    if (_currentType != null && _currentType!.typeName == 'GeoLocation') {
      final timestamp = data['timestamp'] as String?;
      if (timestamp != null) {
        final validationError = GeoLocationService.validateTimestamp(timestamp);
        if (validationError != null) {
          return validationError;
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'ReferenceFrame') {
      final astronomicalBody = data['astronomical_body'] as String?;
      if (astronomicalBody != null) {
        final normalized =
            GeoLocationService.normalizeAstronomicalBody(astronomicalBody);
        final validationError =
            GeoLocationService.validateAstronomicalBody(normalized);
        if (validationError != null) {
          return validationError;
        }
        // Mutate the data map in-place so the normalized value is what
        // gets persisted. This avoids a copy-and-reassign pattern that
        // would require callers to track which fields were normalized.
        data['astronomical_body'] = normalized;
      }
    }

    if (_currentType != null && _currentType!.typeName == 'EllipsoidCoordinates') {
      final latitude = data['latitude'];
      if (latitude != null) {
        final doubleValue = latitude is double
            ? latitude
            : double.tryParse(latitude.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateLatitudeEarth(doubleValue);
          if (validationError != null) {
            return validationError;
          }
          data['latitude'] =
              GeoLocationService.roundDecimal64(doubleValue, 16);
        }
      }

      final longitude = data['longitude'];
      if (longitude != null) {
        final doubleValue = longitude is double
            ? longitude
            : double.tryParse(longitude.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateLongitudeEarth(doubleValue);
          if (validationError != null) {
            return validationError;
          }
          data['longitude'] =
              GeoLocationService.roundDecimal64(doubleValue, 16);
        }
      }

      final height = data['height'];
      if (height != null) {
        final doubleValue = height is double
            ? height
            : double.tryParse(height.toString());
        if (doubleValue != null) {
          data['height'] =
              GeoLocationService.roundDecimal64(doubleValue, 6);
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'CartesianCoordinates') {
      final x = data['x'];
      if (x != null) {
        final doubleValue = x is double
            ? x
            : double.tryParse(x.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateCartesianValue(doubleValue);
          if (validationError != null) {
            return validationError;
          }
          data['x'] =
              GeoLocationService.roundDecimal64(doubleValue, 6);
        }
      }

      final y = data['y'];
      if (y != null) {
        final doubleValue = y is double
            ? y
            : double.tryParse(y.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateCartesianValue(doubleValue);
          if (validationError != null) {
            return validationError;
          }
          data['y'] =
              GeoLocationService.roundDecimal64(doubleValue, 6);
        }
      }

      final z = data['z'];
      if (z != null) {
        final doubleValue = z is double
            ? z
            : double.tryParse(z.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateCartesianValue(doubleValue);
          if (validationError != null) {
            return validationError;
          }
          data['z'] =
              GeoLocationService.roundDecimal64(doubleValue, 6);
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'NetworkInventoryLocation') {
      final id = data['id'] as String?;
      final validationError = GeoLocationService.validateNiLocationId(id);
      if (validationError != null) {
        return validationError;
      }

      final timestamp = data['timestamp'] as String?;
      if (timestamp != null) {
        final tsError = GeoLocationService.validateTimestamp(timestamp);
        if (tsError != null) {
          return tsError;
        }
      }

      final validUntil = data['valid_until'] as String?;
      if (timestamp != null && validUntil != null) {
        final relError =
            GeoLocationService.validateTemporalRelationship(timestamp, validUntil);
        if (relError != null) {
          return relError;
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'NI_GeoLocation') {
      final ellipsoidLatitude = data['latitude'];
      final double? latitudeValue = ellipsoidLatitude is double
          ? ellipsoidLatitude
          : double.tryParse(ellipsoidLatitude?.toString() ?? '');

      final ellipsoidLongitude = data['longitude'];
      final double? longitudeValue = ellipsoidLongitude is double
          ? ellipsoidLongitude
          : double.tryParse(ellipsoidLongitude?.toString() ?? '');

      final cartesianX = data['x'];
      final double? xValue = cartesianX is double
          ? cartesianX
          : double.tryParse(cartesianX?.toString() ?? '');

      final choiceError = NiLocationService.validateNiGeoLocation(
        ellipsoidLatitude: latitudeValue,
        ellipsoidLongitude: longitudeValue,
        cartesianX: xValue,
      );
      if (choiceError != null) {
        return choiceError;
      }

      final astronomicalBody = data['astronomical_body'] as String?;
      if (astronomicalBody != null) {
        final normalized =
            GeoLocationService.normalizeAstronomicalBody(astronomicalBody);
        final validationError =
            GeoLocationService.validateAstronomicalBody(normalized);
        if (validationError != null) {
          return validationError;
        }
        data['astronomical_body'] = normalized;
      }

      final geodeticDatum = data['geodetic_datum'] as String?;
      if (geodeticDatum != null) {
        final normalized =
            GeoLocationService.normalizeGeodeticDatum(geodeticDatum);
        final validationError =
            GeoLocationService.validateGeodeticDatum(normalized);
        if (validationError != null) {
          return validationError;
        }
        data['geodetic_datum'] = normalized;
      }

      if (latitudeValue != null) {
        final validationError =
            GeoLocationService.validateLatitudeEarth(latitudeValue);
        if (validationError != null) {
          return validationError;
        }
        data['latitude'] =
            GeoLocationService.roundDecimal64(latitudeValue, 16);
      }

      if (longitudeValue != null) {
        final validationError =
            GeoLocationService.validateLongitudeEarth(longitudeValue);
        if (validationError != null) {
          return validationError;
        }
        data['longitude'] =
            GeoLocationService.roundDecimal64(longitudeValue, 16);
      }

      final height = data['height'];
      if (height != null) {
        final doubleValue = height is double
            ? height
            : double.tryParse(height.toString());
        if (doubleValue != null) {
          data['height'] =
              GeoLocationService.roundDecimal64(doubleValue, 6);
        }
      }

      for (final axis in ['x', 'y', 'z']) {
        final value = data[axis];
        if (value != null) {
          final doubleValue = value is double
              ? value
              : double.tryParse(value.toString());
          if (doubleValue != null) {
            final validationError =
                GeoLocationService.validateCartesianValue(doubleValue);
            if (validationError != null) {
              return validationError;
            }
            data[axis] =
                GeoLocationService.roundDecimal64(doubleValue, 6);
          }
        }
      }

      for (final comp in ['v_north', 'v_east', 'v_up']) {
        final value = data[comp];
        if (value != null) {
          final doubleValue = value is double
              ? value
              : double.tryParse(value.toString());
          if (doubleValue != null) {
            final validationError =
                GeoLocationService.validateVelocityComponent(doubleValue);
            if (validationError != null) {
              return validationError;
            }
            data[comp] =
                GeoLocationService.roundDecimal64(doubleValue, 12);
          }
        }
      }

      final timestamp = data['timestamp'] as String?;
      if (timestamp != null) {
        final tsError = GeoLocationService.validateTimestamp(timestamp);
        if (tsError != null) {
          return tsError;
        }
      }

      final validUntil = data['valid_until'] as String?;
      if (timestamp != null && validUntil != null) {
        final relError =
            GeoLocationService.validateTemporalRelationship(timestamp, validUntil);
        if (relError != null) {
          return relError;
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'PhysicalAddress') {
      final countryCode = data['country_code'] as String?;
      if (countryCode != null) {
        final validationError =
            GeoLocationService.validateCountryCode(countryCode);
        if (validationError != null) {
          return validationError;
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'VelocityVector') {
      final vNorth = data['v_north'];
      if (vNorth != null) {
        final doubleValue = vNorth is double
            ? vNorth
            : double.tryParse(vNorth.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateVelocityComponent(doubleValue);
          if (validationError != null) {
            return validationError;
          }
          data['v_north'] =
              GeoLocationService.roundDecimal64(doubleValue, 12);
        }
      }

      final vEast = data['v_east'];
      if (vEast != null) {
        final doubleValue = vEast is double
            ? vEast
            : double.tryParse(vEast.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateVelocityComponent(doubleValue);
          if (validationError != null) {
            return validationError;
          }
          data['v_east'] =
              GeoLocationService.roundDecimal64(doubleValue, 12);
        }
      }

      final vUp = data['v_up'];
      if (vUp != null) {
        final doubleValue = vUp is double
            ? vUp
            : double.tryParse(vUp.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateVelocityComponent(doubleValue);
          if (validationError != null) {
            return validationError;
          }
          data['v_up'] =
              GeoLocationService.roundDecimal64(doubleValue, 12);
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'LocationChassis') {
      final chassisId = data['chassis_id'] as String?;
      final validationError = GeoLocationService.validateChassisId(chassisId);
      if (validationError != null) {
        return validationError;
      }
    }

    if (_currentType != null && _currentType!.typeName == 'RackEntity') {
      final rackClass = data['rack_class'] as String?;
      if (rackClass != null) {
        final validationError = GeoLocationService.validateRackClass(rackClass);
        if (validationError != null) {
          return validationError;
        }
      }

      for (final field in ['height', 'width', 'depth', 'max_voltage', 'max_allocated_power']) {
        final value = data[field];
        if (value != null) {
          final validationError =
              GeoLocationService.validateUint16(value.toString());
          if (validationError != null) {
            return validationError;
          }
        }
      }

      final id = data['id'] as String?;
      final idError = GeoLocationService.validateRackId(id);
      if (idError != null) {
        return idError;
      }
    }

    if (_currentType != null && _currentType!.typeName == 'RackPlacement') {
      final rowNumber = data['row_number'];
      if (rowNumber != null) {
        final intValue = rowNumber is int
            ? rowNumber
            : int.tryParse(rowNumber.toString());
        if (intValue != null) {
          final validationError =
              GeoLocationService.validateUint32(intValue);
          if (validationError != null) {
            return validationError;
          }
        }
      }

      final columnNumber = data['column_number'];
      if (columnNumber != null) {
        final intValue = columnNumber is int
            ? columnNumber
            : int.tryParse(columnNumber.toString());
        if (intValue != null) {
          final validationError =
              GeoLocationService.validateUint32(intValue);
          if (validationError != null) {
            return validationError;
          }
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'RackChassis') {
      final relativePosition = data['relative_position'];
      if (relativePosition != null) {
        final intValue = relativePosition is int
            ? relativePosition
            : int.tryParse(relativePosition.toString());
        if (intValue != null) {
          final validationError =
              GeoLocationService.validateRelativePosition(intValue);
          if (validationError != null) {
            return validationError;
          }
        }
      }
    }

    if (_currentType != null && _currentType!.typeName == 'GeodeticSystem') {
      final geodeticDatum = data['geodetic_datum'] as String?;
      if (geodeticDatum != null) {
        final normalized =
            GeoLocationService.normalizeGeodeticDatum(geodeticDatum);
        final validationError =
            GeoLocationService.validateGeodeticDatum(normalized);
        if (validationError != null) {
          return validationError;
        }
        data['geodetic_datum'] = normalized;
      }

      final coordAccuracy = data['coord_accuracy'];
      if (coordAccuracy != null) {
        final doubleValue = coordAccuracy is double
            ? coordAccuracy
            : double.tryParse(coordAccuracy.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateCoordinateAccuracy(doubleValue);
          if (validationError != null) {
            return validationError;
          }
        }
      }

      final heightAccuracy = data['height_accuracy'];
      if (heightAccuracy != null) {
        final doubleValue = heightAccuracy is double
            ? heightAccuracy
            : double.tryParse(heightAccuracy.toString());
        if (doubleValue != null) {
          final validationError =
              GeoLocationService.validateHeightAccuracy(doubleValue);
          if (validationError != null) {
            return validationError;
          }
        }
      }
    }

    await _dataSource.saveProperties(nodeId, data);
    return null;
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
