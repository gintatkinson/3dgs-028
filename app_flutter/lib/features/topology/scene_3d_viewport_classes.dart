// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:app_flutter/domain/cesium_3d/cesium_engine.dart';
import 'package:app_flutter/domain/cesium_3d/globe_tile_renderer.dart';
import 'package:app_flutter/domain/cesium_3d/projected_point.dart';
import 'package:app_flutter/domain/cesium_3d/tile_fetcher.dart';
import 'package:app_flutter/domain/cesium_3d/camera_controller.dart';
import 'package:app_flutter/domain/cesium_3d/virtual_camera.dart';
import 'package:app_flutter/features/topology/topology_map.dart';
import 'package:app_flutter/features/tree/view_models/tree_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

extension VirtualCameraNormalization on VirtualCamera {
  /// Ensures the camera altitude is normalized to absolute ECEF coordinates 
  /// (relative to the Earth's center rather than the surface).
  VirtualCamera toAbsoluteWgs84() {
    if (altitude >= Ellipsoid.wgs84EquatorialRadius) {
      return this;
    }
    return VirtualCamera.raw(
      latitude: latitude,
      longitude: longitude,
      altitude: Ellipsoid.wgs84EquatorialRadius + altitude,
      heading: heading,
      pitch: pitch,
      roll: roll,
    );
  }
}

class ElevationProvider {
  final bool isElevationActive;
  final double verticalExaggeration;

  const ElevationProvider({
    required this.isElevationActive, 
    this.verticalExaggeration = 1.0,
  });

  double getElevation(double latDeg, double lngDeg) {
    if (!isElevationActive) return 0.0;
    
    double elev = 0.0;
    final double dLat = latDeg - 35.3606;
    final double dLng = lngDeg - 138.7274;
    final double distSq = dLat * dLat + dLng * dLng;
    final double fujiDist = math.sqrt(distSq);
    
    // Mount Fuji geographic simulation
    if (fujiDist < 0.25) {
      elev += 3776.0 * math.exp(-fujiDist * fujiDist / (0.04 * 0.04));
    }
    
    // Procedural terrain noise
    if (latDeg > 34.5 && latDeg < 37.5 && lngDeg > 136.0 && lngDeg < 140.0) {
      final double rangeNoise = math.sin(latDeg * 12.0) * math.cos(lngDeg * 12.0) * 1200.0 +
                               math.sin(latDeg * 25.0) * math.sin(lngDeg * 25.0) * 400.0;
      elev += math.max(0.0, rangeNoise);
    }
    
    return elev * verticalExaggeration;
  }
}

class CoordinateTransformer {
  final VirtualCamera absoluteCamera;
  final Size viewportSize;
  final Offset screenCenter;
  final double rotationAngle;
  final double tilt;

  // Cached math properties for the camera to save CPU cycles
  late final double _cRad;
  late final double _cx, _cy, _cz;
  late final double _ux, _uy, _uz;
  late final double _ex, _ey, _ez;
  late final double _nx, _ny, _nz;
  late final double _d2;
  late final double _r2;

  CoordinateTransformer({
    required VirtualCamera camera,
    required this.viewportSize,
    required this.screenCenter,
    required this.rotationAngle,
    required this.tilt,
  }) : absoluteCamera = camera.toAbsoluteWgs84() {
    _precomputeCameraBasis();
  }

  void _precomputeCameraBasis() {
    final double radLng = -rotationAngle;
    final double radLat = -tilt;

    _cRad = absoluteCamera.altitude;
    _r2 = Ellipsoid.wgs84EquatorialRadius * Ellipsoid.wgs84EquatorialRadius;
    _d2 = _cRad * _cRad;

    // Camera position in ECEF
    _cx = _cRad * math.cos(radLat) * math.cos(radLng);
    _cy = _cRad * math.cos(radLat) * math.sin(radLng);
    _cz = _cRad * math.sin(radLat);

    // Camera local ENU basis
    _ux = math.cos(radLat) * math.cos(radLng);
    _uy = math.cos(radLat) * math.sin(radLng);
    _uz = math.sin(radLat);

    _ex = -math.sin(radLng);
    _ey = math.cos(radLng);
    _ez = 0.0;

    _nx = -math.sin(radLat) * math.cos(radLng);
    _ny = -math.sin(radLat) * math.sin(radLng);
    _nz = math.cos(radLat);
  }

