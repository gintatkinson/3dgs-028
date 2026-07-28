import 'package:flutter/material.dart';
import 'package:app_flutter/domain/data_source.dart';
import 'package:app_flutter/domain/type_descriptor.dart';

/// Manages rack inventory list, filtering, sorting, selection, and detail views.
///
/// Queries all rack rows (node_id starting with `rack_`) from the properties
/// table, loads related RackPlacement and RackChassis instances, computes
/// capacity utilization, and exposes sorted/filtered racks for the UI.
///
/// @realizes UML::RackTableViewModel
class RackTableViewModel extends ChangeNotifier {
  final DataSource _dataSource;

  List<Map<String, dynamic>> _racks = [];
  String? _selectedRackId;
  String _filterText = '';
  bool _groupByLocation = false;
  bool _showUnplaced = false;
  String _sortColumn = '_node_id';
  bool _sortAscending = true;
  bool _loading = false;
  bool _disposed = false;

  Map<String, Map<String, dynamic>> _placementByRack = {};
  Map<String, List<Map<String, dynamic>>> _chassisByRack = {};

  /// Lookup by rack node_id.
  Map<String, Map<String, dynamic>> get racksById {
    final map = <String, Map<String, dynamic>>{};
    for (final r in _racks) {
      map[r['_node_id'] as String] = r;
    }
    return map;
  }

  RackTableViewModel(this._dataSource);

  List<Map<String, dynamic>> get racks => _racks;

  String? get selectedRackId => _selectedRackId;

  Map<String, dynamic>? get selectedRack {
    if (_selectedRackId == null) return null;
    for (final r in _racks) {
      if (r['_node_id'] == _selectedRackId) return r;
    }
    return null;
  }

  Map<String, dynamic>? get rackPlacement {
    if (_selectedRackId == null) return null;
    return _placementByRack[_selectedRackId];
  }

  List<Map<String, dynamic>> get rackChassis {
    if (_selectedRackId == null) return [];
    return _chassisByRack[_selectedRackId] ?? [];
  }

  Map<String, List<Map<String, dynamic>>> get chassisByRack => _chassisByRack;

  double? get powerUtilizationPercent {
    if (_selectedRackId == null) return null;
    final rack = selectedRack;
    if (rack == null) return null;
    final maxPower =
        (rack['max_allocated_power'] as num?)?.toDouble() ?? 0;
    if (maxPower <= 0) return null;
    final chassis = _chassisByRack[_selectedRackId] ?? [];
    double totalDraw = 0;
    for (final c in chassis) {
      final powerDraw = c['power_draw'] as num?;
      if (powerDraw != null) {
        totalDraw += powerDraw.toDouble();
      }
    }
    return maxPower > 0 ? (totalDraw / maxPower) * 100 : 0;
  }

  double? get remainingPowerWatts {
    if (_selectedRackId == null) return null;
    final rack = selectedRack;
    if (rack == null) return null;
    final maxPower =
        (rack['max_allocated_power'] as num?)?.toDouble() ?? 0;
    final chassis = _chassisByRack[_selectedRackId] ?? [];
    double totalDraw = 0;
    for (final c in chassis) {
      final powerDraw = c['power_draw'] as num?;
      if (powerDraw != null) {
        totalDraw += powerDraw.toDouble();
      }
    }
    return maxPower - totalDraw;
  }

  int get chassisCount {
    if (_selectedRackId == null) return 0;
    return (_chassisByRack[_selectedRackId] ?? []).length;
  }

  bool get loading => _loading;

  List<Map<String, dynamic>> get filteredRacks {
    var list = List<Map<String, dynamic>>.from(_racks);

    if (_filterText.isNotEmpty) {
      final f = _filterText.toLowerCase();
      list = list.where((r) {
        final id = (r['_node_id'] as String).toLowerCase();
        final rackClass = (r['rack_class'] as String? ?? '').toLowerCase();
        final name = (r['name'] as String? ?? '').toLowerCase();
        return id.contains(f) || name.contains(f) || rackClass.contains(f);
      }).toList();
    }

    if (_showUnplaced) {
      list = list.where((r) {
        final placement = _placementByRack[r['_node_id']];
        return placement == null;
      }).toList();
    }

    if (_groupByLocation) {
      list.sort((a, b) {
        final pa = _placementByRack[a['_node_id']]?['location_ref'] ?? '';
        final pb = _placementByRack[b['_node_id']]?['location_ref'] ?? '';
        return pa.toString().compareTo(pb.toString());
      });
    } else {
      list.sort((a, b) {
        final valA = _sortValue(a, _sortColumn);
        final valB = _sortValue(b, _sortColumn);
        final cmp = valA.compareTo(valB);
        return _sortAscending ? cmp : -cmp;
      });
    }

    return list;
  }

  String _sortValue(Map<String, dynamic> rack, String column) {
    if (column == '_node_id') return rack['_node_id'] as String;
    return rack[column]?.toString() ?? '';
  }

  Future<void> loadRacks() async {
    _loading = true;
    notifyListeners();

    try {
      _racks = [];
      _placementByRack = {};
      _chassisByRack = {};

      final types = await _dataSource.discoverTypes();

      for (final type in types) {
        if (type.typeName.startsWith('rack_') &&
            !type.typeName.contains('_placement') &&
            !type.typeName.contains('_RackChassis')) {
          final props = await _dataSource.fetchProperties(type.typeName);
          if (props.isNotEmpty) {
            props['_node_id'] = type.typeName;
            _racks.add(props);
          }
        }
      }

      for (final rack in _racks) {
        final rackId = rack['_node_id'] as String;

        final placementType = TypeDescriptor(
          typeName: 'RackPlacement',
          displayName: 'Rack Placement',
          iconName: 'grid_on',
          fields: [],
          childTypes: [],
          relatedTypes: [],
          parentTypes: [],
        );
        final placementRecords = await _dataSource.fetchRelatedInstances(
          parentNodeId: rackId,
          targetType: placementType,
        );
        if (placementRecords.isNotEmpty) {
          _placementByRack[rackId] = placementRecords.first.attributes;
        }

        final chassisType = TypeDescriptor(
          typeName: 'RackChassis',
          displayName: 'Rack Chassis',
          iconName: 'dns',
          fields: [],
          childTypes: [],
          relatedTypes: [],
          parentTypes: [],
        );
        final chassisRecords = await _dataSource.fetchRelatedInstances(
          parentNodeId: rackId,
          targetType: chassisType,
        );
        _chassisByRack[rackId] =
            chassisRecords.map((r) => r.attributes).toList();
      }
    } catch (e) {
      debugPrint('RackTableViewModel.loadRacks error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  void selectRack(String id) {
    if (_selectedRackId != id) {
      _selectedRackId = id;
      notifyListeners();
    }
  }

  void setFilter(String text) {
    if (_filterText != text) {
      _filterText = text;
      notifyListeners();
    }
  }

  void toggleGroupBy() {
    _groupByLocation = !_groupByLocation;
    notifyListeners();
  }

  void toggleUnplaced() {
    _showUnplaced = !_showUnplaced;
    notifyListeners();
  }

  void sortBy(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = true;
    }
    notifyListeners();
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
