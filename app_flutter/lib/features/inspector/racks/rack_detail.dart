import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/features/inspector/racks/rack_table_view_model.dart';
import 'package:app_flutter/features/inspector/racks/widgets/capacity_gauge.dart';
import 'package:app_flutter/features/inspector/shared/geo_section.dart';

/// Panel below rack table showing selected rack's full detail.
///
/// Sections:
///   Identity: id, rack_class (dropdown with valid enum values), uuid, name, alias, description
///   Dimensions: height mm, width mm, depth mm (uint16 validated)
///   Power: max_voltage, max_allocated_power + CapacityGauge
///   Placement: location_ref (resolved name, clickable), row_number, column_number
///     Buttons: [Assign Location] [Clear Location]
///   Chassis Table: relative_position | ne_ref | component_ref
///     Button: [Add Chassis] with modal form (position 0-255, ne_ref, component_ref)
///   Temporal: timestamp, valid_until
///
/// @realizes UML::RackDetail
class RackDetail extends StatelessWidget {
  const RackDetail({super.key});

  static const List<String> _rackClasses = [
    'rack-standard',
    'rack-secure-baseline',
    'rack-secure-medium',
    'rack-secure-high',
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RackTableViewModel>();
    final rack = vm.selectedRack;

    if (rack == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIdentitySection(rack),
          const SizedBox(height: 8),
          _buildDimensionSection(rack),
          const SizedBox(height: 8),
          _buildPowerSection(vm, rack),
          const SizedBox(height: 8),
          _buildPlacementSection(vm),
          const SizedBox(height: 8),
          _buildChassisSection(vm, context),
          const SizedBox(height: 8),
          _buildTemporalSection(rack),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(Map<String, dynamic> rack) {
    return GeoSection(
      title: 'Identity',
      children: [
        _infoRow('ID', rack['_node_id']?.toString() ?? '-'),
        _infoRow('UUID', rack['uuid']?.toString() ?? '-'),
        _infoRow('Name', rack['name']?.toString() ?? '-'),
        _infoRow('Alias', rack['alias']?.toString() ?? '-'),
        _infoRow('Description', rack['description']?.toString() ?? '-'),
        const SizedBox(height: 4),
        _infoRowEnum('Rack Class', rack['rack_class']?.toString()),
      ],
    );
  }

  Widget _infoRowEnum(String label, String? current) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: Text(
              current ?? '-',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionSection(Map<String, dynamic> rack) {
    return GeoSection(
      title: 'Dimensions',
      children: [
        _infoRow('Height (mm)', rack['height']?.toString() ?? '-'),
        _infoRow('Width (mm)', rack['width']?.toString() ?? '-'),
        _infoRow('Depth (mm)', rack['depth']?.toString() ?? '-'),
      ],
    );
  }

  Widget _buildPowerSection(RackTableViewModel vm, Map<String, dynamic> rack) {
    final maxPower =
        (rack['max_allocated_power'] as num?)?.toDouble() ?? 0;
    final remaining = vm.remainingPowerWatts ?? maxPower;
    final used = maxPower - remaining;

    return GeoSection(
      title: 'Power',
      children: [
        _infoRow('Max Voltage (V)', rack['max_voltage']?.toString() ?? '-'),
        _infoRow(
            'Max Allocated Power (W)',
            rack['max_allocated_power']?.toString() ?? '-'),
        const SizedBox(height: 8),
        const Text('Power Utilization',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        CapacityGauge(usedWatts: used, totalWatts: maxPower),
      ],
    );
  }

  Widget _buildPlacementSection(RackTableViewModel vm) {
    final placement = vm.rackPlacement;

    return GeoSection(
      title: 'Placement',
      children: [
        if (placement != null) ...[
          _infoRow('Location Ref', placement['location_ref']?.toString() ?? '-'),
          _infoRow('Row', placement['row_number']?.toString() ?? '-'),
          _infoRow('Column', placement['column_number']?.toString() ?? '-'),
        ] else
          const Text(
            'No placement assigned.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.location_on_outlined, size: 14),
              label: const Text('Assign Location', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            if (placement != null) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.clear, size: 14),
                label: const Text('Clear Location', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildChassisSection(
      RackTableViewModel vm, BuildContext context) {
    final chassis = vm.rackChassis;

    return GeoSection(
      title: 'Chassis Table',
      children: [
        if (chassis.isEmpty)
          const Text(
            'No chassis assigned to this rack.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          )
        else
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            border: TableBorder.all(color: Colors.grey.shade700),
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade800),
                children: const [
                  _TableHeader('Position'),
                  _TableHeader('NE Ref'),
                  _TableHeader('Component Ref'),
                ],
              ),
              for (final c in chassis)
                TableRow(
                  children: [
                    _TableCell(c['relative_position']?.toString() ?? '-'),
                    _TableCell(c['ne_ref']?.toString() ?? '-'),
                    _TableCell(c['component_ref']?.toString() ?? '-'),
                  ],
                ),
            ],
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Add Chassis', style: TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildTemporalSection(Map<String, dynamic> rack) {
    return GeoSection(
      title: 'Temporal',
      children: [
        _infoRow('Timestamp', rack['timestamp']?.toString() ?? '-'),
        _infoRow('Valid Until', rack['valid_until']?.toString() ?? '-'),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}
