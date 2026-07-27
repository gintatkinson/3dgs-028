class GeoLocation {
  final String entityId;
  final String? timestamp;
  final String? validUntil;

  const GeoLocation({
    required this.entityId,
    this.timestamp,
    this.validUntil,
  });

  factory GeoLocation.fromMap(String entityId, Map<String, dynamic> map) {
    return GeoLocation(
      entityId: entityId,
      timestamp: map['timestamp'] as String?,
      validUntil: map['valid_until'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (timestamp != null) 'timestamp': timestamp,
      if (validUntil != null) 'valid_until': validUntil,
    };
  }

  bool get isExpired {
    if (validUntil == null) return false;
    final parsed = DateTime.tryParse(validUntil!);
    if (parsed == null) return false;
    return parsed.toUtc().isBefore(DateTime.now().toUtc());
  }

  bool get hasTemporalContext => timestamp != null;
}
