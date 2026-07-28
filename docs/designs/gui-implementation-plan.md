# Complete Implementation Plan: 100% Specification Coverage

## Overview

| Phase | Deliverable | Files | Tests | Hours |
|-------|-------------|:-----:|:-----:|:-----:|
| 1 | Foundation (done) | 32 | 640 | — |
| 2 | Geo Tab — Epic #7 | 8 new, 3 mod | +75 | 8 |
| 3 | NI Tab — Epic #8 | 8 new, 2 mod | +128 | 10 |
| 4 | Racks Tab — Epic #9 | 6 new, 2 mod | +83 | 8 |
| 5 | Quality Tab — UC #37 | 3 new, 1 mod | +0 | 4 |
| 6 | Verification + Delivery | 5 metadata | — | 3 |
| | **Total** | **30 new, 8 mod** | **926** | **33** |

---

## Phase 2: Geo Tab (Epic #7 — RFC 9179)

### Architecture: Geo Tab Contents

```
Geo Tab
├── GeoInspector (StatefulWidget)
│   ├── selects topology node → GeoInspectorViewModel.loadNode(nodeId)
│   ├── Section: Temporal
│   │   ├── timestamp text field  (validated on blur)
│   │   ├── valid-until text field (validated on blur, temporal relationship check)
│   │   └── status: [Fresh] [No Expiry] [EXPIRED]
│   ├── Section: Frame of Reference
│   │   ├── astronomical-body text field (pattern, auto-lowercase)
│   │   └── alternate-system text field (hidden if feature disabled)
│   ├── Section: Geodetic System
│   │   ├── geodetic-datum text field (pattern, space→dash)
│   │   ├── coord-accuracy number field (≥0)
│   │   └── height-accuracy number field (≥0, greyed when Cartesian)
│   ├── Section: Coordinates
│   │   ├── CoordinateChoiceToggle (radio: Ellipsoid | Cartesian)
│   │   ├── Ellipsoid: latitude, longitude, height
│   │   └── Cartesian: x, y, z
│   ├── Section: Velocity
│   │   ├── v-north, v-east, v-up number fields
│   │   └── VelocityComputedDisplay (read-only speed + heading)
│   └── "Export" button → IETF URI / W3C / GML / KML
```

### File List

| # | File | Type | Purpose |
|---|------|------|---------|
| 2.1 | `lib/features/inspector/geo/geo_inspector.dart` | Widget | Main Geo tab panel, sections rendering |
| 2.2 | `lib/features/inspector/geo/geo_inspector_view_model.dart` | VM | Loads current node geo data, validates, computes |
| 2.3 | `lib/features/inspector/geo/widgets/coordinate_choice_toggle.dart` | Widget | Ellipsoid/Cartesian radio toggle |
| 2.4 | `lib/features/inspector/geo/widgets/velocity_computed_display.dart` | Widget | Read-only speed/heading from v-north/v-east |
| 2.5 | `lib/features/inspector/geo/widgets/geo_section.dart` | Widget | Reusable section card (header + fields) |
| 2.6 | `lib/features/inspector/geo/widgets/geo_status_badge.dart` | Widget | Fresh/NoExpiry/Expired badge |
| 2.7 | `lib/features/layout/layout.dart` | Modify | Replace PropertyGrid panel call with tab bar |
| 2.8 | `lib/domain/velocity_utility.dart` | Existing | computeSpeed, computeHeadingDegrees |
| 2.9 | `lib/domain/geo_location_service.dart` | Existing | All validation methods |

### GeoInspectorViewModel API

