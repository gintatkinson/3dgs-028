import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_flutter/domain/data_source.dart';
import 'package:app_flutter/domain/use_case_orchestrator.dart';

/// Runs data quality validation across all locations and racks.
///
/// Uses [UseCaseOrchestrator.validateDataQuality] to compute statuses.
/// Supports filtering by status/type and pagination.
class QualityDashboardViewModel extends ChangeNotifier {
  final DataSource _dataSource;

  Map<String, String> _statusByNodeId = {};
  Map<String, Map<String, dynamic>> _nodeProperties = {};

  String _filterStatus = 'all';
  String _filterType = 'all';
  int _pageIndex = 0;
  static const int _pageSize = 25;
  bool _loading = false;

  QualityDashboardViewModel(this._dataSource);

  Map<String, String> get statusByNodeId => _statusByNodeId;

  int get validCount =>
      _statusByNodeId.values.where((s) => s == 'valid').length;
  int get staleCount =>
      _statusByNodeId.values.where((s) => s == 'stale').length;
  int get incompleteCount =>
      _statusByNodeId.values.where((s) => s == 'incomplete').length;
  int get totalCount => _statusByNodeId.length;

  List<String> get _filteredNodeIds {
    var ids = _statusByNodeId.keys.toList();
    if (_filterStatus != 'all') {
      ids = ids.where((id) => _statusByNodeId[id] == _filterStatus).toList();
    }
    if (_filterType != 'all') {
      ids = ids.where((id) {
        final props = _nodeProperties[id];
        if (props == null) return false;
        final type = (props['type'] as String?)?.toLowerCase();
        return type == _filterType.toLowerCase();
      }).toList();
    }
    return ids;
  }

  List<Map<String, dynamic>> get paginatedResults {
    final filtered = _filteredNodeIds;
    final start = _pageIndex * _pageSize;
    final end = start + _pageSize;
    final pageIds = start < filtered.length
        ? filtered.sublist(start, end > filtered.length ? filtered.length : end)
        : <String>[];
    return pageIds.map((id) {
      final props = _nodeProperties[id] ?? {};
      final status = _statusByNodeId[id] ?? 'unknown';
      return {
        'nodeId': id,
        'type': props['type'] ?? _guessType(id),
        'status': status,
        'validUntil':
            props['valid_until'] ?? props['geo_location_valid_until'],
        'hasAddress': _hasAddress(props),
        'hasGeo': _hasGeo(props),
      };
    }).toList();
  }

  int get pageCount {
    final total = _filteredNodeIds.length;
    return total == 0 ? 1 : (total / _pageSize).ceil();
  }

  String get filterStatus => _filterStatus;
  String get filterType => _filterType;
  int get currentPage => _pageIndex;
  bool get loading => _loading;

  List<String> get availableTypes {
    final types = <String>{'all'};
    for (final props in _nodeProperties.values) {
      final type = props['type'] as String?;
      if (type != null && type.isNotEmpty) {
        types.add(type);
      }
    }
    for (final id in _statusByNodeId.keys) {
      final props = _nodeProperties[id];
      final type =
          props != null ? (props['type'] as String?) : null;
      if (type != null && type.isNotEmpty) {
        types.add(type);
      } else {
        types.add(_guessType(id));
      }
    }
    return types.toList()..sort();
  }

  void setFilterStatus(String status) {
    if (_filterStatus != status) {
      _filterStatus = status;
      _pageIndex = 0;
      notifyListeners();
    }
  }

  void setFilterType(String type) {
    if (_filterType != type) {
      _filterType = type;
      _pageIndex = 0;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_pageIndex < pageCount - 1) {
      _pageIndex++;
      notifyListeners();
    }
  }

  void prevPage() {
    if (_pageIndex > 0) {
      _pageIndex--;
      notifyListeners();
    }
  }

  Future<void> runValidation() async {
    _loading = true;
    notifyListeners();

    _statusByNodeId =
        await UseCaseOrchestrator.validateDataQuality(_dataSource);
    await _loadNodeProperties();

    _pageIndex = 0;
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadNodeProperties() async {
    final db = _dataSource.db;
    if (db == null) return;
    final rows =
        await (db as Database).query('properties');
    _nodeProperties = {};
    for (final row in rows) {
      final nodeId = row['node_id'] as String;
      try {
        final data = Map<String, dynamic>.from(
            jsonDecode(row['data_json'] as String) as Map);
        _nodeProperties[nodeId] = data;
      } catch (_) {
        _nodeProperties[nodeId] = {};
      }
    }
  }

  bool _hasAddress(Map<String, dynamic> data) {
    return (data.containsKey('postal_code') && data['postal_code'] != null) ||
        (data.containsKey('city') && data['city'] != null) ||
        (data.containsKey('country_code') && data['country_code'] != null) ||
        (data.containsKey('physical_address') &&
            data['physical_address'] != null);
  }

  bool _hasGeo(Map<String, dynamic> data) {
    return (data.containsKey('latitude') && data['latitude'] != null) ||
        (data.containsKey('longitude') && data['longitude'] != null);
  }

  String _guessType(String nodeId) {
    if (nodeId.startsWith('nil_location_')) return 'nil_location';
    if (nodeId.startsWith('rack_')) return 'rack';
    if (nodeId.startsWith('space_')) return 'space';
    if (nodeId.startsWith('ntt_exchange_')) return 'ntt_exchange';
    if (nodeId.startsWith('cable_landing_')) return 'cable_landing';
    if (nodeId == 'geo_location_root') return 'geo_location';
    return 'unknown';
  }
}