  /// Projects a 3D geocoordinate into a 2D screen offset.
  ProjectedPoint projectWgs84ToScreen({
    required double latRad,
    required double lngRad,
    required double heightMeters,
    bool clampToHorizon = true,
  }) {
    final double R = Ellipsoid.wgs84EquatorialRadius;
    final double rad = R + heightMeters;

    double px = rad * math.cos(latRad) * math.cos(lngRad);
    double py = rad * math.cos(latRad) * math.sin(lngRad);
    double pz = rad * math.sin(latRad);

    bool isCulled = _checkCulling(px, py, pz, heightMeters, latRad, lngRad, R);

    if (isCulled && clampToHorizon) {
      final double h2 = rad * rad;
      if (_d2 > h2) {
        final double r2OverD2 = h2 / _d2;
        final double parX = r2OverD2 * _cx;
        final double parY = r2OverD2 * _cy;
        final double parZ = r2OverD2 * _cz;

        final double dotPC = px * _cx + py * _cy + pz * _cz;
        final double dotOverD2 = dotPC / _d2;
        final double perpX = px - dotOverD2 * _cx;
        final double perpY = py - dotOverD2 * _cy;
        final double perpZ = pz - dotOverD2 * _cz;

        final double perpLen = math.sqrt(perpX * perpX + perpY * perpY + perpZ * perpZ);
        if (perpLen > 0.0) {
          final double rHorizon = rad * math.sqrt(1.0 - h2 / _d2);
          final double scale = rHorizon / perpLen;
          px = parX + perpX * scale;
          py = parY + perpY * scale;
          pz = parZ + perpZ * scale;
        }
      }
    }

    // Relative vector from camera to point
    final double rx = px - _cx;
    final double ry = py - _cy;
    final double rz = pz - _cz;

    // Project onto ENU basis
    final double xEnu = rx * _ex + ry * _ey + rz * _ez;
    final double yEnu = rx * _nx + ry * _ny + rz * _nz;
    final double zEnu = rx * _ux + ry * _uy + rz * _uz;

    // Apply camera pitch and heading
    final double hRad = absoluteCamera.heading * math.pi / 180.0;
    final double alpha = (absoluteCamera.pitch + 90.0) * math.pi / 180.0;

    final double cosH = math.cos(hRad);
    final double sinH = math.sin(hRad);
    final double cosA = math.cos(alpha);
    final double sinA = math.sin(alpha);

    final double x1 = xEnu * cosH - yEnu * sinH;
    final double y1 = xEnu * sinH + yEnu * cosH;
    
    final double xCam = x1;
    final double yCam = y1 * cosA + zEnu * sinA;
    final double zCam = -y1 * sinA + zEnu * cosA;

    final double depth = -zCam;
    final double f = viewportSize.shortestSide * 1.2;
    final double absDepth = depth.abs();
    final double safeDepth = absDepth <= 1.0 ? 1.0 : absDepth;
    final double pScale = f / safeDepth;

    final double rxPixel = xCam * pScale;
    final double ryPixel = yCam * pScale;

    final double depthVal;
    if (depth <= 0.0) {
      depthVal = -100.0;
    } else if (isCulled) {
      depthVal = clampToHorizon ? -1.0 : -2.0;
    } else {
      depthVal = depth;
    }

    return ProjectedPoint(
      Offset(screenCenter.dx + rxPixel, screenCenter.dy - ryPixel),
      depthVal,
    );
  }

  bool _checkCulling(double px, double py, double pz, double height, double lat, double lng, double R) {
    bool isCulled = false;
    final double cullHeight = math.max(R + height, R);
    final double pxCull = cullHeight * math.cos(lat) * math.cos(lng);
    final double pyCull = cullHeight * math.cos(lat) * math.sin(lng);
    final double pzCull = cullHeight * math.sin(lat);

    final double rx = pxCull - _cx;
    final double ry = pyCull - _cy;
    final double rz = pzCull - _cz;
    final double dCP2 = rx * rx + ry * ry + rz * rz;
    final double dotPC = pxCull * _cx + pyCull * _cy + pzCull * _cz;

    if (dotPC < _r2) {
      final double tMin = (_d2 - dotPC) / dCP2;
      if (tMin >= 0.0 && tMin <= 1.0) {
        final double minDistanceSq = _d2 - (_d2 - dotPC) * (_d2 - dotPC) / dCP2;
        if (minDistanceSq < _r2) {
          isCulled = true;
        }
      }
    }
    if (height < 0.0 && _cRad > R) {
      isCulled = true;
    }
    return isCulled;
  }

