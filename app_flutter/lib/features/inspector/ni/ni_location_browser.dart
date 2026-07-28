import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/features/inspector/ni/ni_location_tree_view_model.dart';
import 'package:app_flutter/features/inspector/ni/ni_location_detail.dart';
import 'package:app_flutter/features/inspector/ni/widgets/location_tree_tile.dart';

/// Main NI tab widget. Horizontal split: location tree (left) + detail (right).
///
/// Toolbar at top with filter, expand/collapse, show expired toggle, and
/// status bar showing counts. When no location is selected, shows
/// "Select a location" placeholder in the detail pane.
///
/// @realizes UML::NiLocationBrowser
class NiLocationBrowser extends StatefulWidget {
  const NiLocationBrowser({super.key});

  @override
  State<NiLocationBrowser> createState() => _NiLocationBrowserState();
}

class _NiLocationBrowserState extends State<NiLocationBrowser> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NiLocationTreeViewModel>();

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildToolbar(vm),
        _buildStatusBar(vm),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 250,
                child: _buildTree(vm),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: const NiLocationDetail()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(NiLocationTreeViewModel vm) {
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
                hintText: 'Filter locations...',
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
          _ToolbarButton(
            icon: Icons.unfold_more,
            tooltip: 'Expand All',
            onTap: () => vm.expandAll(),
          ),
          _ToolbarButton(
            icon: Icons.unfold_less,
            tooltip: 'Collapse All',
            onTap: () => vm.collapseAll(),
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.add_location,
            tooltip: 'Register Location',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(NiLocationTreeViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
      ),
      child: Row(
        children: [
          _StatusChip(
            label: '${vm.readyCount} Ready',
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _StatusChip(
            label: '${vm.incompleteCount} Incomplete',
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          _StatusChip(
            label: '${vm.staleCount} Stale',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildTree(NiLocationTreeViewModel vm) {
    final dispatchByLocation = vm.dispatchStatusByLocation;

    return ListView(
      padding: EdgeInsets.zero,
      children: _buildTreeNodes(
        vm,
        vm.rootLocationIds,
        dispatchByLocation,
        0,
      ),
    );
  }

  List<Widget> _buildTreeNodes(
    NiLocationTreeViewModel vm,
    List<String> nodeIds,
    Map<String, String> dispatchByLocation,
    int depth,
  ) {
    final widgets = <Widget>[];
    final visibleIds = vm.visibleLocationIds;

    for (final id in nodeIds) {
      if (!visibleIds.contains(id)) continue;
      final location = vm.allLocations.firstWhere(
        (l) => l['_node_id'] == id,
        orElse: () => {},
      );
      if (location.isEmpty) continue;

      final name = location['name'] as String? ?? id;
      final type = location['type'] as String? ?? '';
      final dispatchStatus = dispatchByLocation[id] ?? 'unknown';
      final expanded = vm.isExpanded(id);
      final hasChildren = vm.hasChildren(id);

      widgets.add(LocationTreeTile(
        id: id,
        name: name,
        type: type,
        dispatchStatus: dispatchStatus,
        depth: depth,
        isExpanded: expanded,
        hasChildren: hasChildren,
        isSelected: vm.selectedLocationId == id,
        onTap: () => vm.selectLocation(id),
        onExpand: () => vm.toggleExpanded(id),
      ));

      if (hasChildren) {
        final children =
            vm.childrenOf(id).map((c) => c['_node_id'] as String).toList();
        final visibleChildren = children
            .where((childId) => visibleIds.contains(childId))
            .toList();
        if (visibleChildren.isNotEmpty) {
          if (expanded) {
            widgets.addAll(
              _buildTreeNodes(vm, children, dispatchByLocation, depth + 1),
            );
          }
        } else {
          widgets.last = LocationTreeTile(
            id: id,
            name: name,
            type: type,
            dispatchStatus: dispatchStatus,
            depth: depth,
            isExpanded: false,
            hasChildren: false,
            isSelected: vm.selectedLocationId == id,
            onTap: () => vm.selectLocation(id),
            onExpand: null,
          );
        }
      }
    }
    return widgets;
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