```dart
class GeoInspectorViewModel extends ChangeNotifier {
  final DataSource _dataSource;
  String? _currentNodeId;
  Map<String, dynamic> _rawProperties;   // from data_json
  Map<String, dynamic> _geoFields;       // extracted geo-location fields
  
  // GEO-LOCATION FIELDS (extracted from node properties)
  String? get timestamp;
  String? get validUntil;
  String? get astronomicalBody;
  String? get alternateSystem;
  String? get geodeticDatum;
  double? get coordAccuracy;
  double? get heightAccuracy;
  double? get latitude;
  double? get longitude;
  double? get height;
  double? get x, get y, get z;
  double? get vNorth, get vEast, get vUp;
  
  // COMPUTED
  double? get speed;           // sqrt(vNorth² + vEast²)
  double? get headingDegrees;  // atan2(vEast, vNorth)
  bool get headingIsUndefined; // both zero
  bool get isExpired;
  bool get hasTemporalContext;
  bool get isCartesianActive;
  
  // COORDINATE CHOICE
  String _coordinateMode; // 'ellipsoid' | 'cartesian'
  String get coordinateMode;
  set coordinateMode(String mode);
  
  // LOADING
  bool get loading;
  String? get error;
  
  Future<void> loadNode(String nodeId);
  Future<String?> saveField(String fieldKey, String value);
  String exportToFormat(String format); // 'ietf-uri', 'w3c', 'gml', 'kml'
}
```

### GeoInspector Widget Structure

```dart
class GeoInspector extends StatefulWidget {
  // Binds to GeoInspectorViewModel via Provider
  // Rebuilds on notifyListeners
}

class _GeoInspectorState extends State<GeoInspector> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GeoInspectorViewModel>();
    if (vm.loading) return CircularProgressIndicator();
    
    return SingleChildScrollView(
      child: Column(children: [
        // STATUS BADGE
        GeoStatusBadge(isExpired: vm.isExpired, hasTemporal: vm.hasTemporalContext),
        
        // TEMPORAL SECTION
        GeoSection(title: 'Temporal', fields: [
          GeoField(label: 'Timestamp', value: vm.timestamp, onSave: (v) => vm.saveField('timestamp', v)),
          GeoField(label: 'Valid Until', value: vm.validUntil, onSave: (v) => vm.saveField('valid_until', v)),
        ]),
        
        // FRAME OF REFERENCE SECTION
        GeoSection(title: 'Frame of Reference', fields: [
          GeoField(label: 'Astronomical Body', value: vm.astronomicalBody, onSave: (v) => vm.saveField('astronomical_body', v)),
          GeoField(label: 'Alternate System', value: vm.alternateSystem, onSave: (v) => vm.saveField('alternate_system', v)),
        ]),
        
        // GEODETIC SYSTEM SECTION
        GeoSection(title: 'Geodetic System', fields: [
          GeoField(label: 'Geodetic Datum', value: vm.geodeticDatum, onSave: (v) => vm.saveField('geodetic_datum', v)),
          GeoField(label: 'Coord Accuracy', value: vm.coordAccuracy?.toString(), isNumeric: true, onSave: (v) => vm.saveField('coord_accuracy', v)),
          GeoField(label: 'Height Accuracy', value: vm.heightAccuracy?.toString(), isNumeric: true, enabled: !vm.isCartesianActive, onSave: (v) => vm.saveField('height_accuracy', v)),
        ]),
        
        // COORDINATES SECTION
        GeoSection(title: 'Coordinates', fields: [
          CoordinateChoiceToggle(mode: vm.coordinateMode, onChanged: (m) => vm.coordinateMode = m),
          if (vm.coordinateMode == 'ellipsoid') ...[
            GeoField(label: 'Latitude', value: vm.latitude?.toString(), isNumeric: true, onSave: (v) => vm.saveField('latitude', v)),
            GeoField(label: 'Longitude', value: vm.longitude?.toString(), isNumeric: true, onSave: (v) => vm.saveField('longitude', v)),
            GeoField(label: 'Height', value: vm.height?.toString(), isNumeric: true, onSave: (v) => vm.saveField('height', v)),
          ],
          if (vm.coordinateMode == 'cartesian') ...[
            GeoField(label: 'X', value: vm.x?.toString(), isNumeric: true, onSave: (v) => vm.saveField('x', v)),
            GeoField(label: 'Y', value: vm.y?.toString(), isNumeric: true, onSave: (v) => vm.saveField('y', v)),
            GeoField(label: 'Z', value: vm.z?.toString(), isNumeric: true, onSave: (v) => vm.saveField('z', v)),
          ],
        ]),
        
        // VELOCITY SECTION
        GeoSection(title: 'Velocity', fields: [
          GeoField(label: 'V North (m/s)', value: vm.vNorth?.toString(), isNumeric: true, onSave: (v) => vm.saveField('v_north', v)),
          GeoField(label: 'V East (m/s)', value: vm.vEast?.toString(), isNumeric: true, onSave: (v) => vm.saveField('v_east', v)),
          GeoField(label: 'V Up (m/s)', value: vm.vUp?.toString(), isNumeric: true, onSave: (v) => vm.saveField('v_up', v)),
          VelocityComputedDisplay(speed: vm.speed, heading: vm.headingDegrees, undefined: vm.headingIsUndefined),
        ]),
        
        // EXPORT BUTTON
        PopupMenuButton<String>(
          itemBuilder: (_) => [
            PopupMenuItem(value: 'ietf-uri', child: Text('IETF URI (RFC 5870)')),
            PopupMenuItem(value: 'w3c', child: Text('W3C Geolocation API')),
            PopupMenuItem(value: 'gml', child: Text('GML (ISO 19136)')),
            PopupMenuItem(value: 'kml', child: Text('KML')),
          ],
          onSelected: (fmt) => Clipboard.setData(ClipboardData(text: vm.exportToFormat(fmt))),
        ),
      ]),
    );
  }
}
```

