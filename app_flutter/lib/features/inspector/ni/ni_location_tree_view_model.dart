import 'package:flutter/material.dart';
import 'package:app_flutter/domain/data_source.dart';
import 'package:app_flutter/domain/ni_location_services.dart';
import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:app_flutter/features/inspector/shared/breadcrumb_bar.dart';

/// Loads NI Location hierarchy from the database, manages tree state,
/// selection, filtering, and dispatch readiness computation.
///
/// Queries all rows whose node_id starts with `nil_location_` from the
/// properties table, builds a parent→children map, computes dispatch
/// status via [NiLocationServices.validateDispatchReadiness], and
/// exposes sorted/filtered tree nodes for the UI.
///
/// @realizes UML::NiLocationTreeViewModel
class NiLocationTreeViewModel extends ChangeNotifier {
  final DataSource _dataSource;

  List<Map<String, dynamic>> _allLocations = [];
  Map<String, List<Map<String, dynamic>>> _childrenByParent = {};
  String? _selectedLocationId;
  String _filterText = '';
  bool _showExpired = false;
  final Set<String> _expandedIds = {};
  List<Map<String, dynamic>> _chassisList = [];
  bool _loading = false;
  bool _disposed = false;

  NiLocationTreeViewModel(this._dataSource);

  List<Map<String, dynamic>> get allLocations => _allLocations;

  List<String> get allLocationIds =>
      _allLocations.map((l) => l['_node_id'] as String).toList();

  List<String> get rootLocationIds {
    return _allLocations
        .where((l) => l['parent'] == null)
        .map((l) => l['_node_id'] as String)
        .toList();
  }

  String? get selectedLocationId => _selectedLocationId;

  Map<String, dynamic>? get selectedLocation {
    if (_selectedLocationId == null) return null;
    for (final l in _allLocations) {
      if (l['_node_id'] == _selectedLocationId) return l;
    }
    return null;
  }

  Map<String, String> get dispatchStatusByLocation {
    final map = <String, String>{};
    for (final l in _allLocations) {
      final result = NiLocationServices.validateDispatchReadiness(l);
      map[l['_node_id'] as String] = result ?? 'ready';
    }
    return map;
  }

  int get readyCount {
    return dispatchStatusByLocation.values.where((s) => s == 'ready').length;
  }

  int get incompleteCount {
    return dispatchStatusByLocation.values
        .where((s) => s == 'incomplete')
        .length;
  }

  int get staleCount {
    return dispatchStatusByLocation.values.where((s) => s == 'stale').length;
  }

  List<BreadcrumbItem> get breadcrumbs {
    if (_selectedLocationId == null) return [];
    final chain = <Map<String, dynamic>>[];
    String? currentId = _selectedLocationId;

    final idToLocation = <String, Map<String, dynamic>>{};
    for (final l in _allLocations) {
      idToLocation[l['_node_id'] as String] = l;
    }

    while (currentId != null) {
      final loc = idToLocation[currentId];
      if (loc == null) break;
      chain.add(loc);
      currentId = loc['parent'] as String?;
    }

    return chain.reversed.map((loc) {
      final id = loc['_node_id'] as String;
      final name = loc['name'] as String? ?? id;
      return BreadcrumbItem(
        id: id,
        label: name,
        onTap: id == _selectedLocationId ? null : () => selectLocation(id),
      );
    }).toList();
  }

  List<Map<String, dynamic>> get chassisList => _chassisList;

  List<Map<String, dynamic>> get filteredLocations {
    return _allLocations.where((l) {
      if (!_showExpired &&
          NiLocationServices.isLocationStale(l)) {
        return false;
      }
      if (_filterText.isNotEmpty) {
        final name = (l['name'] as String? ?? '').toLowerCase();
        final type = (l['type'] as String? ?? '').toLowerCase();
        final id = (l['_node_id'] as String).toLowerCase();
        final f = _filterText.toLowerCase();
        return name.contains(f) || type.contains(f) || id.contains(f);
      }
      return true;
    }).toList();
  }

