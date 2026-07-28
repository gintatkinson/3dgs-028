import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_initializer.dart';

/// Concrete implementation of [SeedStrategy] that seeds the database with domain-specific mock data.
///
/// This includes base type definitions, attributes, space nodes, real NTT exchanges,
/// cable landing stations, and their interconnectivity links.
class DomainSeedStrategy implements SeedStrategy {
  
  /// Seeds the database by batch-inserting default schemas, nodes, and instances.
  ///
  /// Assumes the database tables have been successfully created by [DatabaseInitializer].
  @override
  Future<void> seed(Database db) async {
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

    // 0. Seed ReferenceFrame type definition and attributes (relation added after GeoLocation below)
    batch.insert('type_definitions', {
      'type_name': 'ReferenceFrame',
      'display_name': 'Reference Frame',
      'icon_name': 'explore',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'ReferenceFrame',
      'attr_key': 'astronomical_body',
      'label': 'Astronomical Body',
      'attr_type': 'string',
      'section_label': 'Frame of Reference',
      'section_order': 0,
      'is_required': 0,
      'pattern': r'^[ -@\[-\^_-~]*$',
      'default_value': 'earth',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'ReferenceFrame',
      'attr_key': 'alternate_system',
      'label': 'Alternate System',
      'attr_type': 'string',
      'section_label': 'Frame of Reference',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1a. Seed NetworkInventoryLocation type definition and attributes
    // (type_relation is deferred to after the Components loop to satisfy FK ordering)
    batch.insert('type_definitions', {
      'type_name': 'NetworkInventoryLocation',
      'display_name': 'Network Inventory Location',
      'icon_name': 'business',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'id',
      'label': 'ID',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 0,
      'is_required': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'uuid',
      'label': 'UUID',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'name',
      'label': 'Name',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'alias',
      'label': 'Alias',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 3,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'description',
      'label': 'Description',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 4,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'type',
      'label': 'Type',
      'attr_type': 'string',
      'section_label': 'Classification',
      'section_order': 0,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'parent',
      'label': 'Parent',
      'attr_type': 'string',
      'section_label': 'Classification',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'timestamp',
      'label': 'Timestamp',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 0,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NetworkInventoryLocation',
      'attr_key': 'valid_until',
      'label': 'Valid Until',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 1,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1b2. Seed NI_GeoLocation type definition, attributes, and relation to
    // NetworkInventoryLocation
    batch.insert('type_definitions', {
      'type_name': 'NI_GeoLocation',
      'display_name': 'Geographic Location',
      'icon_name': 'public',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'timestamp',
      'label': 'Timestamp',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 0,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'valid_until',
      'label': 'Valid Until',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 1,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'astronomical_body',
      'label': 'Astronomical Body',
      'attr_type': 'string',
      'section_label': 'Geo-Location',
      'section_order': 0,
      'is_required': 0,
      'pattern': r'^[ -@\[-\^_-~]*$',
      'default_value': 'earth',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'geodetic_datum',
      'label': 'Geodetic Datum',
      'attr_type': 'string',
      'section_label': 'Geo-Location',
      'section_order': 1,
      'is_required': 0,
      'pattern': r'^[ -@\[-\^_-~]*$',
      'default_value': 'wgs-84',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'latitude',
      'label': 'Latitude',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 2,
      'is_required': 0,
      'min_value': -90,
      'max_value': 90,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'longitude',
      'label': 'Longitude',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 3,
      'is_required': 0,
      'min_value': -180,
      'max_value': 180,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'height',
      'label': 'Height',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 4,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'x',
      'label': 'X',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 5,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'y',
      'label': 'Y',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 6,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'z',
      'label': 'Z',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 7,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'v_north',
      'label': 'V North (m/s)',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 8,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'v_east',
      'label': 'V East (m/s)',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 9,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'NI_GeoLocation',
      'attr_key': 'v_up',
      'label': 'V Up (m/s)',
      'attr_type': 'double',
      'section_label': 'Geo-Location',
      'section_order': 10,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'NetworkInventoryLocation',
      'relation_name': 'contains',
      'child_type_name': 'NI_GeoLocation',
      'child_label': 'Geographic Location',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1c. Seed PhysicalAddress type definition, attributes, and relation to
    // NetworkInventoryLocation
    batch.insert('type_definitions', {
      'type_name': 'PhysicalAddress',
      'display_name': 'Physical Address',
      'icon_name': 'home',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'PhysicalAddress',
      'attr_key': 'address',
      'label': 'Address',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 0,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'PhysicalAddress',
      'attr_key': 'postal_code',
      'label': 'Postal Code',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'PhysicalAddress',
      'attr_key': 'state',
      'label': 'State',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'PhysicalAddress',
      'attr_key': 'city',
      'label': 'City',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 3,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'PhysicalAddress',
      'attr_key': 'country_code',
      'label': 'Country Code',
      'attr_type': 'string',
      'section_label': 'Address',
      'section_order': 4,
      'is_required': 0,
      'pattern': r'^[A-Z]{2}$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'NetworkInventoryLocation',
      'relation_name': 'contains',
      'child_type_name': 'PhysicalAddress',
      'child_label': 'Physical Address',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1cz. Seed LocationChassis type definition, attributes, and relation to
    // NetworkInventoryLocation
    batch.insert('type_definitions', {
      'type_name': 'LocationChassis',
      'display_name': 'Location Chassis',
      'icon_name': 'dns',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'LocationChassis',
      'attr_key': 'chassis_id',
      'label': 'Chassis ID',
      'attr_type': 'int',
      'section_label': 'Chassis',
      'section_order': 0,
      'is_required': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'LocationChassis',
      'attr_key': 'ne_ref',
      'label': 'NE Reference',
      'attr_type': 'string',
      'section_label': 'Chassis',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'LocationChassis',
      'attr_key': 'component_ref',
      'label': 'Component Reference',
      'attr_type': 'string',
      'section_label': 'Chassis',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'NetworkInventoryLocation',
      'relation_name': 'contains',
      'child_type_name': 'LocationChassis',
      'child_label': 'Location Chassis',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1d. Seed RackEntity type definition, attributes, and relation to Components
    batch.insert('type_definitions', {
      'type_name': 'RackEntity',
      'display_name': 'Rack Entity',
      'icon_name': 'warehouse',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'id',
      'label': 'ID',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 0,
      'is_required': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
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

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'uuid',
      'label': 'UUID',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'name',
      'label': 'Name',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'alias',
      'label': 'Alias',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 3,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'description',
      'label': 'Description',
      'attr_type': 'string',
      'section_label': 'Identity',
      'section_order': 4,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'height',
      'label': 'Height (mm)',
      'attr_type': 'int',
      'section_label': 'Dimensions',
      'section_order': 0,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'width',
      'label': 'Width (mm)',
      'attr_type': 'int',
      'section_label': 'Dimensions',
      'section_order': 1,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'depth',
      'label': 'Depth (mm)',
      'attr_type': 'int',
      'section_label': 'Dimensions',
      'section_order': 2,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'max_voltage',
      'label': 'Max Voltage (V)',
      'attr_type': 'int',
      'section_label': 'Power',
      'section_order': 0,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'max_allocated_power',
      'label': 'Max Allocated Power (W)',
      'attr_type': 'int',
      'section_label': 'Power',
      'section_order': 1,
      'is_required': 0,
      'min_value': 0,
      'max_value': 65535,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'timestamp',
      'label': 'Timestamp',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 0,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackEntity',
      'attr_key': 'valid_until',
      'label': 'Valid Until',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 1,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1e. Seed RackPlacement type definition, attributes, and relation to RackEntity
    batch.insert('type_definitions', {
      'type_name': 'RackPlacement',
      'display_name': 'Rack Placement',
      'icon_name': 'grid_on',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackPlacement',
      'attr_key': 'location_ref',
      'label': 'Location Reference',
      'attr_type': 'string',
      'section_label': 'Placement',
      'section_order': 0,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackPlacement',
      'attr_key': 'row_number',
      'label': 'Row Number',
      'attr_type': 'int',
      'section_label': 'Placement',
      'section_order': 1,
      'is_required': 0,
      'min_value': 0,
      'max_value': 4294967295,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackPlacement',
      'attr_key': 'column_number',
      'label': 'Column Number',
      'attr_type': 'int',
      'section_label': 'Placement',
      'section_order': 2,
      'is_required': 0,
      'min_value': 0,
      'max_value': 4294967295,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'RackEntity',
      'relation_name': 'contains',
      'child_type_name': 'RackPlacement',
      'child_label': 'Rack Placement',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1e2. Seed RackChassis type definition, attributes, and relation to
    // RackEntity
    batch.insert('type_definitions', {
      'type_name': 'RackChassis',
      'display_name': 'Rack Chassis',
      'icon_name': 'dns',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackChassis',
      'attr_key': 'relative_position',
      'label': 'Relative Position',
      'attr_type': 'int',
      'section_label': 'Chassis',
      'section_order': 0,
      'is_required': 1,
      'min_value': 0,
      'max_value': 255,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackChassis',
      'attr_key': 'ne_ref',
      'label': 'NE Reference',
      'attr_type': 'string',
      'section_label': 'Chassis',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'RackChassis',
      'attr_key': 'component_ref',
      'label': 'Component Reference',
      'attr_type': 'string',
      'section_label': 'Chassis',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'RackEntity',
      'relation_name': 'contains',
      'child_type_name': 'RackChassis',
      'child_label': 'Rack Chassis',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // 1. Seed base system type definitions and their 50 generic attributes
    for (final d in displayNames.keys) {
      batch.insert('type_definitions', {
        'type_name': d,
        'display_name': displayNames[d] ?? d,
        'icon_name': 'widgets',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      for (int i = 1; i <= 50; i++) {
        batch.insert('type_attributes', {
          'type_name': d,
          'attr_key': 'field_$i',
          'label': 'Field $i',
          'attr_type': 'string',
          'section_label': 'General',
          'section_order': 0,
          'is_required': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    // 1b. Seed GeoLocation type definition, attributes, relations, and sample node
    batch.insert('type_definitions', {
      'type_name': 'GeoLocation',
      'display_name': 'Geo Location',
      'icon_name': 'location_on',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'GeoLocation',
      'attr_key': 'timestamp',
      'label': 'Timestamp',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 0,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'GeoLocation',
      'attr_key': 'valid_until',
      'label': 'Valid Until',
      'attr_type': 'date',
      'section_label': 'Temporal',
      'section_order': 1,
      'is_required': 0,
      'pattern': r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'Components',
      'relation_name': 'contains',
      'child_type_name': 'GeoLocation',
      'child_label': 'Geo Location',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'Components',
      'relation_name': 'contains',
      'child_type_name': 'NetworkInventoryLocation',
      'child_label': 'Network Inventory Location',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'Components',
      'relation_name': 'contains',
      'child_type_name': 'RackEntity',
      'child_label': 'Rack Entity',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'GeoLocation',
      'relation_name': 'contains',
      'child_type_name': 'ReferenceFrame',
      'child_label': 'Reference Frame',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // EllipsoidCoordinates type definition, attributes, and relation to GeoLocation
    batch.insert('type_definitions', {
      'type_name': 'EllipsoidCoordinates',
      'display_name': 'Ellipsoid Coordinates',
      'icon_name': 'language',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'EllipsoidCoordinates',
      'attr_key': 'latitude',
      'label': 'Latitude',
      'attr_type': 'double',
      'section_label': 'Ellipsoid',
      'section_order': 0,
      'is_required': 0,
      'min_value': -90,
      'max_value': 90,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'EllipsoidCoordinates',
      'attr_key': 'longitude',
      'label': 'Longitude',
      'attr_type': 'double',
      'section_label': 'Ellipsoid',
      'section_order': 1,
      'is_required': 0,
      'min_value': -180,
      'max_value': 180,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'EllipsoidCoordinates',
      'attr_key': 'height',
      'label': 'Height',
      'attr_type': 'double',
      'section_label': 'Ellipsoid',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'GeoLocation',
      'relation_name': 'contains',
      'child_type_name': 'EllipsoidCoordinates',
      'child_label': 'Ellipsoid Coordinates',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // CartesianCoordinates type definition, attributes, and relation to GeoLocation
    batch.insert('type_definitions', {
      'type_name': 'CartesianCoordinates',
      'display_name': 'Cartesian Coordinates',
      'icon_name': 'grid_on',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'CartesianCoordinates',
      'attr_key': 'x',
      'label': 'X',
      'attr_type': 'double',
      'section_label': 'Cartesian Location',
      'section_order': 0,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'CartesianCoordinates',
      'attr_key': 'y',
      'label': 'Y',
      'attr_type': 'double',
      'section_label': 'Cartesian Location',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'CartesianCoordinates',
      'attr_key': 'z',
      'label': 'Z',
      'attr_type': 'double',
      'section_label': 'Cartesian Location',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'GeoLocation',
      'relation_name': 'contains',
      'child_type_name': 'CartesianCoordinates',
      'child_label': 'Cartesian Coordinates',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // GeodeticSystem type definition, attributes, and relation to ReferenceFrame
    batch.insert('type_definitions', {
      'type_name': 'GeodeticSystem',
      'display_name': 'Geodetic System',
      'icon_name': 'gps_fixed',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'GeodeticSystem',
      'attr_key': 'geodetic_datum',
      'label': 'Geodetic Datum',
      'attr_type': 'string',
      'section_label': 'Geodetic Reference',
      'is_required': 0,
      'pattern': r'^[ -@\[-\^_-~]*$',
      'default_value': 'wgs-84',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'GeodeticSystem',
      'attr_key': 'coord_accuracy',
      'label': 'Coordinate Accuracy',
      'attr_type': 'double',
      'section_label': 'Geodetic Reference',
      'is_required': 0,
      'min_value': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'GeodeticSystem',
      'attr_key': 'height_accuracy',
      'label': 'Height Accuracy',
      'attr_type': 'double',
      'section_label': 'Geodetic Reference',
      'is_required': 0,
      'min_value': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'ReferenceFrame',
      'relation_name': 'contains',
      'child_type_name': 'GeodeticSystem',
      'child_label': 'Geodetic System',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // VelocityVector type definition and attributes
    batch.insert('type_definitions', {
      'type_name': 'VelocityVector',
      'display_name': 'Velocity Vector',
      'icon_name': 'speed',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'VelocityVector',
      'attr_key': 'v_north',
      'label': 'V North (m/s)',
      'attr_type': 'double',
      'section_label': 'Velocity',
      'section_order': 0,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'VelocityVector',
      'attr_key': 'v_east',
      'label': 'V East (m/s)',
      'attr_type': 'double',
      'section_label': 'Velocity',
      'section_order': 1,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_attributes', {
      'type_name': 'VelocityVector',
      'attr_key': 'v_up',
      'label': 'V Up (m/s)',
      'attr_type': 'double',
      'section_label': 'Velocity',
      'section_order': 2,
      'is_required': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('type_relations', {
      'parent_type_name': 'GeoLocation',
      'relation_name': 'contains',
      'child_type_name': 'VelocityVector',
      'child_label': 'Velocity Vector',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    batch.insert('properties', {
      'node_id': 'geo_location_root',
      'parent_node_id': null,
      'data_json': jsonEncode({
        'timestamp': '2022-02-11T12:00:00Z',
        'valid_until': '2022-02-12T12:00:00Z',
      }),
    });

    // 2. Generate 100 space orbit telemetry nodes
    final spaceNodes = <String>[];
    for (int i = 0; i < 100; i++) {
      final id = 'space_$i';
      spaceNodes.add(id);
      final lat = 25.0 + (i / 100.0) * 20.0;
      final lon = 125.0 + (i % 20) * 1.0;
      _addNodeToBatch(batch, id, null, spaceDetails, lat: lat, lon: lon, height: 500000.0);
    }

    // 3. Load and parse real NTT exchanges data from assets
    final nttFile = File('assets/ntt_exchanges_japan_763.json');
    String nttJsonString;
    if (await nttFile.exists()) {
      nttJsonString = await nttFile.readAsString();
    } else {
      nttJsonString = await rootBundle.loadString('assets/ntt_exchanges_japan_763.json');
    }
    final nttJson = jsonDecode(nttJsonString) as List;

    final nttNodes = <Map<String, dynamic>>[];
    for (int i = 0; i < nttJson.length; i++) {
      final item = nttJson[i];
      final id = 'ntt_exchange_$i';
      nttNodes.add({
        'id': id,
        'lat': (item['latitude'] as num).toDouble(),
        'lon': (item['longitude'] as num).toDouble(),
      });
      _addNodeToBatch(batch, id, null, nttDetails, lat: (item['latitude'] as num).toDouble(), lon: (item['longitude'] as num).toDouble(), height: 0.0);
    }

    // 4. Load and parse cable landing stations data from assets
    final landingFile = File('assets/cable_landing_stations_japan.json');
    String landingJsonString;
    if (await landingFile.exists()) {
      landingJsonString = await landingFile.readAsString();
    } else {
      landingJsonString = await rootBundle.loadString('assets/cable_landing_stations_japan.json');
    }
    final landingJson = jsonDecode(landingJsonString) as List;

    final landingNodes = <Map<String, dynamic>>[];
    for (int i = 0; i < landingJson.length; i++) {
      final item = landingJson[i];
      final id = 'cable_landing_$i';
      landingNodes.add({
        'id': id,
        'lat': (item['latitude'] as num).toDouble(),
        'lon': (item['longitude'] as num).toDouble(),
      });
      _addNodeToBatch(batch, id, null, landingDetails, lat: (item['latitude'] as num).toDouble(), lon: (item['longitude'] as num).toDouble(), height: 0.0);
    }

    // 5. Interconnect stations, exchanges, and orbits with interface links
    final Set<String> addedLinks = {};
    int linkIdCounter = 0;

    void addLink(String from, String to) {
      final key1 = '${from}_$to';
      final key2 = '${to}_$from';
      if (!addedLinks.contains(key1) && !addedLinks.contains(key2)) {
        addedLinks.add(key1);
        addedLinks.add(key2);
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
        distances.add({
          'id': target['id'],
          'dist': distSq(
            current['lat'] as double,
            current['lon'] as double,
            target['lat'] as double,
            target['lon'] as double,
          ),
        });
      }
      distances.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));
      for (int k = 0; k < 2 && k < distances.length; k++) {
        addLink(current['id'] as String, distances[k]['id'] as String);
      }
      
      final space1 = spaceNodes[(i * 2) % 100];
      final space2 = spaceNodes[(i * 2 + 1) % 100];
      addLink(current['id'] as String, space1);
      addLink(current['id'] as String, space2);
    }

    for (int i = 0; i < landingNodes.length; i++) {
      final current = landingNodes[i];
      final distances = <Map<String, dynamic>>[];
      for (int j = 0; j < nttNodes.length; j++) {
        final target = nttNodes[j];
        distances.add({
          'id': target['id'],
          'dist': distSq(
            current['lat'] as double,
            current['lon'] as double,
            target['lat'] as double,
            target['lon'] as double,
          ),
        });
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

      batch2.insert('type_relations', {
        'parent_type_name': rackId,
        'relation_name': 'contains',
        'child_type_name': 'RackChassis',
        'child_label': 'Rack Chassis',
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

  /// Helper helper to insert a complete node configuration (type_definition, relation, properties, and instances).
  void _addNodeToBatch(
    Batch batch,
    String node,
    String? parent,
    List<String> details, {
    required double lat,
    required double lon,
    required double height,
  }) {
    batch.insert('type_definitions', {
      'type_name': node,
      'display_name': node.replaceAll('_', ' '),
      'icon_name': 'insert_drive_file',
    });

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

    // Geo-location attribute definitions for each node type
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
      'location': {
        'ellipsoid': {
          'latitude': lat,
          'longitude': lon,
          'height': height,
        }
      },
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
    batch.insert('properties', {
      'node_id': node,
      'parent_node_id': parent,
      'data_json': jsonEncode(propertiesMap),
    });

    for (final d in details) {
      for (int k = 1; k <= 5; k++) {
        final instId = 'inst_${node}_${d}_$k';
        final instanceMap = {
          for (int j = 1; j <= 50; j++) 'field_$j': 'val_inst_${node}_${d}_${k}_field_$j'
        };
        batch.insert('instances', {
          'id': instId,
          'parent_node_id': node,
          'type_name': d,
          'data_json': jsonEncode(instanceMap),
        });
      }
    }
  }
}
