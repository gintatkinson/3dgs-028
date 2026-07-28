import 'package:flutter/material.dart';
import 'package:app_flutter/domain/data_source.dart';
import 'package:app_flutter/domain/geo_location_service.dart';
import 'package:app_flutter/domain/velocity_utility.dart';

/// Maps canonical geo-location field names to possible raw keys in data_json.
///
/// Each canonical key (RFC 9179 field name) maps to a list of candidate raw
/// keys that may appear in the stored JSON. The first matching key wins.
/// This handles the variety of key naming conventions used across different
/// node types (prefixed, flat, nested).
const Map<String, List<String>> _fieldKeyMappings = {
  'timestamp': ['timestamp', 'geo_location_timestamp'],
  'valid_until': ['valid_until', 'geo_location_valid_until'],
  'astronomical_body': ['astronomical_body', 'reference_frame_astronomical_body'],
  'alternate_system': ['alternate_system', 'reference_frame_alternate_system'],
  'geodetic_datum': ['geodetic_datum'],
  'coord_accuracy': ['coord_accuracy'],
  'height_accuracy': ['height_accuracy'],
  'latitude': ['latitude', 'ellipsoid_latitude', 'location.ellipsoid.latitude'],
  'longitude': ['longitude', 'ellipsoid_longitude', 'location.ellipsoid.longitude'],
  'height': ['height', 'ellipsoid_height', 'location.ellipsoid.height'],
  'x': ['x', 'cartesian_x', 'location.cartesian.x'],
  'y': ['y', 'cartesian_y', 'location.cartesian.y'],
  'z': ['z', 'cartesian_z', 'location.cartesian.z'],
  'v_north': ['v_north', 'velocity_v_north'],
  'v_east': ['v_east', 'velocity_v_east'],
  'v_up': ['v_up', 'velocity_v_up'],
};

/// Maps canonical field names back to the primary raw key for persisting.
const Map<String, String> _fieldSaveKeys = {
  'timestamp': 'geo_location_timestamp',
  'valid_until': 'geo_location_valid_until',
  'astronomical_body': 'reference_frame_astronomical_body',
  'alternate_system': 'reference_frame_alternate_system',
  'geodetic_datum': 'geodetic_datum',
  'coord_accuracy': 'coord_accuracy',
  'height_accuracy': 'height_accuracy',
  'latitude': 'ellipsoid_latitude',
  'longitude': 'ellipsoid_longitude',
  'height': 'ellipsoid_height',
  'x': 'x',
  'y': 'y',
  'z': 'z',
  'v_north': 'velocity_v_north',
  'v_east': 'velocity_v_east',
  'v_up': 'velocity_v_up',
};

/// Loads geo-location data for the selected topology node and exposes
/// all RFC 9179 fields for two-way binding with the GeoInspector widget.
///
/// Extracts geo-location fields from the raw property map using multi-key
/// resolution, computes derived velocity values (speed/heading), checks
/// temporal expiration, and handles field validation and persistence.
///
/// @realizes UML::GeoInspectorViewModel
class GeoInspectorViewModel extends ChangeNotifier {
  final DataSource _dataSource;

  String? _currentNodeId;
  Map<String, dynamic> _geoFields = {};
  Map<String, dynamic> _allProperties = {};
  bool _loading = false;
  String? _error;
  String _coordinateMode = 'ellipsoid';
  bool _disposed = false;

  GeoInspectorViewModel(this._dataSource);

  String? get timestamp => _geoFields['timestamp'] as String?;
  String? get validUntil => _geoFields['valid_until'] as String?;
  String? get astronomicalBody => _geoFields['astronomical_body'] as String? ?? 'earth';
  String? get alternateSystem => _geoFields['alternate_system'] as String?;
  String? get geodeticDatum => _geoFields['geodetic_datum'] as String? ?? 'wgs-84';

