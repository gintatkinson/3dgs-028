import 'package:flutter/material.dart';
import 'package:app_flutter/domain/data_source.dart';
import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:app_flutter/domain/geo_location_service.dart';

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
