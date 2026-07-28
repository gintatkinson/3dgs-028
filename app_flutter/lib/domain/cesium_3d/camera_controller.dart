import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:clock/clock.dart';
import 'virtual_camera.dart';

class CameraController extends ChangeNotifier {
  VirtualCamera _camera;

  VirtualCamera? _startCamera;
  VirtualCamera? _targetCamera;
  DateTime? _animationStart;
  Duration _flightDuration = const Duration(milliseconds: 500);

  @visibleForTesting
  Duration get flightDurationForTesting => _flightDuration;

  static const double dragSensitivity = 0.15;
  static const double scrollSensitivity = 0.5;
  static const double keyboardStep = 5.0;
  static const double minAltitude = 100.0;
  static const double maxAltitude = 40000000.0;

  double Function(double lat, double lng)? elevationProvider;

  double _getTerrainHeight(double lat, double lng) {
    if (elevationProvider == null) return 0.0;
    return elevationProvider!(lat, lng);
  }

  double _clampAltitudeToTerrain(double lat, double lng, double targetAlt) {
    final double terrainH = _getTerrainHeight(lat, lng);
    final double minAlt = Ellipsoid.wgs84EquatorialRadius + terrainH + minAltitude;
    return targetAlt < minAlt ? minAlt : targetAlt;
  }

  CameraController(VirtualCamera camera) : _camera = camera.altitude < Ellipsoid.wgs84EquatorialRadius ? VirtualCamera.clamped(
    latitude: camera.latitude,
    longitude: camera.longitude,
    altitude: Ellipsoid.wgs84EquatorialRadius + camera.altitude,
    heading: camera.heading,
    pitch: camera.pitch,
    roll: camera.roll,
  ) : camera;

  VirtualCamera get current => _camera;

  bool get isFlying => _targetCamera != null;

  void updateCamera(VirtualCamera camera) {
    final absoluteCamera = camera.altitude < Ellipsoid.wgs84EquatorialRadius ? VirtualCamera.clamped(
      latitude: camera.latitude,
      longitude: camera.longitude,
      altitude: Ellipsoid.wgs84EquatorialRadius + camera.altitude,
      heading: camera.heading,
      pitch: camera.pitch,
      roll: camera.roll,
    ) : camera;
    final double targetAlt = _clampAltitudeToTerrain(absoluteCamera.latitude, absoluteCamera.longitude, absoluteCamera.altitude);
    final clampedCam = VirtualCamera.clamped(
      latitude: absoluteCamera.latitude,
      longitude: absoluteCamera.longitude,
      altitude: targetAlt,
      heading: absoluteCamera.heading,
      pitch: absoluteCamera.pitch,
      roll: absoluteCamera.roll,
    );
    if (_camera == clampedCam) return;
    _camera = clampedCam;
    _targetCamera = null;
    _startCamera = null;
    notifyListeners();
  }

  static double _normalizeRadDiff(double diff) {
    if (diff.isNaN || !diff.isFinite) return 0.0;
    double wrapped = (diff + math.pi) % (2 * math.pi);
    if (wrapped < 0.0) wrapped += 2 * math.pi;
    return wrapped - math.pi;
  }

  static double _computeAngularDistance(VirtualCamera a, VirtualCamera b) {
    final double lat1 = a.latitude * math.pi / 180.0;
    final double lat2 = b.latitude * math.pi / 180.0;
    final double lon1 = a.longitude * math.pi / 180.0;
    final double lon2 = b.longitude * math.pi / 180.0;

    final double dLat = lat2 - lat1;
    final double dLon = _normalizeRadDiff(lon2 - lon1);

    final double sinDLat2 = math.sin(dLat / 2);
    final double sinDLon2 = math.sin(dLon / 2);
    final double val = sinDLat2 * sinDLat2 + math.cos(lat1) * math.cos(lat2) * sinDLon2 * sinDLon2;
    return 2 * math.asin(math.sqrt(val.clamp(0.0, 1.0)));
  }

  void flyTo(VirtualCamera target) {
    final double angularDistance = _computeAngularDistance(_camera, target);
    final double ms = 500.0 + (angularDistance / math.pi) * 1300.0;
    _flightDuration = Duration(milliseconds: ms.round());
    _startCamera = _camera;
    _targetCamera = target;
    _animationStart = null;
  }

