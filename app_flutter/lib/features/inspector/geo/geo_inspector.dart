import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/features/inspector/geo/geo_inspector_view_model.dart';
import 'package:app_flutter/features/inspector/geo/widgets/geo_status_badge.dart';
import 'package:app_flutter/features/inspector/geo/widgets/coordinate_choice_toggle.dart';
import 'package:app_flutter/features/inspector/geo/widgets/velocity_computed_display.dart';
import 'package:app_flutter/features/inspector/shared/geo_section.dart';
import 'package:app_flutter/features/inspector/shared/geo_field.dart';

/// Main Geo tab widget for the inspector panel.
///
/// Renders all RFC 9179 geo-location fields for the currently selected
/// topology node, organized into collapsible sections: Temporal,
/// Frame of Reference, Geodetic System, Coordinates (with coordinate
/// choice toggle), and Velocity (with computed display). Includes an
/// export popup for IETF URI, W3C, GML, and KML formats.
///
/// @realizes UML::GeoInspector
class GeoInspector extends StatefulWidget {
  const GeoInspector({super.key});

  @override
  State<GeoInspector> createState() => _GeoInspectorState();
}

class _GeoInspectorState extends State<GeoInspector> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeoInspectorViewModel>();

    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error: ${vm.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GeoStatusBadge(
            isExpired: vm.isExpired,
            hasTemporalContext: vm.hasTemporalContext,
            hasValidUntil: vm.hasValidUntil,
          ),

          GeoSection(
            title: 'Temporal',
            children: [
              GeoField(
                label: 'Timestamp',
                value: vm.timestamp,
                onSave: (v) => vm.saveField('timestamp', v),
              ),
              GeoField(
                label: 'Valid Until',
                value: vm.validUntil,
                onSave: (v) => vm.saveField('valid_until', v),
              ),
            ],
          ),

          GeoSection(
            title: 'Frame of Reference',
            children: [
              GeoField(
                label: 'Astronomical Body',
                value: vm.astronomicalBody,
                onSave: (v) => vm.saveField('astronomical_body', v),
              ),
              GeoField(
                label: 'Alternate System',
                value: vm.alternateSystem,
                onSave: (v) => vm.saveField('alternate_system', v),
              ),
            ],
          ),

          GeoSection(
            title: 'Geodetic System',
            children: [
              GeoField(
                label: 'Geodetic Datum',
                value: vm.geodeticDatum,
                onSave: (v) => vm.saveField('geodetic_datum', v),
              ),
              GeoField(
                label: 'Coord Accuracy',
                value: vm.coordAccuracy?.toString(),
                isNumeric: true,
                onSave: (v) => vm.saveField('coord_accuracy', v),
              ),
              GeoField(
                label: 'Height Accuracy',
                value: vm.heightAccuracy?.toString(),
                isNumeric: true,
                enabled: vm.coordinateMode == 'ellipsoid',
                onSave: (v) => vm.saveField('height_accuracy', v),
              ),
            ],
          ),

          GeoSection(
            title: 'Coordinates',
            children: [
              CoordinateChoiceToggle(
                mode: vm.coordinateMode,
                onChanged: (m) {
                  vm.coordinateMode = m;
                },
              ),
              if (vm.coordinateMode == 'ellipsoid') ...[
                GeoField(
                  label: 'Latitude',
                  value: vm.latitude?.toString(),
                  isNumeric: true,
                  onSave: (v) => vm.saveField('latitude', v),
                ),
                GeoField(
                  label: 'Longitude',
                  value: vm.longitude?.toString(),
                  isNumeric: true,
                  onSave: (v) => vm.saveField('longitude', v),
                ),
                GeoField(
                  label: 'Height',
                  value: vm.height?.toString(),
                  isNumeric: true,
                  onSave: (v) => vm.saveField('height', v),
                ),
              ],
              if (vm.coordinateMode == 'cartesian') ...[
                GeoField(
                  label: 'X',
                  value: vm.x?.toString(),
                  isNumeric: true,
                  onSave: (v) => vm.saveField('x', v),
                ),
                GeoField(
                  label: 'Y',
                  value: vm.y?.toString(),
                  isNumeric: true,
                  onSave: (v) => vm.saveField('y', v),
                ),
                GeoField(
                  label: 'Z',
                  value: vm.z?.toString(),
                  isNumeric: true,
                  onSave: (v) => vm.saveField('z', v),
                ),
              ],
            ],
          ),

          GeoSection(
            title: 'Velocity',
            children: [
              GeoField(
                label: 'V North (m/s)',
                value: vm.vNorth?.toString(),
                isNumeric: true,
                onSave: (v) => vm.saveField('v_north', v),
              ),
              GeoField(
                label: 'V East (m/s)',
                value: vm.vEast?.toString(),
                isNumeric: true,
                onSave: (v) => vm.saveField('v_east', v),
              ),
              GeoField(
                label: 'V Up (m/s)',
                value: vm.vUp?.toString(),
                isNumeric: true,
                onSave: (v) => vm.saveField('v_up', v),
              ),
              VelocityComputedDisplay(
                speed: vm.speed,
                headingDegrees: vm.headingDegrees,
                undefined: vm.headingIsUndefined,
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: PopupMenuButton<String>(
              onSelected: (fmt) {
                final data = vm.exportToFormat(fmt);
                if (data.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: data));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Exported $fmt to clipboard'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'ietf-uri',
                  child: Text('IETF URI (RFC 5870)'),
                ),
                PopupMenuItem(
                  value: 'w3c',
                  child: Text('W3C Geolocation API'),
                ),
                PopupMenuItem(
                  value: 'gml',
                  child: Text('GML (ISO 19136)'),
                ),
                PopupMenuItem(
                  value: 'kml',
                  child: Text('KML'),
                ),
              ],
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.ios_share, size: 16),
                  SizedBox(width: 4),
                  Text('Export', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
