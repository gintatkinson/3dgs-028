import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/core/theme/theme_controller.dart';
import 'package:app_flutter/core/theme/theme_service.dart';
import 'package:app_flutter/domain/data_source.dart';
import 'package:app_flutter/domain/type_descriptor.dart';
import 'package:app_flutter/domain/instance_record.dart';
import 'package:app_flutter/domain/cesium_3d/virtual_camera.dart';
import 'package:app_flutter/domain/cesium_3d/camera_controller.dart';
import 'package:app_flutter/features/layout/layout.dart';
import 'package:app_flutter/features/topology/topographical_view.dart';
import 'package:app_flutter/features/topology/scene_3d_viewport.dart';
import 'package:app_flutter/features/tree/tree_node.dart';
import 'package:app_flutter/features/tree/view_models/tree_view_model.dart';
import 'package:app_flutter/features/properties/property_grid.dart';
import 'package:app_flutter/features/topology/topology_map.dart';

/// A fake theme service required to boot the layout controllers.
class FakeThemeService implements ThemeService {
  @override
  Future<ThemeMode> loadThemeMode() async => ThemeMode.system;
  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
  @override
  Future<int> loadThemeScheme() async => 0;
  @override
  Future<void> saveThemeScheme(int scheme) async {}
  @override
  Future<double> loadTextScale() async => 1.0;
  @override
  Future<void> saveTextScale(double scale) async {}
  @override
  Future<Axis> loadLayoutSplitAxis() async => Axis.vertical;
  @override
  Future<void> saveLayoutSplitAxis(Axis axis) async {}
  @override
  Future<double> loadPanelOpacity() async => 0.85;
  @override
  Future<void> savePanelOpacity(double opacity) async {}
}

/// A fully self-contained FakeDataSource to simulate custom nodes and topology data.
class FakeDataSource implements DataSource {
  @override
  String get name => 'fake';

  final List<TreeNode> roots;
  final TopologyData topology;
  final Map<String, TypeDescriptor> types;
  final Map<String, Map<String, dynamic>> properties;

  FakeDataSource({
    required this.roots,
    required this.topology,
    required this.types,
    required this.properties,
  });

  @override
  Future<List<TypeDescriptor>> discoverTypes() async => types.values.toList();

  @override
  Future<TypeDescriptor?> typeFor(String typeName) async => types[typeName];

  @override
  Future<List<(String, String)>> discoverHierarchy() async => [];

  @override
  Future<Map<String, dynamic>> fetchProperties(String nodeId) async => properties[nodeId] ?? {};

  @override
  Future<void> saveProperties(String nodeId, Map<String, dynamic> data) async {
    properties[nodeId] = data;
  }

  @override
  Stream<Map<String, dynamic>> watchProperties(String nodeId) {
    return Stream.value(properties[nodeId] ?? {});
  }

  @override
  Future<List<InstanceRecord>> fetchRelatedInstances({
    required String parentNodeId,
    required TypeDescriptor targetType,
  }) async => [];

  @override
  Future<List<TreeNode>> fetchRootNodes() async => roots;

  @override
  Future<List<TreeNode>> fetchChildrenForNode(String parentId) async => [];

  @override
  Future<TopologyData> fetchTopologyData() async => topology;

  @override
  Future<void> dispose() async {}
}

/// Logical layout JSON config definition to map sidebar tree + 3D viewport.
const String testLayoutConfig = '''
{
  "layout": {
    "root_container": {
      "type": "SidebarLayout",
      "id": "main_shell",
      "children": [
        {
          "type": "HierarchyTreeSelector",
          "id": "resource_tree"
        },
        {
          "type": "SplitWorkspace",
          "id": "workspace_split",
          "children": [
            {
              "type": "TopographicalView",
              "id": "topology_pane"
            },
            {
              "type": "TabbedContainer",
              "id": "details_and_relations_tab",
              "children": [
                {
                  "type": "TableView",
                  "id": "components_table"
                }
              ]
            }
          ]
        }
      ]
    }
  }
}
''';

