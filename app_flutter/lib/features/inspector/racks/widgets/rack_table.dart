import 'package:flutter/material.dart';
import 'package:app_flutter/features/inspector/racks/widgets/capacity_gauge.dart';
import 'package:app_flutter/features/inspector/racks/rack_table_view_model.dart';

/// Sortable DataTable showing rack inventory.
/// Columns: id | class | height mm | width mm | depth mm | max-V | max-W | Capacity | Status
/// Click row to select rack. Sort by clicking column header.
class RackTable extends StatelessWidget {
  final List<Map<String, dynamic>> racks;
  final String? selectedRackId;
  final void Function(String id) onSelect;
  final void Function(String column) onSort;
  final RackTableViewModel viewModel;

  const RackTable({
    super.key,
    required this.racks,
    this.selectedRackId,
    required this.onSelect,
    required this.onSort,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final columns = <String>[
      'id', 'rack_class', 'height', 'width', 'depth',
      'max_voltage', 'max_allocated_power', 'capacity', 'status'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 36,
        dataRowMinHeight: 32,
        dataRowMaxHeight: 40,
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Colors.grey,
        ),
        columns: [
          DataColumn(label: const Text('ID'), onSort: (col, asc) => onSort('_node_id')),
          DataColumn(label: const Text('Class'), onSort: (col, asc) => onSort('rack_class')),
          DataColumn(label: const Text('Height mm'), onSort: (col, asc) => onSort('height'), numeric: true),
          DataColumn(label: const Text('Width mm'), onSort: (col, asc) => onSort('width'), numeric: true),
          DataColumn(label: const Text('Depth mm'), onSort: (col, asc) => onSort('depth'), numeric: true),
          DataColumn(label: const Text('Max-V'), onSort: (col, asc) => onSort('max_voltage'), numeric: true),
          DataColumn(label: const Text('Max-W'), onSort: (col, asc) => onSort('max_allocated_power'), numeric: true),
          const DataColumn(label: Text('Capacity')),
          const DataColumn(label: Text('Status')),
        ],
        rows: racks.map((rack) {
          final rackId = rack['_node_id'] as String;
          final isSelected = rackId == selectedRackId;
          return DataRow(
            selected: isSelected,
            onSelectChanged: (_) => onSelect(rackId),
            cells: [
              DataCell(Text(rackId, style: const TextStyle(fontSize: 11))),
              DataCell(Text(rack['rack_class']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11))),
              DataCell(Text(rack['height']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11))),
              DataCell(Text(rack['width']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11))),
              DataCell(Text(rack['depth']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11))),
              DataCell(Text(rack['max_voltage']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11))),
              DataCell(Text(rack['max_allocated_power']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 11))),
              DataCell(_buildCapacityCell(rackId)),
              DataCell(_buildStatusCell(rack)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCapacityCell(String rackId) {
    final chassis = viewModel.chassisByRack[rackId] ?? [];
    final maxPower = (viewModel.racksById[rackId]?['max_allocated_power'] as num?)?.toDouble() ?? 0;
    double totalDraw = 0;
    for (final c in chassis) {
      final draw = c['power_draw'] as num?;
      if (draw != null) totalDraw += draw.toDouble();
    }
    return SizedBox(
      width: 140,
      child: CapacityGauge(usedWatts: totalDraw, totalWatts: maxPower),
    );
  }

  Widget _buildStatusCell(Map<String, dynamic> rack) {
    final validUntil = rack['valid_until'] as String?;
    bool isExpired = false;
    if (validUntil != null) {
      final parsed = DateTime.tryParse(validUntil);
      if (parsed != null) {
        isExpired = parsed.toUtc().isBefore(DateTime.now().toUtc());
      }
    }
    return Icon(
      isExpired ? Icons.warning : Icons.check_circle,
      size: 16,
      color: isExpired ? Colors.orange : Colors.green,
    );
  }
}