  /// Calculates the Earth's visual horizon edge.
  Path generateHorizonPath({int segments = 64}) {
    final double R = Ellipsoid.wgs84EquatorialRadius;
    final double r2OverD2 = (R * R) / _d2;
    final double cxH = r2OverD2 * _cx;
    final double cyH = r2OverD2 * _cy;
    final double czH = r2OverD2 * _cz;

    final double rHorizon = R * math.sqrt(1.0 - (R * R) / _d2);

    final Path path = Path();
    for (int i = 0; i <= segments; i++) {
      final double theta = 2.0 * math.pi * i / segments;
      final double cosT = math.cos(theta);
      final double sinT = math.sin(theta);

      final double px = cxH + rHorizon * (cosT * _ex + sinT * _nx);
      final double py = cyH + rHorizon * (cosT * _ey + sinT * _ny);
      final double pz = czH + rHorizon * (cosT * _ez + sinT * _nz);

      final double rx = px - _cx;
      final double ry = py - _cy;
      final double rz = pz - _cz;

      final double xEnu = rx * _ex + ry * _ey + rz * _ez;
      final double yEnu = rx * _nx + ry * _ny + rz * _nz;
      final double zEnu = rx * _ux + ry * _uy + rz * _uz;

      final double hRad = absoluteCamera.heading * math.pi / 180.0;
      final double alpha = (absoluteCamera.pitch + 90.0) * math.pi / 180.0;

      final double cosH = math.cos(hRad);
      final double sinH = math.sin(hRad);
      final double cosA = math.cos(alpha);
      final double sinA = math.sin(alpha);

      final double x1 = xEnu * cosH - yEnu * sinH;
      final double y1 = xEnu * sinH + yEnu * cosH;
      final double z1 = zEnu;

      final double xCam = x1;
      final double yCam = y1 * cosA + z1 * sinA;
      final double zCam = -y1 * sinA + z1 * cosA;

      final double depth = -zCam;
      final double f = viewportSize.shortestSide * 1.2;
      final double absDepth = depth.abs();
      final double safeDepth = absDepth <= 1.0 ? 1.0 : absDepth;
      final double pScale = f / safeDepth;

      final double rxPixel = xCam * pScale;
      final double ryPixel = yCam * pScale;

      final Offset pt = Offset(screenCenter.dx + rxPixel, screenCenter.dy - ryPixel);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path;
  }
}

typedef ElevationCacheKey = (String id, double latDeg, double lngDeg, String astronomicalBody, bool elevationActive);

class SceneViewState extends ChangeNotifier {
  final Map<String, Network3DScene> nodeModels = {};
  final Map<String, ProjectedPoint> projectedNodes = {};
  final List<Offset> groundGlowPoints = [];
  final List<Offset> groundPoints = [];
  final List<Offset> linkGlowPoints = [];
  final List<Offset> linkPoints = [];
  final List<Offset> packetPoints = [];
  final List<Rect> drawnLabelRects = [];
  final Map<ElevationCacheKey, double> nodeElevationCache = {};
  final Map<String, ElevationCacheKey> cacheKeyCache = {};
  final Map<String, double> debugCapturedHeights = {};

  Path? horizonPath;
  ProjectedPoint? earthCenterProj;
  double projectedRadius = 0.0;
  Offset projectedCenter = Offset.zero;

  late VirtualCamera camera;
  GlobeTileRenderer? tileRenderer;
  bool isFlying = false;

  late String activeStyle;
  late String astronomicalBody;
  late bool elevationActive;
  late bool showDevices;
  late bool showLinks;
  late bool showLabels;
  late bool showDropLines;
  late double verticalExaggeration;
  TopologyData? topologyData;
  late ElevationProvider elevationProvider;
  late CoordinateTransformer transformer;

  final Map<String, Offset> finalLabelPositions = {};
  final Map<TextPainterKey, TextPainter> textPainterCache = {};

  VirtualCamera? _lastRecalculatedCamera;
  TopologyData? _lastRecalculatedTopology;
  bool _lastRecalculatedIsFlying = false;

