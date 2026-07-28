import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = p.join(Directory.current.path, 'assets', 'properties_db.db');
  final file = File(dbPath);
  if (await file.exists()) {
    await file.delete();
  }

  final db = await databaseFactory.openDatabase(dbPath);
  try {
    await _createSchema(db);
    await _seedDatabase(db);
    print('Database regenerated: $dbPath');
  } finally {
    await db.close();
  }

  final gzFile = File('assets/properties_db.db.gz');
  if (await gzFile.exists()) {
    await gzFile.delete();
  }
  final bytes = await file.readAsBytes();
  final gzipped = gzip.encode(bytes);
  await gzFile.writeAsBytes(gzipped);
  print('Database gzipped to properties_db.db.gz successfully.');
}

Future<void> _createSchema(Database db) async {
  await db.execute('PRAGMA journal_mode = WAL;');
  await db.execute('PRAGMA busy_timeout = 5000;');
  await db.execute('PRAGMA foreign_keys = ON;');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS properties (
      node_id TEXT PRIMARY KEY,
      parent_node_id TEXT REFERENCES properties(node_id),
      data_json TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_properties_parent_node_id ON properties(parent_node_id);');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS instances (
      id TEXT PRIMARY KEY,
      parent_node_id TEXT NOT NULL,
      type_name TEXT NOT NULL,
      data_json TEXT NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_instances_parent_type ON instances(parent_node_id, type_name);');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_instances_type_name ON instances(type_name);');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS type_definitions (
      type_name TEXT PRIMARY KEY,
      display_name TEXT NOT NULL,
      icon_name TEXT NOT NULL DEFAULT 'insert_drive_file'
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS type_attributes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type_name TEXT NOT NULL REFERENCES type_definitions(type_name),
      attr_key TEXT NOT NULL,
      label TEXT NOT NULL,
      attr_type TEXT NOT NULL,
      section_label TEXT,
      section_order INTEGER NOT NULL DEFAULT 0,
      is_required INTEGER NOT NULL DEFAULT 0,
      min_value REAL,
      max_value REAL,
      pattern TEXT,
      enum_options TEXT,
      enum_display_names TEXT,
      default_value TEXT,
      input_formatters TEXT,
      UNIQUE(type_name, attr_key)
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS type_relations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_type_name TEXT NOT NULL REFERENCES type_definitions(type_name),
      relation_name TEXT NOT NULL,
      child_type_name TEXT NOT NULL REFERENCES type_definitions(type_name),
      child_label TEXT NOT NULL,
      UNIQUE(parent_type_name, child_type_name)
    )
  ''');
}

Future<void> _seedDatabase(Database db) async {
  final batch = db.batch();

  final spaceDetails = ['Components', 'Telemetry', 'Logs', 'Links'];
  final nttDetails = ['Components', 'Alarms', 'Links'];
  final landingDetails = ['Components', 'Links'];
  final displayNames = {
    'Components': 'Components',
    'Telemetry': 'Telemetry',
    'Logs': 'Logs',
    'Alarms': 'Alarms',
    'Links': 'Links',
  };

  _insertTypeDef(batch, 'ReferenceFrame', 'Reference Frame', 'explore');
  _insertTypeAttr(batch, 'ReferenceFrame', 'astronomical_body', 'Astronomical Body', 'string',
      sectionLabel: 'Frame of Reference', sectionOrder: 0, pattern: r'^[ -@\[-\^_-~]*$', defaultValue: 'earth');
  _insertTypeAttr(batch, 'ReferenceFrame', 'alternate_system', 'Alternate System', 'string',
      sectionLabel: 'Frame of Reference', sectionOrder: 1);

  _insertTypeDef(batch, 'NetworkInventoryLocation', 'Network Inventory Location', 'business');
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'id', 'ID', 'string',
      sectionLabel: 'Identity', sectionOrder: 0, isRequired: 1);
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'uuid', 'UUID', 'string',
      sectionLabel: 'Identity', sectionOrder: 1);
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'name', 'Name', 'string',
      sectionLabel: 'Identity', sectionOrder: 2);
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'alias', 'Alias', 'string',
      sectionLabel: 'Identity', sectionOrder: 3);
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'description', 'Description', 'string',
      sectionLabel: 'Identity', sectionOrder: 4);
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'type', 'Type', 'string',
      sectionLabel: 'Classification', sectionOrder: 0);
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'parent', 'Parent', 'string',
      sectionLabel: 'Classification', sectionOrder: 1);
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'timestamp', 'Timestamp', 'date',
      sectionLabel: 'Temporal', sectionOrder: 0,
      pattern: r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');
  _insertTypeAttr(batch, 'NetworkInventoryLocation', 'valid_until', 'Valid Until', 'date',
      sectionLabel: 'Temporal', sectionOrder: 1,
      pattern: r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');

  _insertTypeDef(batch, 'NI_GeoLocation', 'Geographic Location', 'public');
  _insertTypeAttr(batch, 'NI_GeoLocation', 'timestamp', 'Timestamp', 'date',
      sectionLabel: 'Temporal', sectionOrder: 0,
      pattern: r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');
  _insertTypeAttr(batch, 'NI_GeoLocation', 'valid_until', 'Valid Until', 'date',
      sectionLabel: 'Temporal', sectionOrder: 1,
      pattern: r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');
  _insertTypeAttr(batch, 'NI_GeoLocation', 'astronomical_body', 'Astronomical Body', 'string',
      sectionLabel: 'Geo-Location', sectionOrder: 0, pattern: r'^[ -@\[-\^_-~]*$', defaultValue: 'earth');
  _insertTypeAttr(batch, 'NI_GeoLocation', 'geodetic_datum', 'Geodetic Datum', 'string',
      sectionLabel: 'Geo-Location', sectionOrder: 1, pattern: r'^[ -@\[-\^_-~]*$', defaultValue: 'wgs-84');
  _insertTypeAttr(batch, 'NI_GeoLocation', 'latitude', 'Latitude', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 2, minValue: -90, maxValue: 90);
  _insertTypeAttr(batch, 'NI_GeoLocation', 'longitude', 'Longitude', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 3, minValue: -180, maxValue: 180);
  _insertTypeAttr(batch, 'NI_GeoLocation', 'height', 'Height', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 4);
  _insertTypeAttr(batch, 'NI_GeoLocation', 'x', 'X', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 5);
  _insertTypeAttr(batch, 'NI_GeoLocation', 'y', 'Y', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 6);
  _insertTypeAttr(batch, 'NI_GeoLocation', 'z', 'Z', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 7);
  _insertTypeAttr(batch, 'NI_GeoLocation', 'v_north', 'V North (m/s)', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 8);
  _insertTypeAttr(batch, 'NI_GeoLocation', 'v_east', 'V East (m/s)', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 9);
  _insertTypeAttr(batch, 'NI_GeoLocation', 'v_up', 'V Up (m/s)', 'double',
      sectionLabel: 'Geo-Location', sectionOrder: 10);
  _insertTypeRel(batch, 'NetworkInventoryLocation', 'contains', 'NI_GeoLocation', 'Geographic Location');

  _insertTypeDef(batch, 'PhysicalAddress', 'Physical Address', 'home');
  _insertTypeAttr(batch, 'PhysicalAddress', 'address', 'Address', 'string', sectionLabel: 'Address', sectionOrder: 0);
  _insertTypeAttr(batch, 'PhysicalAddress', 'postal_code', 'Postal Code', 'string', sectionLabel: 'Address', sectionOrder: 1);
  _insertTypeAttr(batch, 'PhysicalAddress', 'state', 'State', 'string', sectionLabel: 'Address', sectionOrder: 2);
  _insertTypeAttr(batch, 'PhysicalAddress', 'city', 'City', 'string', sectionLabel: 'Address', sectionOrder: 3);
  _insertTypeAttr(batch, 'PhysicalAddress', 'country_code', 'Country Code', 'string', sectionLabel: 'Address', sectionOrder: 4, pattern: r'^[A-Z]{2}$');
  _insertTypeRel(batch, 'NetworkInventoryLocation', 'contains', 'PhysicalAddress', 'Physical Address');

  _insertTypeDef(batch, 'LocationChassis', 'Location Chassis', 'dns');
  _insertTypeAttr(batch, 'LocationChassis', 'chassis_id', 'Chassis ID', 'int', sectionLabel: 'Chassis', sectionOrder: 0, isRequired: 1);
  _insertTypeAttr(batch, 'LocationChassis', 'ne_ref', 'NE Reference', 'string', sectionLabel: 'Chassis', sectionOrder: 1);
  _insertTypeAttr(batch, 'LocationChassis', 'component_ref', 'Component Reference', 'string', sectionLabel: 'Chassis', sectionOrder: 2);
  _insertTypeRel(batch, 'NetworkInventoryLocation', 'contains', 'LocationChassis', 'Location Chassis');

  _insertTypeDef(batch, 'RackEntity', 'Rack Entity', 'warehouse');
  _insertTypeAttr(batch, 'RackEntity', 'id', 'ID', 'string', sectionLabel: 'Identity', sectionOrder: 0, isRequired: 1);
  _insertTypeAttr(batch, 'RackEntity', 'rack_class', 'Rack Class', 'enum', sectionLabel: 'Classification', sectionOrder: 0,
      enumOptions: jsonEncode(['rack-standard', 'rack-secure-baseline', 'rack-secure-medium', 'rack-secure-high']));
  _insertTypeAttr(batch, 'RackEntity', 'uuid', 'UUID', 'string', sectionLabel: 'Identity', sectionOrder: 1);
  _insertTypeAttr(batch, 'RackEntity', 'name', 'Name', 'string', sectionLabel: 'Identity', sectionOrder: 2);
  _insertTypeAttr(batch, 'RackEntity', 'alias', 'Alias', 'string', sectionLabel: 'Identity', sectionOrder: 3);
  _insertTypeAttr(batch, 'RackEntity', 'description', 'Description', 'string', sectionLabel: 'Identity', sectionOrder: 4);
  _insertTypeAttr(batch, 'RackEntity', 'height', 'Height (mm)', 'int', sectionLabel: 'Dimensions', sectionOrder: 0, minValue: 0, maxValue: 65535);
  _insertTypeAttr(batch, 'RackEntity', 'width', 'Width (mm)', 'int', sectionLabel: 'Dimensions', sectionOrder: 1, minValue: 0, maxValue: 65535);
  _insertTypeAttr(batch, 'RackEntity', 'depth', 'Depth (mm)', 'int', sectionLabel: 'Dimensions', sectionOrder: 2, minValue: 0, maxValue: 65535);
  _insertTypeAttr(batch, 'RackEntity', 'max_voltage', 'Max Voltage (V)', 'int', sectionLabel: 'Power', sectionOrder: 0, minValue: 0, maxValue: 65535);
  _insertTypeAttr(batch, 'RackEntity', 'max_allocated_power', 'Max Allocated Power (W)', 'int', sectionLabel: 'Power', sectionOrder: 1, minValue: 0, maxValue: 65535);
  _insertTypeAttr(batch, 'RackEntity', 'timestamp', 'Timestamp', 'date', sectionLabel: 'Temporal', sectionOrder: 0,
      pattern: r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');
  _insertTypeAttr(batch, 'RackEntity', 'valid_until', 'Valid Until', 'date', sectionLabel: 'Temporal', sectionOrder: 1,
      pattern: r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');

  _insertTypeDef(batch, 'RackPlacement', 'Rack Placement', 'grid_on');
  _insertTypeAttr(batch, 'RackPlacement', 'location_ref', 'Location Reference', 'string', sectionLabel: 'Placement', sectionOrder: 0);
  _insertTypeAttr(batch, 'RackPlacement', 'row_number', 'Row Number', 'int', sectionLabel: 'Placement', sectionOrder: 1, minValue: 0, maxValue: 4294967295);
  _insertTypeAttr(batch, 'RackPlacement', 'column_number', 'Column Number', 'int', sectionLabel: 'Placement', sectionOrder: 2, minValue: 0, maxValue: 4294967295);
  _insertTypeRel(batch, 'RackEntity', 'contains', 'RackPlacement', 'Rack Placement');

  _insertTypeDef(batch, 'RackChassis', 'Rack Chassis', 'dns');
  _insertTypeAttr(batch, 'RackChassis', 'relative_position', 'Relative Position', 'int', sectionLabel: 'Chassis', sectionOrder: 0, isRequired: 1, minValue: 0, maxValue: 255);
  _insertTypeAttr(batch, 'RackChassis', 'ne_ref', 'NE Reference', 'string', sectionLabel: 'Chassis', sectionOrder: 1);
  _insertTypeAttr(batch, 'RackChassis', 'component_ref', 'Component Reference', 'string', sectionLabel: 'Chassis', sectionOrder: 2);
  _insertTypeRel(batch, 'RackEntity', 'contains', 'RackChassis', 'Rack Chassis');

  for (final d in displayNames.keys) {
    _insertTypeDef(batch, d, displayNames[d] ?? d, 'widgets');
    for (int i = 1; i <= 50; i++) {
      _insertTypeAttr(batch, d, 'field_$i', 'Field $i', 'string', sectionLabel: 'General', sectionOrder: 0);
    }
  }

  _insertTypeDef(batch, 'GeoLocation', 'Geo Location', 'location_on');
  _insertTypeAttr(batch, 'GeoLocation', 'timestamp', 'Timestamp', 'date', sectionLabel: 'Temporal', sectionOrder: 0,
      pattern: r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');
  _insertTypeAttr(batch, 'GeoLocation', 'valid_until', 'Valid Until', 'date', sectionLabel: 'Temporal', sectionOrder: 1,
      pattern: r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$');
  _insertTypeRel(batch, 'Components', 'contains', 'GeoLocation', 'Geo Location');
  _insertTypeRel(batch, 'Components', 'contains', 'NetworkInventoryLocation', 'Network Inventory Location');
  _insertTypeRel(batch, 'Components', 'contains', 'RackEntity', 'Rack Entity');
  _insertTypeRel(batch, 'GeoLocation', 'contains', 'ReferenceFrame', 'Reference Frame');

  _insertTypeDef(batch, 'EllipsoidCoordinates', 'Ellipsoid Coordinates', 'language');
  _insertTypeAttr(batch, 'EllipsoidCoordinates', 'latitude', 'Latitude', 'double', sectionLabel: 'Ellipsoid', sectionOrder: 0, minValue: -90, maxValue: 90);
  _insertTypeAttr(batch, 'EllipsoidCoordinates', 'longitude', 'Longitude', 'double', sectionLabel: 'Ellipsoid', sectionOrder: 1, minValue: -180, maxValue: 180);
  _insertTypeAttr(batch, 'EllipsoidCoordinates', 'height', 'Height', 'double', sectionLabel: 'Ellipsoid', sectionOrder: 2);
  _insertTypeRel(batch, 'GeoLocation', 'contains', 'EllipsoidCoordinates', 'Ellipsoid Coordinates');

  _insertTypeDef(batch, 'CartesianCoordinates', 'Cartesian Coordinates', 'grid_on');
  _insertTypeAttr(batch, 'CartesianCoordinates', 'x', 'X', 'double', sectionLabel: 'Cartesian Location', sectionOrder: 0);
  _insertTypeAttr(batch, 'CartesianCoordinates', 'y', 'Y', 'double', sectionLabel: 'Cartesian Location', sectionOrder: 1);
  _insertTypeAttr(batch, 'CartesianCoordinates', 'z', 'Z', 'double', sectionLabel: 'Cartesian Location', sectionOrder: 2);
  _insertTypeRel(batch, 'GeoLocation', 'contains', 'CartesianCoordinates', 'Cartesian Coordinates');

  _insertTypeDef(batch, 'GeodeticSystem', 'Geodetic System', 'gps_fixed');
  _insertTypeAttr(batch, 'GeodeticSystem', 'geodetic_datum', 'Geodetic Datum', 'string', sectionLabel: 'Geodetic Reference', isRequired: 0, pattern: r'^[ -@\[-\^_-~]*$', defaultValue: 'wgs-84');
  _insertTypeAttr(batch, 'GeodeticSystem', 'coord_accuracy', 'Coordinate Accuracy', 'double', sectionLabel: 'Geodetic Reference', isRequired: 0, minValue: 0);
  _insertTypeAttr(batch, 'GeodeticSystem', 'height_accuracy', 'Height Accuracy', 'double', sectionLabel: 'Geodetic Reference', isRequired: 0, minValue: 0);
  _insertTypeRel(batch, 'ReferenceFrame', 'contains', 'GeodeticSystem', 'Geodetic System');

  _insertTypeDef(batch, 'VelocityVector', 'Velocity Vector', 'speed');
  _insertTypeAttr(batch, 'VelocityVector', 'v_north', 'V North (m/s)', 'double', sectionLabel: 'Velocity', sectionOrder: 0);
  _insertTypeAttr(batch, 'VelocityVector', 'v_east', 'V East (m/s)', 'double', sectionLabel: 'Velocity', sectionOrder: 1);
  _insertTypeAttr(batch, 'VelocityVector', 'v_up', 'V Up (m/s)', 'double', sectionLabel: 'Velocity', sectionOrder: 2);
  _insertTypeRel(batch, 'GeoLocation', 'contains', 'VelocityVector', 'Velocity Vector');

  batch.insert('properties', {
    'node_id': 'geo_location_root',
    'parent_node_id': null,
    'data_json': jsonEncode({'timestamp': '2022-02-11T12:00:00Z', 'valid_until': '2022-02-12T12:00:00Z'}),
  });

  final spaceNodes = <String>[];
  for (int i = 0; i < 100; i++) {
    final id = 'space_$i';
    spaceNodes.add(id);
    final lat = 25.0 + (i / 100.0) * 20.0;
    final lon = 125.0 + (i % 20) * 1.0;
    _addNodeToBatch(batch, id, null, spaceDetails, lat: lat, lon: lon, height: 500000.0);
  }

  final nttFile = File('assets/ntt_exchanges_japan_763.json');
  final nttJsonString = await nttFile.readAsString();
  final nttJson = jsonDecode(nttJsonString) as List;
  final nttNodes = <Map<String, dynamic>>[];
  for (int i = 0; i < nttJson.length; i++) {
    final item = nttJson[i];
    final id = 'ntt_exchange_$i';
    nttNodes.add({'id': id, 'lat': (item['latitude'] as num).toDouble(), 'lon': (item['longitude'] as num).toDouble()});
    _addNodeToBatch(batch, id, null, nttDetails, lat: (item['latitude'] as num).toDouble(), lon: (item['longitude'] as num).toDouble(), height: 0.0);
  }

  final landingFile = File('assets/cable_landing_stations_japan.json');
  final landingJsonString = await landingFile.readAsString();
  final landingJson = jsonDecode(landingJsonString) as List;
  final landingNodes = <Map<String, dynamic>>[];
  for (int i = 0; i < landingJson.length; i++) {
    final item = landingJson[i];
    final id = 'cable_landing_$i';
    landingNodes.add({'id': id, 'lat': (item['latitude'] as num).toDouble(), 'lon': (item['longitude'] as num).toDouble()});
    _addNodeToBatch(batch, id, null, landingDetails, lat: (item['latitude'] as num).toDouble(), lon: (item['longitude'] as num).toDouble(), height: 0.0);
  }

  final addedLinks = <String>{};
  int linkIdCounter = 0;
  void addLink(String from, String to) {
    final k1 = '${from}_$to';
    final k2 = '${to}_$from';
    if (!addedLinks.contains(k1) && !addedLinks.contains(k2)) {
      addedLinks.add(k1);
      addedLinks.add(k2);
      batch.insert('instances', {
        'id': 'link_${linkIdCounter++}',
        'parent_node_id': from,
        'type_name': 'interface',
        'data_json': jsonEncode({'description': 'link to node $to'}),
      });
    }
  }

  double distSq(double lat1, double lon1, double lat2, double lon2) {
    return (lat1 - lat2) * (lat1 - lat2) + (lon1 - lon2) * (lon1 - lon2);
  }

  for (int i = 0; i < nttNodes.length; i++) {
    final current = nttNodes[i];
    final distances = <Map<String, dynamic>>[];
    for (int j = 0; j < nttNodes.length; j++) {
      if (i == j) continue;
      final target = nttNodes[j];
      distances.add({'id': target['id'], 'dist': distSq(current['lat'] as double, current['lon'] as double, target['lat'] as double, target['lon'] as double)});
    }
    distances.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
    for (int k = 0; k < 2 && k < distances.length; k++) {
      addLink(current['id'] as String, distances[k]['id'] as String);
    }
    final s1 = spaceNodes[(i * 2) % 100];
    final s2 = spaceNodes[(i * 2 + 1) % 100];
    addLink(current['id'] as String, s1);
    addLink(current['id'] as String, s2);
  }

  for (int i = 0; i < landingNodes.length; i++) {
    final current = landingNodes[i];
    final distances = <Map<String, dynamic>>[];
    for (int j = 0; j < nttNodes.length; j++) {
      final target = nttNodes[j];
      distances.add({'id': target['id'], 'dist': distSq(current['lat'] as double, current['lon'] as double, target['lat'] as double, target['lon'] as double)});
    }
    distances.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
    for (int k = 0; k < 5 && k < distances.length; k++) {
      addLink(current['id'] as String, distances[k]['id'] as String);
    }
  }

  await batch.commit(noResult: true);

  final batch2 = db.batch();

  for (int i = 0; i < nttNodes.length; i++) {
    final nodeId = nttNodes[i]['id'] as String;

    batch2.insert('type_relations', {
      'parent_type_name': nodeId,
      'relation_name': 'contains',
      'child_type_name': 'LocationChassis',
      'child_label': 'Location Chassis',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('instances', {
      'id': 'inst_${nodeId}_LocationChassis_1',
      'parent_node_id': nodeId,
      'type_name': 'LocationChassis',
      'data_json': jsonEncode({
        'chassis_id': 1,
        'ne_ref': 'NE-$i',
        'component_ref': 'comp-$i-1',
      }),
    });

    batch2.insert('instances', {
      'id': 'inst_${nodeId}_LocationChassis_2',
      'parent_node_id': nodeId,
      'type_name': 'LocationChassis',
      'data_json': jsonEncode({
        'chassis_id': 2,
        'ne_ref': 'NE-$i',
        'component_ref': 'comp-$i-2',
      }),
    });
  }

  final nilLocations = [
    {
      'id': 'nil_location_site',
      'type': 'site',
      'name': 'Tokyo Campus',
      'parent': null,
      'display_name': 'Tokyo Campus (Site)',
      'uuid': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    },
    {
      'id': 'nil_location_building',
      'type': 'building',
      'name': 'Building A',
      'parent': 'nil_location_site',
      'display_name': 'Building A',
      'uuid': 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
      'physical_address': '1-2-3 Shinjuku',
      'postal_code': '160-0022',
      'state': 'Tokyo',
      'city': 'Shinjuku',
      'country_code': 'JP',
    },
    {
      'id': 'nil_location_room',
      'type': 'equipment-room',
      'name': 'Equipment Room 101',
      'parent': 'nil_location_building',
      'display_name': 'Equipment Room 101',
      'uuid': 'c3d4e5f6-a7b8-9012-cdef-123456789012',
      'latitude': 35.6895,
      'longitude': 139.6917,
      'height': 45.0,
    },
    {
      'id': 'nil_location_room2',
      'type': 'equipment-room',
      'name': 'Equipment Room 201',
      'parent': 'nil_location_building',
      'display_name': 'Equipment Room 201',
      'uuid': 'd4e5f6a7-b8c9-0123-defa-123456789013',
      'physical_address': '1-2-3 Shinjuku',
      'postal_code': '160-0022',
      'state': 'Tokyo',
      'city': 'Shinjuku',
      'country_code': 'JP',
      'latitude': 35.6895,
      'longitude': 139.6917,
      'height': 45.0,
    },
    {
      'id': 'nil_location_pole',
      'type': 'pole',
      'name': 'Utility Pole TK-01',
      'parent': null,
      'display_name': 'Utility Pole TK-01 (Pole)',
      'uuid': 'e5f6a7b8-c9d0-1234-efab-123456789014',
    },
  ];

  for (final loc in nilLocations) {
    final locId = loc['id'] as String;
    final locType = loc['type'] as String;
    final locName = loc['name'] as String;
    final locParent = loc['parent'];
    final displayName = loc['display_name'] as String;

    batch2.insert('type_definitions', {
      'type_name': locId,
      'display_name': displayName,
      'icon_name': 'business',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_relations', {
      'parent_type_name': 'Components',
      'relation_name': 'contains',
      'child_type_name': locId,
      'child_label': locName,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'id',
      'label': 'ID',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 0,
      'is_required': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'type',
      'label': 'Type',
      'attr_type': 'string',
      'section_label': 'Classification',
      'section_order': 0,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'parent',
      'label': 'Parent',
      'attr_type': 'string',
      'section_label': 'Classification',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'timestamp',
      'label': 'Timestamp',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 0,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'valid_until',
      'label': 'Valid Until',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 1,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'uuid',
      'label': 'UUID',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'physical_address',
      'label': 'Physical Address',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 0,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'postal_code',
      'label': 'Postal Code',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'state',
      'label': 'State',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'city',
      'label': 'City',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 3,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'country_code',
      'label': 'Country Code',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 4,
      'is_required': 0,
      'pattern': r'^[A-Z]{2}$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'latitude',
      'label': 'Latitude',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 0,
      'is_required': 0,
      'min_value': -90,
      'max_value': 90,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'longitude',
      'label': 'Longitude',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 1,
      'is_required': 0,
      'min_value': -180,
      'max_value': 180,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': locId,
      'attr_key': 'height',
      'label': 'Height',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final propData = <String, dynamic>{
      'id': locId,
      'type': locType,
      'name': locName,
      'parent': locParent,
      'uuid': loc['uuid'],
      'timestamp': '2024-06-15T10:00:00Z',
      'valid_until': '2030-12-31T23:59:59Z',
    };
    if (loc.containsKey('physical_address'))
      propData['physical_address'] = loc['physical_address'];
    if (loc.containsKey('postal_code'))
      propData['postal_code'] = loc['postal_code'];
    if (loc.containsKey('state'))
      propData['state'] = loc['state'];
    if (loc.containsKey('city'))
      propData['city'] = loc['city'];
    if (loc.containsKey('country_code'))
      propData['country_code'] = loc['country_code'];
    if (loc.containsKey('latitude'))
      propData['latitude'] = loc['latitude'];
    if (loc.containsKey('longitude'))
      propData['longitude'] = loc['longitude'];
    if (loc.containsKey('height'))
      propData['height'] = loc['height'];

    batch2.insert('properties', {
      'node_id': locId,
      'parent_node_id': null,
      'data_json': jsonEncode(propData),
    });
  }

  final racks = [
    {
      'id': 'rack_101_a',
      'rack_class': 'rack-secure-medium',
      'height': 2200,
      'width': 600,
      'depth': 1200,
      'max_voltage': 240,
      'max_allocated_power': 8000,
      'display_name': 'Rack 101-A',
      'location_ref': 'nil_location_room',
      'row': 1,
      'col': 1,
      'chassis': [
        {'relative_position': 10, 'ne_ref': 'NE-1', 'component_ref': 'comp-1-1'},
        {'relative_position': 20, 'ne_ref': 'NE-2', 'component_ref': 'comp-2-1'},
      ],
    },
    {
      'id': 'rack_201_b',
      'rack_class': 'rack-standard',
      'height': 2000,
      'width': 600,
      'depth': 1000,
      'max_voltage': 240,
      'max_allocated_power': 6000,
      'display_name': 'Rack 201-B',
      'location_ref': 'nil_location_room2',
      'row': 1,
      'col': 2,
      'chassis': [
        {'relative_position': 5, 'ne_ref': 'NE-3', 'component_ref': 'comp-3-1'},
      ],
    },
  ];

  for (final rack in racks) {
    final rackId = rack['id'] as String;
    final rackClass = rack['rack_class'] as String;
    final height = rack['height'] as int;
    final width = rack['width'] as int;
    final depth = rack['depth'] as int;
    final maxVoltage = rack['max_voltage'] as int;
    final maxAllocatedPower = rack['max_allocated_power'] as int;
    final displayName = rack['display_name'] as String;
    final locationRef = rack['location_ref'] as String;
    final row = rack['row'] as int;
    final col = rack['col'] as int;
    final chassisList = rack['chassis'] as List;

    batch2.insert('type_definitions', {
      'type_name': rackId,
      'display_name': displayName,
      'icon_name': 'warehouse',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_relations', {
      'parent_type_name': 'Components',
      'relation_name': 'contains',
      'child_type_name': rackId,
      'child_label': displayName,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'id',
      'label': 'ID',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 0,
      'is_required': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'rack_class',
      'label': 'Rack Class',
      'attr_type': 'enum',
      'section_label': 'Classification',
      'section_order': 0,
      'is_required': 0,
      'enum_options': jsonEncode([
        'rack-standard',
        'rack-secure-baseline',
        'rack-secure-medium',
        'rack-secure-high',
      ]),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'height',
      'label': 'Height (mm)',
      'attr_type': 'int',
      'section_label': 'Dimensions',
      'section_order': 0,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'width',
      'label': 'Width (mm)',
      'attr_type': 'int',
      'section_label': 'Dimensions',
      'section_order': 1,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'depth',
      'label': 'Depth (mm)',
      'attr_type': 'int',
      'section_label': 'Dimensions',
      'section_order': 2,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'max_voltage',
      'label': 'Max Voltage (V)',
      'attr_type': 'int',
      'section_label': 'Power',
      'section_order': 0,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'max_allocated_power',
      'label': 'Max Allocated Power (W)',
      'attr_type': 'int',
      'section_label': 'Power',
      'section_order': 1,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'timestamp',
      'label': 'Timestamp',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 0,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_attributes', {
      'type_name': rackId,
      'attr_key': 'valid_until',
      'label': 'Valid Until',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 1,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('properties', {
      'node_id': rackId,
      'parent_node_id': null,
      'data_json': jsonEncode({
        'id': rackId,
        'rack_class': rackClass,
        'height': height,
        'width': width,
        'depth': depth,
        'max_voltage': maxVoltage,
        'max_allocated_power': maxAllocatedPower,
        'timestamp': '2024-01-01T00:00:00Z',
        'valid_until': '2030-12-31T23:59:59Z',
      }),
    });

    final placementId = '${rackId}_placement';
    batch2.insert('type_definitions', {
      'type_name': placementId,
      'display_name': '$displayName Placement',
      'icon_name': 'grid_on',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('type_relations', {
      'parent_type_name': rackId,
      'relation_name': 'contains',
      'child_type_name': placementId,
      'child_label': 'Rack Placement',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch2.insert('instances', {
      'id': 'inst_${rackId}_RackPlacement',
      'parent_node_id': rackId,
      'type_name': 'RackPlacement',
      'data_json': jsonEncode({
        'location_ref': locationRef,
        'row_number': row,
        'column_number': col,
      }),
    });

    for (final chassis in chassisList) {
      final relPos = chassis['relative_position'] as int;
      final neRef = chassis['ne_ref'] as String;
      final compRef = chassis['component_ref'] as String;

      batch2.insert('instances', {
        'id': 'inst_${rackId}_RackChassis_$relPos',
        'parent_node_id': rackId,
        'type_name': 'RackChassis',
        'data_json': jsonEncode({
          'relative_position': relPos,
          'ne_ref': neRef,
          'component_ref': compRef,
        }),
      });
    }
  }

  await batch2.commit(noResult: true);
}

void _insertTypeDef(Batch batch, String typeName, String displayName, String iconName) {
  batch.insert('type_definitions', {'type_name': typeName, 'display_name': displayName, 'icon_name': iconName}, conflictAlgorithm: ConflictAlgorithm.ignore);
}

void _insertTypeAttr(Batch batch, String typeName, String attrKey, String label, String attrType, {
  String? sectionLabel,
  int sectionOrder = 0,
  int isRequired = 0,
  double? minValue,
  double? maxValue,
  String? pattern,
  String? enumOptions,
  String? defaultValue,
}) {
  batch.insert('type_attributes', {
    'type_name': typeName,
    'attr_key': attrKey,
    'label': label,
    'attr_type': attrType,
    if (sectionLabel != null) 'section_label': sectionLabel,
    'section_order': sectionOrder,
    'is_required': isRequired,
    if (minValue != null) 'min_value': minValue,
    if (maxValue != null) 'max_value': maxValue,
    if (pattern != null) 'pattern': pattern,
    if (enumOptions != null) 'enum_options': enumOptions,
    if (defaultValue != null) 'default_value': defaultValue,
  }, conflictAlgorithm: ConflictAlgorithm.ignore);
}

void _insertTypeRel(Batch batch, String parent, String relation, String child, String label) {
  batch.insert('type_relations', {'parent_type_name': parent, 'relation_name': relation, 'child_type_name': child, 'child_label': label}, conflictAlgorithm: ConflictAlgorithm.ignore);
}

void _addNodeToBatch(Batch batch, String node, String? parent, List<String> details, {
  required double lat,
  required double lon,
  required double height,
}) {
  batch.insert('type_definitions', {'type_name': node, 'display_name': node.replaceAll('_', ' '), 'icon_name': 'insert_drive_file'});

  for (final d in details) {
    batch.insert('type_relations', {
      'parent_type_name': node,
      'relation_name': 'contains',
      'child_type_name': d,
      'child_label': d == 'Components' ? 'Components' : d.replaceAll('_', ' ').split(' ').map((s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1)).join(' '),
    });
  }

  for (int i = 1; i <= 50; i++) {
    batch.insert('type_attributes', {
      'type_name': node,
      'attr_key': 'field_$i',
      'label': 'Field $i',
      'attr_type': 'string',
      'section_label': 'General',
      'section_order': 0,
      'is_required': 0,
    });
  }

  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'geo_location_timestamp',
    'label': 'Timestamp',
    'attr_type': 'date',
    'section_label': 'Geo Location',
    'section_order': 0,
    'is_required': 0,
    'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'geo_location_valid_until',
    'label': 'Valid Until',
    'attr_type': 'date',
    'section_label': 'Geo Location',
    'section_order': 1,
    'is_required': 0,
    'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'reference_frame_astronomical_body',
    'label': 'Astronomical Body',
    'attr_type': 'string',
    'section_label': 'Reference Frame',
    'section_order': 0,
    'is_required': 0,
    'default_value': 'earth',
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'reference_frame_alternate_system',
    'label': 'Alternate System',
    'attr_type': 'string',
    'section_label': 'Reference Frame',
    'section_order': 1,
    'is_required': 0,
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'geodetic_datum',
    'label': 'Geodetic Datum',
    'attr_type': 'string',
    'section_label': 'Geodetic System',
    'section_order': 0,
    'is_required': 0,
    'default_value': 'wgs-84',
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'coord_accuracy',
    'label': 'Coordinate Accuracy',
    'attr_type': 'double',
    'section_label': 'Geodetic System',
    'section_order': 1,
    'is_required': 0,
    'min_value': 0,
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'height_accuracy',
    'label': 'Height Accuracy',
    'attr_type': 'double',
    'section_label': 'Geodetic System',
    'section_order': 2,
    'is_required': 0,
    'min_value': 0,
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'ellipsoid_latitude',
    'label': 'Latitude',
    'attr_type': 'double',
    'section_label': 'Ellipsoid Coordinates',
    'section_order': 0,
    'is_required': 0,
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'ellipsoid_longitude',
    'label': 'Longitude',
    'attr_type': 'double',
    'section_label': 'Ellipsoid Coordinates',
    'section_order': 1,
    'is_required': 0,
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'ellipsoid_height',
    'label': 'Height',
    'attr_type': 'double',
    'section_label': 'Ellipsoid Coordinates',
    'section_order': 2,
    'is_required': 0,
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'velocity_v_north',
    'label': 'V North (m/s)',
    'attr_type': 'double',
    'section_label': 'Velocity',
    'section_order': 0,
    'is_required': 0,
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'velocity_v_east',
    'label': 'V East (m/s)',
    'attr_type': 'double',
    'section_label': 'Velocity',
    'section_order': 1,
    'is_required': 0,
  });
  batch.insert('type_attributes', {
    'type_name': node,
    'attr_key': 'velocity_v_up',
    'label': 'V Up (m/s)',
    'attr_type': 'double',
    'section_label': 'Velocity',
    'section_order': 2,
    'is_required': 0,
  });

  final propertiesMap = {
    for (int j = 1; j <= 50; j++) 'field_$j': 'val_${node}_field_$j',
    'location': {'ellipsoid': {'latitude': lat, 'longitude': lon, 'height': height}},
    'geo_location_timestamp': '2024-01-01T00:00:00Z',
    'geo_location_valid_until': '2030-12-31T23:59:59Z',
    'reference_frame_astronomical_body': 'earth',
    'geodetic_datum': 'wgs-84',
    'ellipsoid_latitude': lat,
    'ellipsoid_longitude': lon,
    'ellipsoid_height': height,
    'velocity_v_north': 0,
    'velocity_v_east': 0,
    'velocity_v_up': 0,
  };
  batch.insert('properties', {'node_id': node, 'parent_node_id': parent, 'data_json': jsonEncode(propertiesMap)});

  for (final d in details) {
    for (int k = 1; k <= 5; k++) {
      final instId = 'inst_${node}_${d}_$k';
      final instanceMap = {for (int j = 1; j <= 50; j++) 'field_$j': 'val_inst_${node}_${d}_${k}_field_$j'};
      batch.insert('instances', {'id': instId, 'parent_node_id': node, 'type_name': d, 'data_json': jsonEncode(instanceMap)});
    }
  }
}