### Coordinate Choice Toggle

```dart
class CoordinateChoiceToggle extends StatelessWidget {
  final String mode; // 'ellipsoid' | 'cartesian'
  final ValueChanged<String> onChanged;
  
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Radio<String>(value: 'ellipsoid', groupValue: mode, onChanged: (v) => onChanged(v!)),
      Text('Ellipsoid'),
      SizedBox(width: 24),
      Radio<String>(value: 'cartesian', groupValue: mode, onChanged: (v) => onChanged(v!)),
      Text('Cartesian'),
    ]);
  }
}
```

### Velocity Computed Display

```dart
class VelocityComputedDisplay extends StatelessWidget {
  final double? speed;           // m/s
  final double? headingDegrees;
  final bool undefined;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Speed: ${speed != null ? "${speed!.toStringAsFixed(2)} m/s" : "--"}', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Heading: ${undefined ? "undefined" : headingDegrees != null ? "${headingDegrees!.toStringAsFixed(1)}°" : "--"}'),
      ]),
    );
  }
}
```

### GeoField (reusable editable field widget)

```dart
class GeoField extends StatefulWidget {
  final String label;
  final String? value;
  final bool isNumeric;
  final bool enabled;
  final Future<String?> Function(String value) onSave;
  
  @override
  _GeoFieldState createState() => _GeoFieldState();
}

class _GeoFieldState extends State<GeoField> {
  late TextEditingController _controller;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }
  
  @override
  void didUpdateWidget(GeoField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _controller.text = widget.value ?? '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        TextField(
          controller: _controller,
          enabled: widget.enabled,
          keyboardType: widget.isNumeric ? TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(
            errorText: _error,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          ),
          onSubmitted: (_) => _commit(),
        ),
      ]),
    );
  }
  
  Future<void> _commit() async {
    final error = await widget.onSave(_controller.text);
    setState(() => _error = error);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Layout Modifications

In `layout.dart`, replace the `_buildChildWidget` method:

```dart
Widget _buildChildWidget(BuildContext context) {
  return Column(children: [
    // FEATURE TAB BAR
    _buildTabBar(),
    // TAB CONTENT
    Expanded(child: _buildTabContent()),
  ]);
}

Widget _buildTabBar() {
  return Container(
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: dividerColor))),
    child: Row(children: [
      _TabButton(label: 'Geo', active: _activeTab == 'geo', onTap: () => setState(() => _activeTab = 'geo')),
      _TabButton(label: 'NI', active: _activeTab == 'ni', onTap: () => setState(() => _activeTab = 'ni')),
      _TabButton(label: 'Racks', active: _activeTab == 'racks', onTap: () => setState(() => _activeTab = 'racks')),
      _TabButton(label: 'Quality', active: _activeTab == 'quality', onTap: () => setState(() => _activeTab = 'quality')),
    ]),
  );
}