  void recalculate(
    VirtualCamera camera, 
    Size size, 
    TopologyData? topoData,
    String activeStyle,
    String astronomicalBody,
    bool elevationActive,
    bool showDevices,
    bool showLinks,
    bool showLabels,
    bool showDropLines,
    double verticalExaggeration,
    double userRotationX,
    double userTilt,
    GlobeTileRenderer? tileRenderer,
    bool isFlying,
  ) {
    final VirtualCamera absoluteCamera = camera.toAbsoluteWgs84();
    final bool cameraUnchanged = _lastRecalculatedCamera != null &&
        _lastRecalculatedCamera!.isSpatiallyEquivalentTo(absoluteCamera);
    final bool topologyUnchanged = _lastRecalculatedTopology != null &&
        identical(_lastRecalculatedTopology, topoData);
    final bool flyingUnchanged = _lastRecalculatedIsFlying == isFlying;
    if (cameraUnchanged && topologyUnchanged && flyingUnchanged) {
      return;
    }
    _lastRecalculatedCamera = absoluteCamera;
    _lastRecalculatedTopology = topoData;
    _lastRecalculatedIsFlying = isFlying;

    this.camera = absoluteCamera;
    this.tileRenderer = tileRenderer;
    this.isFlying = isFlying;
    this.activeStyle = activeStyle;
    this.astronomicalBody = astronomicalBody;
    this.elevationActive = elevationActive;
    this.showDevices = showDevices;
    this.showLinks = showLinks;
    this.showLabels = showLabels;
    this.showDropLines = showDropLines;
    this.verticalExaggeration = verticalExaggeration;
    this.topologyData = topoData;

    elevationProvider = ElevationProvider(
      isElevationActive: elevationActive,
      verticalExaggeration: verticalExaggeration,
    );

    projectedNodes.clear();
    groundGlowPoints.clear();
    groundPoints.clear();
    linkGlowPoints.clear();
    linkPoints.clear();
    packetPoints.clear();
    drawnLabelRects.clear();
    debugCapturedHeights.clear();
    finalLabelPositions.clear();

    final Offset center = Offset(size.width * 0.45, size.height * 0.5);
    final double baseRotation = -(camera.longitude * math.pi / 180.0);
    final double baseTilt = -(camera.latitude * math.pi / 180.0);
    final double rotationAngle = baseRotation + userRotationX;
    final double tilt = baseTilt + userTilt;

    transformer = CoordinateTransformer(
      camera: camera,
      viewportSize: size,
      screenCenter: center,
      rotationAngle: rotationAngle,
      tilt: tilt,
    );

    horizonPath = transformer.generateHorizonPath();
    earthCenterProj = transformer.projectWgs84ToScreen(latRad: 0.0, lngRad: 0.0, heightMeters: -Ellipsoid.wgs84EquatorialRadius, clampToHorizon: false);
    projectedCenter = earthCenterProj!.offset;

    final double cRad = transformer.absoluteCamera.altitude;
    final double f = size.shortestSide * 1.2;
    final double radDiff = cRad * cRad - Ellipsoid.wgs84EquatorialRadius * Ellipsoid.wgs84EquatorialRadius;
    projectedRadius = Ellipsoid.wgs84EquatorialRadius * f / math.sqrt(radDiff <= 0.0 ? 1.0 : radDiff);

    List<TopologyNode> nodes = topoData?.nodes ?? [];
    List<TopologyLink> links = topoData?.links ?? [];

    final Set<String> currentIds = nodes.map((n) => n.id).toSet();
    nodeModels.removeWhere((id, _) => !currentIds.contains(id));
    nodeElevationCache.removeWhere((key, _) => !currentIds.contains(key.$1));

    for (final node in nodes) {
      final String id = node.id;
      final String modelPath = (node.rawProperties['model_path'] ?? node.rawProperties['model'] ?? '').toString();
      
      if (modelPath.isNotEmpty && !nodeModels.containsKey(id)) {
        final scene = Network3DScene();
        nodeModels[id] = scene;
        scene.loadModel(modelPath).then((_) {
          notifyListeners();
        });
      }

      final double latDeg = node.position.dim1;
      final double lngDeg = node.position.dim0;
      final double alt = node.position.dim2;
      
      final double latRad = latDeg * math.pi / 180.0;
      final double lngRad = lngDeg * math.pi / 180.0;
      
      final String heightRef = (node.rawProperties['heightReference'] ?? node.rawProperties['height_reference'] ?? '').toString().toUpperCase();
      final String type;
      if (heightRef == 'RELATIVE_TO_GROUND' || heightRef == 'CLAMP_TO_GROUND') {
        type = 'ground';
      } else if (heightRef == 'ABSOLUTE') {
        type = 'space';
      } else {
        type = (alt < 50000.0) ? 'ground' : 'space';
      }

      final double orbitHeight = alt;
      final double currentLngRad = lngRad; // simplified

      double finalHeight = orbitHeight;
      if (type == 'ground' || type == 'underwater') {
        if (elevationActive) {
          final ElevationCacheKey cacheKey = (id, latDeg, lngDeg, astronomicalBody, elevationActive);
          final double terrainElev = nodeElevationCache.putIfAbsent(cacheKey, () => elevationProvider.getElevation(latDeg, lngDeg));
          final double baseElev = terrainElev / (verticalExaggeration == 0 ? 1 : verticalExaggeration);
          final double relativeAlt;
          if (heightRef == 'CLAMP_TO_GROUND') {
            relativeAlt = 0.0;
          } else if (heightRef == 'RELATIVE_TO_GROUND') {
            relativeAlt = alt;
          } else {
            relativeAlt = alt - baseElev;
          }
          finalHeight = terrainElev + relativeAlt;
        } else {
          finalHeight = alt;
        }
      }

      debugCapturedHeights[id] = finalHeight;

      final proj = transformer.projectWgs84ToScreen(latRad: latRad, lngRad: currentLngRad, heightMeters: finalHeight);
      
      if (proj.z >= 0) {
        projectedNodes[id] = proj;
        if (type == 'ground') {
          groundGlowPoints.add(proj.offset);
          groundPoints.add(proj.offset);
        }
        
        if (showLabels && showDevices) {
          final String labelText = node.label.isNotEmpty ? node.label : id;
          final Color textColor = type == 'space' ? const Color(0xFFFFB300) : const Color(0xFF00E5FF);
          final key = TextPainterKey(labelText, textColor);
          final textPainter = textPainterCache.putIfAbsent(key, () {
            return TextPainter(
              text: TextSpan(
                text: labelText,
                style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
          });

          Offset textPos = proj.offset + const Offset(8, -4);
          Rect outerRect = Rect.fromLTWH(textPos.dx - 6, textPos.dy - 3, textPainter.width + 12, textPainter.height + 6);

          bool overlaps = true;
          int offsetLoop = 0;
          while (overlaps && offsetLoop < 5) {
            overlaps = false;
            final double area1 = outerRect.width * outerRect.height;
            for (final Rect existing in drawnLabelRects) {
              final double left = math.max(outerRect.left, existing.left);
              final double right = math.min(outerRect.right, existing.right);
              final double top = math.max(outerRect.top, existing.top);
              final double bottom = math.min(outerRect.bottom, existing.bottom);
              if (right > left && bottom > top) {
                final double intersectArea = (right - left) * (bottom - top);
                if (intersectArea / area1 > 0.10 || intersectArea / (existing.width * existing.height) > 0.10) {
                  overlaps = true;
                  break;
                }
              }
            }
            if (overlaps) {
              textPos += const Offset(0, 16);
              outerRect = Rect.fromLTWH(textPos.dx - 6, textPos.dy - 3, textPainter.width + 12, textPainter.height + 6);
              offsetLoop++;
            }
          }
          if (!overlaps) {
            drawnLabelRects.add(outerRect);
            finalLabelPositions[id] = textPos;
          }
        }
      }
    }

    if (showLinks && showDevices) {
      for (int i = 0; i < links.length; i++) {
        final link = links[i];
        final ProjectedPoint? p1 = projectedNodes[link.source];
        final ProjectedPoint? p2 = projectedNodes[link.target];
        if (p1 != null && p2 != null) {
          linkGlowPoints.add(p1.offset);
          linkGlowPoints.add(p2.offset);
          linkPoints.add(p1.offset);
          linkPoints.add(p2.offset);
          final double packetT = (i * 0.25) % 1.0;
          packetPoints.add(Offset.lerp(p1.offset, p2.offset, packetT)!);
        }
      }
    }

    notifyListeners();
  }
}

class TextPainterKey {
  final String text;
  final Color color;
  TextPainterKey(this.text, this.color);
  @override bool operator ==(Object other) => identical(this, other) || other is TextPainterKey && text == other.text && color == other.color;
  @override int get hashCode => Object.hash(text, color);
}

enum ModelRenderState { unloaded, loading, loaded, error }

class Network3DScene {
  Uint8List? gltfData;
  bool isTranslucent = false;
  ModelRenderState state = ModelRenderState.unloaded;

  /// Loads the glTF model data from the given path.
  Future<bool> loadModel(String modelPath) async {
    if (modelPath.isEmpty) {
      state = ModelRenderState.error;
      return false;
    }
    
    state = ModelRenderState.loading;
    try {
      final ByteData data = await rootBundle.load(modelPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      if (bytes.isEmpty) {
        state = ModelRenderState.error;
        return false;
      }
      
      gltfData = bytes;
      state = ModelRenderState.loaded;
      return true;
    } catch (e) {
      state = ModelRenderState.error;
      return false;
    }
  }

  /// Applies PBR materials and sets transcluent flags.
  bool applyPbrMaterials() {
    if (state == ModelRenderState.loaded && gltfData != null) {
      isTranslucent = true;
      return true;
    }
    return false;
  }
}