  Set<String> get filteredLocationIds {
    if (_filterText.isEmpty && !_showExpired) return allLocationIds.toSet();
    return filteredLocations.map((l) => l['_node_id'] as String).toSet();
  }

  Set<String> get visibleLocationIds {
    if (_filterText.isEmpty && !_showExpired) return allLocationIds.toSet();
    final ids = filteredLocations.map((l) => l['_node_id'] as String).toSet();
    for (final loc in filteredLocations) {
      String? p = loc['parent'] as String?;
      while (p != null) {
        ids.add(p);
        final parentLoc = _allLocations.firstWhere(
          (l) => l['_node_id'] == p,
          orElse: () => {},
        );
        if (parentLoc.isEmpty) break;
        p = parentLoc['parent'] as String?;
      }
    }
    return ids;
  }

  bool get loading => _loading;

  List<Map<String, dynamic>> childrenOf(String parentId) {
    return _childrenByParent[parentId] ?? [];
  }

  bool hasChildren(String id) {
    final children = _childrenByParent[id];
    return children != null && children.isNotEmpty;
  }

  bool isExpanded(String id) => _expandedIds.contains(id);

  void selectLocation(String id) {
    if (_selectedLocationId != id) {
      _selectedLocationId = id;
      _loadChassis(id);
      notifyListeners();
    }
  }

  Future<void> _loadChassis(String nodeId) async {
    try {
      final chassisType = TypeDescriptor(
        typeName: 'LocationChassis',
        displayName: 'Location Chassis',
        iconName: 'dns',
        fields: [],
        childTypes: [],
        relatedTypes: [],
        parentTypes: [],
      );
      final records = await _dataSource.fetchRelatedInstances(
        parentNodeId: nodeId,
        targetType: chassisType,
      );
      _chassisList = records.map((r) => r.attributes).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('NiLocationTreeViewModel._loadChassis error: $e');
    }
  }

  void setFilter(String text) {
    if (_filterText != text) {
      _filterText = text;
      notifyListeners();
    }
  }

  void toggleExpired() {
    _showExpired = !_showExpired;
    notifyListeners();
  }

  void toggleExpanded(String id) {
    if (_expandedIds.contains(id)) {
      _expandedIds.remove(id);
    } else {
      _expandedIds.add(id);
    }
    notifyListeners();
  }

  void expandAll() {
    _expandedIds.addAll(
      _allLocations
          .where((l) => hasChildren(l['_node_id'] as String))
          .map((l) => l['_node_id'] as String),
    );
    notifyListeners();
  }

  void collapseAll() {
    _expandedIds.clear();
    notifyListeners();
  }

  Future<void> loadLocations() async {
    _loading = true;
    notifyListeners();

    try {
      final types = await _dataSource.discoverTypes();
      final allRows = <Map<String, dynamic>>[];

      for (final type in types) {
        if (type.typeName.startsWith('nil_location_')) {
          final props = await _dataSource.fetchProperties(type.typeName);
          if (props.isNotEmpty) {
            final data = Map<String, dynamic>.from(props);
            data['_node_id'] = type.typeName;
            allRows.add(data);
          }
        }
      }

      _allLocations = allRows;
      _childrenByParent = {};

      for (final loc in _allLocations) {
        final parent = loc['parent'] as String?;
        _childrenByParent.putIfAbsent(parent ?? '__root__', () => []);
        _childrenByParent[parent ?? '__root__']!.add(loc);
      }
    } catch (e) {
      debugPrint('NiLocationTreeViewModel.loadLocations error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> saveProperties(String nodeId, Map<String, dynamic> data) async {
    await _dataSource.saveProperties(nodeId, data);
    final idx = _allLocations.indexWhere((l) => l['_node_id'] == nodeId);
    if (idx >= 0) {
      _allLocations[idx] = Map<String, dynamic>.from(data);
      _allLocations[idx]['_node_id'] = nodeId;
      notifyListeners();
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