  double? get coordAccuracy {
    final v = _geoFields['coord_accuracy'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get heightAccuracy {
    final v = _geoFields['height_accuracy'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get latitude {
    final v = _geoFields['latitude'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get longitude {
    final v = _geoFields['longitude'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get height {
    final v = _geoFields['height'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get x {
    final v = _geoFields['x'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get y {
    final v = _geoFields['y'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get z {
    final v = _geoFields['z'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get vNorth {
    final v = _geoFields['v_north'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get vEast {
    final v = _geoFields['v_east'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get vUp {
    final v = _geoFields['v_up'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get speed => VelocityUtility.computeSpeed(vNorth, vEast);

  double? get headingDegrees =>
      VelocityUtility.computeHeadingDegrees(vNorth, vEast);

  bool get headingIsUndefined =>
      vNorth != null && vEast != null && headingDegrees == null;

  bool get isExpired {
    final vu = validUntil;
    if (vu == null) return false;
    final parsed = DateTime.tryParse(vu);
    if (parsed == null) return false;
    return parsed.toUtc().isBefore(DateTime.now().toUtc());
  }

  bool get hasTemporalContext => timestamp != null;
  bool get hasValidUntil => validUntil != null;

  bool get loading => _loading;
  String? get error => _error;

  String get coordinateMode => _coordinateMode;

  set coordinateMode(String mode) {
    if (_coordinateMode != mode) {
      _coordinateMode = mode;
      notifyListeners();
    }
  }

  /// Loads geo-location data for [nodeId] from the data source.
  ///
  /// Fetches all properties, extracts geo-location fields using
  /// [_fieldKeyMappings], and notifies listeners on completion.
  /// Resets loading state and [_error] on each call.
  ///
  /// @param nodeId The node identifier to load geo data for.
  ///
  /// @realizes UML::GeoInspectorViewModel::loadNode
  Future<void> loadNode(String nodeId) async {
    _currentNodeId = nodeId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _allProperties = await _dataSource.fetchProperties(nodeId);
      _geoFields = _extractGeoFields(_allProperties);
    } catch (e) {
      _error = e.toString();
      _geoFields = {};
    }

    _loading = false;
    notifyListeners();
  }

  /// Validates and persists a single field for the current node.
  ///
  /// [key] is the canonical field name (e.g. 'timestamp', 'latitude').
  /// [value] is the raw string input from the UI. Validation is dispatched
  /// based on the field type. On success, updates the internal field map
  /// and saves to the data source. Returns an error string on failure or
  /// null on success.
  ///
  /// @param key The canonical field name to save.
  /// @param value The raw string value from the text field.
  /// @returns An error message string if validation fails, or null on success.
  ///
  /// @realizes UML::GeoInspectorViewModel::saveField
  Future<String?> saveField(String key, String value) async {
    final validationError = _validateField(key, value);
    if (validationError != null) return validationError;

    final parsedValue = _parseFieldValue(key, value);

    final rawKey = _fieldSaveKeys[key] ?? key;
    _allProperties[rawKey] = parsedValue;
    _geoFields[key] = parsedValue;

    try {
      await _dataSource.saveProperties(_currentNodeId!, _allProperties);
    } catch (e) {
      return 'Failed to save: $e';
    }

    notifyListeners();
    return null;
  }

  /// Exports the current geo-location data to the specified [format].
  ///
  /// Supported formats:
  /// - 'ietf-uri': RFC 5870 geo URI
  /// - 'w3c': W3C Geolocation API position object
  /// - 'gml': GML Point (ISO 19136)
  /// - 'kml': KML Point
  ///
  /// @param format The export format identifier.
  /// @returns A string representation of the geo data in the requested format.
  String exportToFormat(String format) {
    switch (format) {
      case 'ietf-uri':
        return _exportIetfUri();
      case 'w3c':
        return _exportW3c();
      case 'gml':
        return _exportGml();
      case 'kml':
        return _exportKml();
      default:
        return '';
    }
  }

  String _exportIetfUri() {
    final lat = latitude;
    final lon = longitude;
    if (lat == null || lon == null) return '';
    return 'geo:$lat,$lon'
        '${height != null ? ',${height}' : ''}'
        '${coordAccuracy != null ? ';u=${coordAccuracy}' : ''}';
  }

  String _exportW3c() {
    final lat = latitude;
    final lon = longitude;
    if (lat == null || lon == null) return '';
    final buf = StringBuffer();
    buf.writeln('{');
    buf.writeln('  "coords": {');
    buf.writeln('    "latitude": $lat,');
    buf.writeln('    "longitude": $lon');
    if (height != null) buf.writeln(',\n    "altitude": $height');
    if (coordAccuracy != null) {
      buf.writeln(',\n    "accuracy": $coordAccuracy');
    }
    if (heightAccuracy != null) {
      buf.writeln(',\n    "altitudeAccuracy": $heightAccuracy');
    }
    buf.writeln('\n  }');
    if (timestamp != null) buf.writeln(',\n  "timestamp": "$timestamp"');
    buf.writeln('}');
    return buf.toString();
  }

  String _exportGml() {
    final lat = latitude;
    final lon = longitude;
    if (lat == null || lon == null) return '';
    final coordStr = height != null ? '$lon,$lat,$height' : '$lon,$lat';
    return '<gml:Point srsName="urn:ogc:def:crs:EPSG:4326">'
        '<gml:pos>$coordStr</gml:pos>'
        '</gml:Point>';
  }

  String _exportKml() {
    final lat = latitude;
    final lon = longitude;
    if (lat == null || lon == null) return '';
    final coordStr = height != null ? '$lon,$lat,$height' : '$lon,$lat';
    return '<Placemark>'
        '<Point>'
        '<coordinates>$coordStr</coordinates>'
        '</Point>'
        '</Placemark>';
  }

  static Map<String, dynamic> _extractGeoFields(Map<String, dynamic> raw) {
    final result = <String, dynamic>{};
    for (final entry in _fieldKeyMappings.entries) {
      for (final candidateKey in entry.value) {
        if (raw.containsKey(candidateKey)) {
          result[entry.key] = raw[candidateKey];
          break;
        }
      }
    }
    return result;
  }

  String? _validateField(String key, String value) {
    switch (key) {
      case 'timestamp':
      case 'valid_until':
        return GeoLocationService.validateTimestamp(value);
      case 'astronomical_body':
        final normalized = GeoLocationService.normalizeAstronomicalBody(value);
        return GeoLocationService.validateAstronomicalBody(normalized);
      case 'geodetic_datum':
        final normalized = GeoLocationService.normalizeGeodeticDatum(value);
        return GeoLocationService.validateGeodeticDatum(normalized);
      case 'coord_accuracy':
        final d = double.tryParse(value);
        if (d == null && value.isNotEmpty) {
          return 'Invalid numeric value.';
        }
        return GeoLocationService.validateCoordinateAccuracy(d);
      case 'height_accuracy':
        final d = double.tryParse(value);
        if (d == null && value.isNotEmpty) {
          return 'Invalid numeric value.';
        }
        return GeoLocationService.validateHeightAccuracy(d);
      case 'latitude':
        final d = double.tryParse(value);
        if (d == null && value.isNotEmpty) {
          return 'Invalid numeric value.';
        }
        return GeoLocationService.validateLatitudeEarth(d);
      case 'longitude':
        final d = double.tryParse(value);
        if (d == null && value.isNotEmpty) {
          return 'Invalid numeric value.';
        }
        return GeoLocationService.validateLongitudeEarth(d);
      case 'height':
        final d = double.tryParse(value);
        if (d == null && value.isNotEmpty) {
          return 'Invalid numeric value.';
        }
        if (d != null && !d.isFinite) {
          return 'Height must be a valid finite number.';
        }
        return null;
      case 'x':
      case 'y':
      case 'z':
        final d = double.tryParse(value);
        if (d == null && value.isNotEmpty) {
          return 'Invalid numeric value.';
        }
        return GeoLocationService.validateCartesianValue(d);
      case 'v_north':
      case 'v_east':
      case 'v_up':
        final d = double.tryParse(value);
        if (d == null && value.isNotEmpty) {
          return 'Invalid numeric value.';
        }
        return GeoLocationService.validateVelocityComponent(d);
      default:
        return null;
    }
  }

  dynamic _parseFieldValue(String key, String value) {
    switch (key) {
      case 'astronomical_body':
        return GeoLocationService.normalizeAstronomicalBody(value);
      case 'geodetic_datum':
        return GeoLocationService.normalizeGeodeticDatum(value);
      case 'timestamp':
      case 'valid_until':
      case 'alternate_system':
        return value;
      case 'coord_accuracy':
      case 'height_accuracy':
      case 'latitude':
      case 'longitude':
      case 'height':
      case 'x':
      case 'y':
      case 'z':
      case 'v_north':
      case 'v_east':
      case 'v_up':
        final d = double.tryParse(value);
        return d ?? value;
      default:
        return value;
    }
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