Widget _buildTabContent() {
  switch (_activeTab) {
    case 'geo':
      return ChangeNotifierProvider<GeoInspectorViewModel>.value(
        value: _geoInspectorViewModel!,
        child: GeoInspector(),
      );
    case 'ni':
      return ChangeNotifierProvider<NiLocationTreeViewModel>.value(
        value: _niLocationViewModel!,
        child: NiLocationBrowser(),
      );
    case 'racks':
      return ChangeNotifierProvider<RackTableViewModel>.value(
        value: _rackTableViewModel!,
        child: RackInventoryPanel(),
      );
    case 'quality':
      return ChangeNotifierProvider<QualityDashboardViewModel>.value(
        value: _qualityViewModel!,
        child: QualityDashboard(),
      );
    default:
      return SizedBox.shrink();
  }
}
```

---

## Phase 3: NI Tab (Epic #8)

### Architecture: NI Tab Contents

```
NI Tab
├── Toolbar
│   ├── [Filter: ________________] [Expand All] [Collapse All]
│   ├── [Show Expired ☐] [Register Location ⨁]
│   └── Status bar: "12 Ready · 3 Incomplete · 1 Stale"
├── Body (horizontal split)
│   ├── Left: NiLocationTree
│   │   ├── Tokyo-Campus [site] ⚠
│   │   │   └── Building-A [building] ✓
│   │   │       ├── Room-101 [equipment-room] ✓
│   │   │       └── Room-201 [equipment-room] ✓
│   │   └── Pole-TK-01 [pole] ⚠
│   └── Right: NiLocationDetail
│       ├── BreadcrumbBar: Tokyo-Campus > Building-A > Room-101
│       ├── DispatchBadge: ✓ Ready for Dispatch
│       ├── Section: Identity
│       │   ├── id, type, uuid, name, alias, description
│       ├── Section: Physical Address
│       │   ├── address, postal-code, state, city, country-code (validated)
│       ├── Section: Geographic Location
│       │   ├── reference-frame, coordinates, velocity (reuses Geo fields)
│       ├── Section: Chassis Table
│       │   ├── Table: chassis-id | ne-ref | component-ref
│       │   └── [Add Chassis] button
│       └── Footer: "Enrich Location" [Step Wizard]
```

### File List

| # | File | Type |
|---|------|------|
| 3.1 | `lib/features/inspector/ni/ni_location_browser.dart` | Widget |
| 3.2 | `lib/features/inspector/ni/ni_location_tree_view_model.dart` | VM |
| 3.3 | `lib/features/inspector/ni/ni_location_detail.dart` | Widget |
| 3.4 | `lib/features/inspector/ni/ni_location_detail_view_model.dart` | VM |
| 3.5 | `lib/features/inspector/ni/widgets/dispatch_badge.dart` | Widget |
| 3.6 | `lib/features/inspector/ni/widgets/location_tree_tile.dart` | Widget |
| 3.7 | `lib/features/inspector/shared/breadcrumb_bar.dart` | Widget |
| 3.8 | `lib/features/inspector/ni/widgets/address_form.dart` | Widget |

### NiLocationTreeViewModel API

```dart
class NiLocationTreeViewModel extends ChangeNotifier {
  final DataSource _dataSource;
  
  List<Map<String, dynamic>> _allLocations;
  Map<String, List<Map<String, dynamic>>> _childrenByParent; // parentId → children
  String? _selectedLocationId;
  Map<String, String?> _filteredTree; // tree with filter applied
  
  // TREE DATA
  List<String> get rootLocationIds;
  List<Map<String, dynamic>> childrenOf(String parentId);
  
  // SELECTION
  String? get selectedLocationId;
  void selectLocation(String id);
  
  // FILTERING
  String _filterText;
  bool _showExpired;
  
  // DISPATCH STATUS
  Map<String, String> get dispatchStatusByLocation; // 'ready'|'incomplete'|'stale'
  
  // COUNTS
  int get readyCount;
  int get incompleteCount;
  int get staleCount;
  
  // OPTIONS
  void expandAll();
  void collapseAll();
  Set<String> _expandedIds;
  
