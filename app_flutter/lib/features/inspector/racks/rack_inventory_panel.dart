import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/features/inspector/racks/rack_table_view_model.dart';
import 'package:app_flutter/features/inspector/racks/rack_detail.dart';
import 'package:app_flutter/features/inspector/racks/widgets/rack_table.dart';

/// Main Racks tab widget. Toolbar + RackTable (top) + RackDetail (bottom when rack selected).
/// Toolbar: [Filter input] [Group by Location toggle] [Show Unplaced toggle] [Deploy Rack button]
/// When no rack selected: "Select a rack to view details" placeholder
///
/// @realizes UML::RackInventoryPanel
class RackInventoryPanel extends StatefulWidget {
  const RackInventoryPanel({super.key});

  @override
  State<RackInventoryPanel> createState() => _RackInventoryPanelState();
}

class _RackInventoryPanelState extends State<RackInventoryPanel> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RackTableViewModel>();

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildToolbar(vm),
        Expanded(
          child: _buildRackTable(vm),
        ),
        if (vm.selectedRackId != null) ...[
          const Divider(height: 1),
          Expanded(child: const RackDetail()),
        ] else
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warehouse_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Select a rack to view details',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Choose a rack from the table above',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar(RackTableViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade700),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            height: 28,
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Filter racks...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onChanged: (v) => vm.setFilter(v),
            ),
          ),
          const SizedBox(width: 8),
          _ToolbarToggle(
            icon: Icons.group_work,
            tooltip: 'Group by Location',
            active: false,
            onTap: () => vm.toggleGroupBy(),
          ),
          _ToolbarToggle(
            icon: Icons.visibility_off,
            tooltip: 'Show Unplaced',
            active: false,
            onTap: () => vm.toggleUnplaced(),
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.add,
            tooltip: 'Deploy Rack',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildRackTable(RackTableViewModel vm) {
    return RackTable(
      racks: vm.filteredRacks,
      selectedRackId: vm.selectedRackId,
      onSelect: (id) => vm.selectRack(id),
      onSort: (col) => vm.sortBy(col),
      viewModel: vm,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 18,
            color: onTap != null ? Colors.grey.shade300 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _ToolbarToggle extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ToolbarToggle({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}