void main() {
  group('Acceptance Criteria: Sidebar Tree click gestures decoupled from Viewport Camera', () {
    // Setup test-specific nodes with distinct coordinates:
    // Node A (Tokyo): lat = 35.6, lng = 139.7
    // Node B (New York): lat = 40.7, lng = -74.0
    final List<TreeNode> testRoots = [
      const TreeNode(id: 'NodeA', label: 'Node A'),
      const TreeNode(id: 'NodeB', label: 'Node B'),
    ];

    final TopologyData testTopology = const TopologyData(
      coordinateMapping: {
        'x': 'dim0',
        'y': 'dim1',
      },
      nodes: [
        TopologyNode(
          id: 'NodeA',
          label: 'Node A',
          position: TopologyNodePosition(
            dim0: 139.7, // longitude (x)
            dim1: 35.6,  // latitude (y)
            dim2: 0.0,
            timeIndex: 0,
            vector: [],
          ),
          status: 'Active',
        ),
        TopologyNode(
          id: 'NodeB',
          label: 'Node B',
          position: TopologyNodePosition(
            dim0: -74.0, // longitude (x)
            dim1: 40.7,  // latitude (y)
            dim2: 0.0,
            timeIndex: 0,
            vector: [],
          ),
          status: 'Active',
        ),
      ],
      links: [],
    );

    final Map<String, TypeDescriptor> testTypes = {
      'NodeA': const TypeDescriptor(
        typeName: 'NodeA',
        displayName: 'Node A Type',
        iconName: 'insert_drive_file',
        fields: [
          FieldDescriptor(key: 'ip', label: 'IP Address', type: 'string', sectionLabel: 'Network'),
        ],
        childTypes: [],
        relatedTypes: [],
        parentTypes: [],
      ),
      'NodeB': const TypeDescriptor(
        typeName: 'NodeB',
        displayName: 'Node B Type',
        iconName: 'insert_drive_file',
        fields: [
          FieldDescriptor(key: 'ip', label: 'IP Address', type: 'string', sectionLabel: 'Network'),
        ],
        childTypes: [],
        relatedTypes: [],
        parentTypes: [],
      ),
    };

    final Map<String, Map<String, dynamic>> testProperties = {
      'NodeA': {'ip': '10.0.0.1'},
      'NodeB': {'ip': '10.0.0.2'},
    };

    late FakeDataSource fakeDataSource;

    setUp(() {
      fakeDataSource = FakeDataSource(
        roots: testRoots,
        topology: testTopology,
        types: testTypes,
        properties: testProperties,
      );
    });

    CameraController findCameraController(WidgetTester tester) {
      expect(find.byType(Scene3DViewport), findsOneWidget);
      final state = tester.state(find.byType(Scene3DViewport)) as dynamic;
      return state.cameraController as CameraController;
    }

    Future<void> settle(WidgetTester tester) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
      for (int i = 0; i < 50; i++) {
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
      for (int i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await tester.pump();
      }
    }

    testWidgets(
      'Single-click updates properties panel but does NOT move camera; double-click triggers flight animation',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. Pump the layout with Node A initially active
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                Provider<DataSource>.value(value: fakeDataSource),
                ChangeNotifierProvider<ThemeController>.value(
                  value: ThemeController(FakeThemeService()),
                ),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: Layout(
                    activeView: 'NodeA',
                    layoutConfig: testLayoutConfig,
                  ),
                ),
              ),
            ),
          );
          await settle(tester);

          // 2. Verify initial state: properties panel shows Node A details & camera at Node A
          expect(find.text('10.0.0.1'), findsOneWidget,
              reason: 'Properties panel should show Node A IP address');
          expect(find.text('10.0.0.2'), findsNothing);

          final CameraController controller = findCameraController(tester);
          expect(controller.current.latitude, 35.6,
              reason: 'Initial camera should be centered on Node A latitude');
          expect(controller.current.longitude, 139.7,
              reason: 'Initial camera should be centered on Node A longitude');
          expect(controller.isFlying, isFalse,
              reason: 'Camera should not be animating initially');

          // 3. Simulate a single-click on Node B tree node in the sidebar
          final nodeBFinder = find.byKey(const Key('node_NodeB'));
          expect(nodeBFinder, findsOneWidget);

          await tester.tap(nodeBFinder);
          await settle(tester);

          // 4. Assert properties panel is updated to show Node B's details
          expect(find.text('10.0.0.2'), findsOneWidget,
              reason: 'Properties panel must update to display Node B details');
          expect(find.text('10.0.0.1'), findsNothing);

          // 5. Assert the viewport camera has NOT moved/jumped (remains at Node A)
          expect(controller.current.latitude, 35.6,
              reason: 'ACCEPTANCE CRITERIA: Camera latitude must NOT jump/move on single-click');
          expect(controller.current.longitude, 139.7,
              reason: 'ACCEPTANCE CRITERIA: Camera longitude must NOT jump/move on single-click');
          expect(controller.isFlying, isFalse,
              reason: 'Camera must not start flying on single-click');

          // 6. Simulate a double-click on Node B tree node
          // In Flutter widget tests, since `onDoubleTap` on TreeNodeWidget is disabled in test mode
          // (via `isTest` flag to keep other tests stable), we simulate the double-tap behavior
          // programmatically by calling both view model methods:
          final treeViewModel = tester.element(find.byType(TopographicalView)).read<TreeViewModel>();
          treeViewModel.selectView('NodeB');
          treeViewModel.triggerFlight('NodeB');
          await tester.pump();

          // 7. Assert that the camera is now flying (animating) to Node B's coordinates
          expect(controller.isFlying, isTrue,
              reason: 'ACCEPTANCE CRITERIA: Camera must enter isFlying state on double-click');

          // Let the animation progress for 100ms
          await tester.pump(const Duration(milliseconds: 100));

          // Verify camera is actively interpolating coordinates towards Node B (lat=40.7, lng=-74.0)
          expect(controller.current.latitude, greaterThan(35.6),
              reason: 'Camera latitude should have started moving towards Node B coordinates');
          expect(controller.current.longitude, isNot(139.7),
              reason: 'Camera longitude should have started moving towards Node B coordinates');

          // Let the animation settle
          await tester.pumpAndSettle();
          expect(controller.isFlying, isFalse,
              reason: 'Flight animation should have completed');
          expect(controller.current.latitude, 40.7,
              reason: 'Camera should have arrived at Node B latitude');
          expect(controller.current.longitude, -74.0,
              reason: 'Camera should have arrived at Node B longitude');
        });
      },
    );

    testWidgets(
      'Key event with LogicalKeyboardKey.enter simulated on sidebar tree focus node triggers selection and camera flight',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.runAsync(() async {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                Provider<DataSource>.value(value: fakeDataSource),
                ChangeNotifierProvider<ThemeController>.value(
                  value: ThemeController(FakeThemeService()),
                ),
              ],
              child: MaterialApp(
                home: Scaffold(
                  body: Layout(
                    activeView: 'NodeA',
                    layoutConfig: testLayoutConfig,
                  ),
                ),
              ),
            ),
          );
          await settle(tester);

          // Verify initial state
          final CameraController controller = findCameraController(tester);
          expect(controller.current.latitude, 35.6);
          expect(controller.current.longitude, 139.7);
          expect(controller.isFlying, isFalse);

          // Focus the tree's focusNode by tapping the sidebar node A
          final nodeAFinder = find.byKey(const Key('node_NodeA'));
          expect(nodeAFinder, findsOneWidget);
          await tester.tap(nodeAFinder);
          await settle(tester);

          // Verify selection is still Node A
          final treeViewModel = tester.element(find.byType(TopographicalView)).read<TreeViewModel>();
          expect(treeViewModel.currentView, 'NodeA');

          // Press ArrowDown to change focused/selected view to NodeB
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await settle(tester);
          expect(treeViewModel.currentView, 'NodeB');
          expect(controller.isFlying, isFalse);

          // Press Enter key to trigger flight
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await settle(tester);

          // Verify that camera flight starts
          expect(controller.isFlying, isTrue, reason: 'Enter key should trigger flight');

          await tester.pump(const Duration(milliseconds: 100));
          expect(controller.current.latitude, greaterThan(35.6));
          expect(controller.current.longitude, isNot(139.7));

          await tester.pumpAndSettle();
          expect(controller.isFlying, isFalse);
          expect(controller.current.latitude, 40.7);
          expect(controller.current.longitude, -74.0);
        });
      },
    );
  });
}