  Future<void> loadLocations();
}
```

### DispatchBadge Widget

```dart
class DispatchBadge extends StatelessWidget {
  final String status; // 'ready' | 'incomplete' | 'stale'
  
  Color get color => status == 'ready' ? Colors.green 
                    : status == 'incomplete' ? Colors.orange 
                    : status == 'stale' ? Colors.red : Colors.grey;
  
  String get label => status == 'ready' ? 'READY FOR DISPATCH'
                    : status == 'incomplete' ? 'INCOMPLETE'
                    : status == 'stale' ? 'STALE' : 'UNKNOWN';
  
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
  );
}
```

### BreadcrumbBar Widget

```dart
class BreadcrumbBar extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final void Function(String id)? onTap;
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          GestureDetector(
            onTap: items[i].onTap != null ? () => items[i].onTap!() : null,
            child: Text(items[i].label, style: TextStyle(
              fontSize: 12,
              color: i == items.length - 1 ? Colors.white : Colors.blue,
              fontWeight: i == items.length - 1 ? FontWeight.bold : FontWeight.normal,
            )),
          ),
        ]
      ]),
    );
  }
}
```

---

## Phase 4: Racks Tab (Epic #9)

### Architecture: Racks Tab Contents

```
Racks Tab
├── Toolbar
│   ├── [Filter □] [Group by Location □] [Show Unplaced □]
│   └── [Deploy Rack ⨁]
├── RackTable (sortable, filterable)
│   ├── id | class | height | width | depth | max-V | max-W | power% | status
│   ├── Rack-101-A | secure-medium | 2200 | 600 | 1200 | 240 | 8000 | ▓▓▓▓▓░░░░ 56% | ✓
│   └── Rack-201-B | rack-standard | 2000 | 600 | 1000 | 240 | 6000 | ▓▓▓░░░░░░░ 33% | ✓
└── RackDetail (below table, expands on row click)
    ├── Section: Properties
    │   ├── id, rack-class (dropdown), uuid, name, alias, description
    ├── Section: Dimensions (mm)
    │   ├── height, width, depth — integer, 0..65535
    ├── Section: Power
    │   ├── max-voltage (V), max-allocated-power (W)
    │   └── CapacityGauge: used power / total power, utilization %
    ├── Section: Placement
    │   ├── location-ref (resolved link) | row-number | column-number
    │   └── [Assign Location] [Clear Location]
    ├── Section: Chassis
    │   ├── Table: relative-position | ne-ref | component-ref
    │   └── [Add Chassis] button with U-slot position form
    └── Section: Temporal
        ├── timestamp, valid-until
```

### File List

| # | File | Type |
|---|------|------|
| 4.1 | `lib/features/inspector/racks/rack_inventory_panel.dart` | Widget |
| 4.2 | `lib/features/inspector/racks/rack_table_view_model.dart` | VM |
| 4.3 | `lib/features/inspector/racks/rack_detail.dart` | Widget |
| 4.4 | `lib/features/inspector/racks/rack_detail_view_model.dart` | VM |
| 4.5 | `lib/features/inspector/racks/widgets/rack_table.dart` | Widget |
| 4.6 | `lib/features/inspector/racks/widgets/capacity_gauge.dart` | Widget |

### RackTableViewModel API

```dart
class RackTableViewModel extends ChangeNotifier {
  final DataSource _dataSource;
  
  List<Map<String, dynamic>> _racks;
  String? _selectedRackId;
  String _filterText;
  bool _groupByLocation;
  bool _showUnplaced;
  String? _sortColumn;
  bool _sortAscending;
  
  List<Map<String, dynamic>> get filteredRacks;
  String? get selectedRackId;
  Map<String, dynamic>? get selectedRack;
  
  // CHASSIS
  List<Map<String, dynamic>> get chassisForSelectedRack;
  
  // CAPACITY
  double? get powerUtilizationPercent;
  double? get remainingPowerWatts;
  
