import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/features/inspector/quality/quality_view_model.dart';
import 'package:app_flutter/features/inspector/quality/widgets/summary_card.dart';

/// Main Quality tab widget.
///
/// Layout:
///   - Summary row: [Valid card] [Stale card] [Incomplete card] [Total card]
///   - [Re-validate All] button (calls runValidation)
///   - Filter bar: [Status dropdown] [Type dropdown]
///   - DataTable: location | type | status (colored badge) | valid-until |
///     has address | has geo
///   - Pagination: [← Prev] Page X of Y [Next →] [per page: 25]
class QualityDashboard extends StatefulWidget {
  const QualityDashboard({super.key});

  @override
  State<QualityDashboard> createState() => _QualityDashboardState();
}

class _QualityDashboardState extends State<QualityDashboard> {
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _initialised = true;
      final vm = context.read<QualityDashboardViewModel>();
      if (vm.totalCount == 0) {
        vm.runValidation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QualityDashboardViewModel>(
      builder: (context, vm, _) {
        if (vm.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSummaryRow(vm),
            const SizedBox(height: 8),
            _buildControls(vm),
            const SizedBox(height: 8),
            Expanded(child: _buildDataTable(vm)),
            _buildPagination(vm),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(QualityDashboardViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          SummaryCard(
            count: vm.validCount,
            label: 'Valid',
            color: Colors.green,
            icon: Icons.check_circle_outline,
          ),
          SummaryCard(
            count: vm.staleCount,
            label: 'Stale',
            color: Colors.red,
            icon: Icons.warning_amber_outlined,
          ),
          SummaryCard(
            count: vm.incompleteCount,
            label: 'Incomplete',
            color: Colors.orange,
            icon: Icons.help_outline,
          ),
          SummaryCard(
            count: vm.totalCount,
            label: 'Total',
            color: Colors.grey,
            icon: Icons.storage_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildControls(QualityDashboardViewModel vm) {
    final allStatuses = ['all', 'valid', 'stale', 'incomplete'];
    final allTypes = vm.availableTypes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => vm.runValidation(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Re-validate All'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Status:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          SizedBox(
            width: 120,
            child: DropdownButton<String>(
              value: vm.filterStatus,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (v) => vm.setFilterStatus(v!),
              items: allStatuses
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s[0].toUpperCase() + s.substring(1),
                            style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(width: 16),
          const Text('Type:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          SizedBox(
            width: 140,
            child: DropdownButton<String>(
              value: vm.filterType,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (v) => vm.setFilterType(v!),
              items: allTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1),
                            style: const TextStyle(fontSize: 12)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(QualityDashboardViewModel vm) {
    final data = vm.paginatedResults;
    if (data.isEmpty) {
      return const Center(
          child: Text('No results', style: TextStyle(color: Colors.grey)));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 36,
          headingRowHeight: 36,
          columns: const [
            DataColumn(label: Text('Location', style: TextStyle(fontSize: 11))),
            DataColumn(label: Text('Type', style: TextStyle(fontSize: 11))),
            DataColumn(label: Text('Status', style: TextStyle(fontSize: 11))),
            DataColumn(
                label: Text('Valid Until', style: TextStyle(fontSize: 11))),
            DataColumn(
                label: Text('Has Address', style: TextStyle(fontSize: 11))),
            DataColumn(
                label: Text('Has Geo', style: TextStyle(fontSize: 11))),
          ],
          rows: data.map((item) {
            final status = item['status'] as String;
            const double fontSize = 11.0;
            return DataRow(cells: [
              DataCell(Text(item['nodeId'].toString(),
                  style: const TextStyle(fontSize: fontSize))),
              DataCell(Text(item['type']?.toString() ?? '',
                  style: const TextStyle(fontSize: fontSize))),
              DataCell(_statusBadge(status, fontSize)),
              DataCell(Text(
                _formatDate(item['validUntil']),
                style: TextStyle(
                    fontSize: fontSize,
                    color: item['validUntil'] == null
                        ? Colors.grey
                        : Colors.white70),
              )),
              DataCell(Icon(
                item['hasAddress'] == true
                    ? Icons.check_circle
                    : Icons.cancel_outlined,
                size: 14,
                color:
                    item['hasAddress'] == true ? Colors.green : Colors.red,
              )),
              DataCell(Icon(
                item['hasGeo'] == true
                    ? Icons.check_circle
                    : Icons.cancel_outlined,
                size: 14,
                color: item['hasGeo'] == true ? Colors.green : Colors.red,
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, double fontSize) {
    final color = switch (status) {
      'valid' => Colors.green,
      'stale' => Colors.red,
      'incomplete' => Colors.orange,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(120), width: 0.5),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: color, fontSize: fontSize),
      ),
    );
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    final dt = DateTime.tryParse(dateVal.toString());
    if (dt == null) return '';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildPagination(QualityDashboardViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: vm.currentPage > 0 ? () => vm.prevPage() : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            'Page ${vm.currentPage + 1} of ${vm.pageCount}',
            style: const TextStyle(fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed:
                vm.currentPage < vm.pageCount - 1 ? () => vm.nextPage() : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 16),
          const Text('per page: 25', style: TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