  bool tick() {
    if (_startCamera == null || _targetCamera == null) return true;
    _animationStart ??= clock.now();
    final elapsed = clock.now().difference(_animationStart!);
    final progress =
        (elapsed.inMilliseconds / _flightDuration.inMilliseconds).clamp(0.0, 1.0);
    final t = _easeInOutCubic(progress);
    _camera = _lerpCamera(_startCamera!, _targetCamera!, t);
    notifyListeners();
    if (progress >= 1.0) {
      _camera = _targetCamera!;
      _startCamera = null;
      _targetCamera = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  static double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;
  }

  static VirtualCamera _lerpCamera(VirtualCamera a, VirtualCamera b, double t) {
    final double distance = _computeAngularDistance(a, b);
    final double maxBoost = (distance / math.pi) * 5000000.0;
    final double baseAltitude = a.altitude + (b.altitude - a.altitude) * t;
    final double boostedAltitude = baseAltitude + math.sin(t * math.pi) * maxBoost;

    return VirtualCamera.clamped(
      latitude: a.latitude + (b.latitude - a.latitude) * t,
      longitude: _interpolateCircular(a.longitude, b.longitude, t, _wrapLngStatic),
      altitude: boostedAltitude,
      heading: _interpolateCircular(a.heading, b.heading, t, _wrapHeadingStatic),
      pitch: _interpolateCircular(a.pitch, b.pitch, t, _wrapPitchStatic),
      roll: a.roll + (b.roll - a.roll) * t,
    );
  }

  static double _interpolateCircular(double from, double to, double t, double Function(double) wrapFn) {
    double diff = to - from;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return wrapFn(from + diff * t);
  }

  static double _wrapLngStatic(double lng) {
    if (lng.isNaN || !lng.isFinite) return 0.0;
    double wrapped = (lng + 180.0) % 360.0;
    if (wrapped < 0.0) wrapped += 360.0;
    double val = wrapped - 180.0;
    if (val == -180.0) {
      return lng >= 0.0 ? 180.0 : -180.0;
    }
    return val;
  }

  static double _wrapHeadingStatic(double heading) {
    if (heading.isNaN || !heading.isFinite) return 0.0;
    double wrapped = heading % 360.0;
    if (wrapped < 0.0) wrapped += 360.0;
    return wrapped;
  }

  void pan(Offset delta, [double shortestSide = 800.0]) {
    if (shortestSide <= 0.0 || shortestSide.isNaN) {
      shortestSide = 800.0;
    }
    final double factor = (_camera.altitude - Ellipsoid.wgs84EquatorialRadius + 500000.0) * 2.8074e-5 / shortestSide;
    final double radH = _camera.heading * math.pi / 180.0;
    final double cosH = math.cos(radH);
    final double sinH = math.sin(radH);
    final double dxAligned = delta.dx * cosH + delta.dy * sinH;
    final double dyAligned = -delta.dx * sinH + delta.dy * cosH;
    final newLat = (_camera.latitude - dyAligned * factor).clamp(-90.0, 90.0);
    final newLng = _wrapLng(_camera.longitude - dxAligned * factor);
    final double targetAlt = _clampAltitudeToTerrain(newLat, newLng, _camera.altitude);
    _camera = VirtualCamera.clamped(
      latitude: newLat,
      longitude: newLng,
      altitude: targetAlt,
      heading: _camera.heading,
      pitch: _camera.pitch,
      roll: _camera.roll,
    );
    notifyListeners();
  }

  void tilt(Offset delta) {
    _camera = VirtualCamera.clamped(
      latitude: _camera.latitude, longitude: _camera.longitude,
      altitude: _camera.altitude,
      heading: _wrapHeading(_camera.heading - delta.dx * dragSensitivity),
      pitch: _wrapPitch(_camera.pitch - delta.dy * dragSensitivity),
      roll: _camera.roll,
    );
    notifyListeners();
  }

  void rotateHeading(Offset delta) {
    _camera = VirtualCamera.clamped(
      latitude: _camera.latitude, longitude: _camera.longitude,
      altitude: _camera.altitude,
      heading: _wrapHeading(_camera.heading - delta.dx * dragSensitivity),
      pitch: _camera.pitch, roll: _camera.roll,
    );
    notifyListeners();
  }

  void zoom(double scrollDelta) {
    final double terrainH = _getTerrainHeight(_camera.latitude, _camera.longitude);
    final double currentHeightAGL = _camera.altitude - (Ellipsoid.wgs84EquatorialRadius + terrainH);
    final double targetHeightAGL = currentHeightAGL + scrollDelta * scrollSensitivity;
    final double clampedHeightAGL = targetHeightAGL.clamp(minAltitude, maxAltitude);
    final double newAlt = Ellipsoid.wgs84EquatorialRadius + clampedHeightAGL + terrainH;
    _camera = VirtualCamera.clamped(
      latitude: _camera.latitude,
      longitude: _camera.longitude,
      altitude: newAlt,
      heading: _camera.heading,
      pitch: _camera.pitch,
      roll: _camera.roll,
    );
    notifyListeners();
  }

  void zoomInteractive(double scrollDelta) {
    final double clampedDelta = scrollDelta.clamp(-100.0, 100.0);
    final double factor = math.exp(clampedDelta * 0.001);
    final double terrainH = _getTerrainHeight(_camera.latitude, _camera.longitude);
    final double currentHeightAGL = _camera.altitude - (Ellipsoid.wgs84EquatorialRadius + terrainH);
    final double targetHeightAGL = currentHeightAGL * factor;
    final double clampedHeightAGL = targetHeightAGL.clamp(minAltitude, maxAltitude);
    final double newAlt = Ellipsoid.wgs84EquatorialRadius + clampedHeightAGL + terrainH;
    _camera = VirtualCamera.clamped(
      latitude: _camera.latitude,
      longitude: _camera.longitude,
      altitude: newAlt,
      heading: _camera.heading,
      pitch: _camera.pitch,
      roll: _camera.roll,
    );
    notifyListeners();
  }

  void keyboardRotate(double degrees) {
    _camera = VirtualCamera.clamped(
      latitude: _camera.latitude, longitude: _wrapLng(_camera.longitude + degrees),
      altitude: _camera.altitude, heading: _camera.heading,
      pitch: _camera.pitch, roll: _camera.roll,
    );
    notifyListeners();
  }

  void keyboardRotateHeading(double degrees) {
    _camera = VirtualCamera.clamped(
      latitude: _camera.latitude, longitude: _camera.longitude,
      altitude: _camera.altitude,
      heading: _wrapHeading(_camera.heading + degrees),
      pitch: _camera.pitch, roll: _camera.roll,
    );
    notifyListeners();
  }

  void keyboardTilt(double degrees) {
    _camera = VirtualCamera.clamped(
      latitude: _camera.latitude, longitude: _camera.longitude,
      altitude: _camera.altitude, heading: _camera.heading,
      pitch: _wrapPitch(_camera.pitch + degrees),
      roll: _camera.roll,
    );
    notifyListeners();
  }

  double _wrapLng(double lng) {
    if (lng.isNaN || !lng.isFinite) return 0.0;
    double wrapped = (lng + 180.0) % 360.0;
    if (wrapped < 0.0) wrapped += 360.0;
    double val = wrapped - 180.0;
    if (val == -180.0) {
      return lng >= 0.0 ? 180.0 : -180.0;
    }
    return val;
  }

  double _wrapHeading(double heading) => _wrapHeadingStatic(heading);

  double _wrapPitch(double pitch) => _wrapPitchStatic(pitch);

  static double _wrapPitchStatic(double pitch) {
    if (pitch.isNaN || !pitch.isFinite) return 0.0;
    double wrapped = (pitch + 180.0) % 360.0;
    if (wrapped < 0.0) wrapped += 360.0;
    double val = wrapped - 180.0;
    if (val == -180.0) {
      return pitch >= 0.0 ? 180.0 : -180.0;
    }
    return val;
  }

  @visibleForTesting
  static double wrapLngStaticForTesting(double lng) => _wrapLngStatic(lng);

  @visibleForTesting
  static double wrapHeadingStaticForTesting(double heading) => _wrapHeadingStatic(heading);

  @visibleForTesting
  double wrapLngForTesting(double lng) => _wrapLng(lng);

  @visibleForTesting
  static double wrapPitchStaticForTesting(double pitch) => _wrapPitchStatic(pitch);
}