  Future<void> loadRacks();
  Future<void> selectRack(String id);
  Future<void> deployRack({required String id, required String rackClass, ...});
  Future<void> assignLocation(String rackId, {required String locationRef, required int row, required int col});
  Future<void> addChassis(String rackId, {required int relativePosition, required String neRef, required String componentRef});
  void sortBy(String column);
  void setFilter(String text);
  void toggleGroupBy();
}
```

### CapacityGauge Widget

```dart
class CapacityGauge extends StatelessWidget {
  final double used;       // watts consumed
  final double total;      // watts available
  final double? spatialUtilization; // percent of U-slots used
  
  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (used / total) * 100 : 0;
    return Column(children: [
      // POWER BAR
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Power: ${used.toStringAsFixed(0)}W / ${total.toStringAsFixed(0)}W'),
        Text('${percent.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: percent > 90 ? Colors.red : Colors.green)),
      ]),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(value: percent / 100, minHeight: 8, backgroundColor: Colors.grey[800], valueColor: AlwaysStoppedAnimation(percent > 90 ? Colors.red : Colors.green)),
      ),
      if (spatialUtilization != null) Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('Space: ${spatialUtilization!.toStringAsFixed(0)}% U-slots used'),
      ),
    ]);
  }
}
```

---

## Phase 5: Quality Tab (UC #37)

```
Quality Tab
├── Summary Cards
│   ├── [12 Ready ✓] [3 Stale ✗] [1 Incomplete ⚠] [0 Unknown ?]
│   └── [Re-validate All] button
├── Filter Bar
│   └── [Status: All ▾] [Type: All ▾]
├── Status Table (paginated)
│   ├── location id | type | status | valid-until | has address | has geo
│   └── ... rows ...
└── Pagination: [← Page 1 of 5 →] [25 | 50 | 100 per page]
```

### File List

| # | File | Type |
|---|------|------|
| 5.1 | `lib/features/inspector/quality/quality_dashboard.dart` | Widget |
| 5.2 | `lib/features/inspector/quality/quality_view_model.dart` | VM |
| 5.3 | `lib/features/inspector/quality/widgets/summary_card.dart` | Widget |

---

## Phase 6: Verification & Delivery

### 6.1 Conformance Gate

```bash
python3 scripts/verify_downstream_baseline.py app_flutter
```

### 6.2 Screenshot Capture

| # | Screenshot | Shows |
|---|-----------|-------|
| 1 | `geo-tab-overview.png` | Geo tab with all 5 sections + computed velocity |
| 2 | `geo-tab-validation.png` | Invalid timestamp → error message displayed |
| 3 | `geo-tab-coordinate-toggle.png` | Ellipsoid → Cartesian toggle working |
| 4 | `geo-tab-speed-heading.png` | Speed/heading computed from velocity |
| 5 | `geo-tab-expired.png` | Expired badge on stale location |
| 6 | `ni-tab-tree.png` | Location hierarchy tree with dispatch badges |
| 7 | `ni-tab-detail.png` | Selected location detail with address + geo |
| 8 | `ni-tab-address-form.png` | Physical Address section with country-code validation |
| 9 | `ni-tab-breadcrumb.png` | Breadcrumb: Tokyo-Campus > Building-A > Room-101 |
| 10 | `ni-tab-chassis-table.png` | Location chassis table |
| 11 | `racks-tab-table.png` | Rack inventory table with capacity gauges |
| 12 | `racks-tab-detail.png` | Rack detail with placement + chassis |
| 13 | `racks-tab-deploy.png` | Deploy rack modal form with validation |
| 14 | `racks-tab-capacity.png` | Capacity gauge showing power utilization |
| 15 | `quality-tab-overview.png` | Quality dashboard with summary cards + status table |

### 6.3 Solution Walkthrough

File: `docs/designs/feat-1-geo-location-solution.md`

### 6.4 Release Zip

```bash
zip -r app_flutter_release.zip "app_flutter/build/macos/Build/Products/Release/Platform Console.app"
```

### 6.5 Issue Closure

All features #1-#13, user stories #10-#27, use cases #28-#37 closed on tracker with walkthrough links.

---

**Total: 12 new widgets, 6 new ViewModels, 30 new files, 926 total tests, 15 screenshots.**

Ready for approval.
