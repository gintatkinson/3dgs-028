import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/features/inspector/ni/ni_location_tree_view_model.dart';
import 'package:app_flutter/features/inspector/ni/widgets/dispatch_badge.dart';
import 'package:app_flutter/features/inspector/ni/widgets/address_form.dart';
import 'package:app_flutter/features/inspector/shared/breadcrumb_bar.dart';
import 'package:app_flutter/features/inspector/shared/geo_section.dart';

/// Right panel of NI tab. Shows the selected location's full detail.
///
/// Sections: Identity, Physical Address, Geographic Location, Chassis Table.
/// Uses [BreadcrumbBar] at top, [DispatchBadge], and [GeoSection] wrappers.
/// Shows "Select a location" placeholder when nothing is selected.
///
/// @realizes UML::NiLocationDetail
class NiLocationDetail extends StatelessWidget {
  const NiLocationDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NiLocationTreeViewModel>();
    final location = vm.selectedLocation;

    if (location == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Select a location',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Choose a location from the tree to view details',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final dispatchStatus =
        vm.dispatchStatusByLocation[location['_node_id']] ?? 'unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbBar(items: vm.breadcrumbs),
          const SizedBox(height: 8),
          DispatchBadge(status: dispatchStatus),
          const SizedBox(height: 12),
          _buildIdentitySection(location),
          const SizedBox(height: 8),
          _buildAddressSection(location, context),
          const SizedBox(height: 8),
          _buildGeoSection(location),
          const SizedBox(height: 8),
          _buildChassisSection(location, context),
          const SizedBox(height: 12),
          _buildEnrichButton(),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(Map<String, dynamic> location) {
    return GeoSection(
      title: 'Identity',
      children: [
        _infoRow('ID', location['_node_id']?.toString() ?? '-'),
        _infoRow('Type', location['type']?.toString() ?? '-'),
        _infoRow('UUID', location['uuid']?.toString() ?? '-'),
        _infoRow('Name', location['name']?.toString() ?? '-'),
        _infoRow('Alias', location['alias']?.toString() ?? '-'),
        _infoRow('Description', location['description']?.toString() ?? '-'),
      ],
    );
  }

  Widget _buildAddressSection(
      Map<String, dynamic> location, BuildContext context) {
    final vm = context.read<NiLocationTreeViewModel>();
    return GeoSection(
      title: 'Physical Address',
      children: [
        AddressForm(
          initialData: location,
          onSave: (updatedData) async {
            final nodeId = location['_node_id'] as String;
            try {
              final fullData = Map<String, dynamic>.from(location);
              fullData.addAll(updatedData);
              await vm.saveProperties(nodeId, fullData);
              return null;
            } catch (e) {
              return e.toString();
            }
          },
        ),
      ],
    );
  }

  Widget _buildGeoSection(Map<String, dynamic> location) {
    final lat = location['latitude'];
    final lon = location['longitude'];
    final height = location['height'];

    return GeoSection(
      title: 'Geographic Location',
      children: [
        if (lat != null && lon != null) ...[
          _infoRow('Latitude', lat.toString()),
          _infoRow('Longitude', lon.toString()),
          if (height != null) _infoRow('Height', height.toString()),
        ] else
          const Text(
            'No geographic coordinates configured.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildChassisSection(
      Map<String, dynamic> location, BuildContext context) {
    final vm = context.watch<NiLocationTreeViewModel>();
    final chassis = vm.chassisList;

    return GeoSection(
      title: 'Chassis Table',
      children: [
        if (chassis.isEmpty)
          const Text(
            'No chassis assigned to this location.',
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
                  _TableHeader('Chassis ID'),
                  _TableHeader('NE Ref'),
                  _TableHeader('Component Ref'),
                ],
              ),
              for (final c in chassis)
                TableRow(
                  children: [
                    _TableCell(c['chassis_id']?.toString() ?? '-'),
                    _TableCell(c['ne_ref']?.toString() ?? '-'),
                    _TableCell(c['component_ref']?.toString() ?? '-'),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEnrichButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.auto_fix_high, size: 16),
        label: const Text('Enrich Location'),
      ),
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
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
