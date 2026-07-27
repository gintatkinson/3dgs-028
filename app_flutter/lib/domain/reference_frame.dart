class ReferenceFrame {
  final String? astronomicalBody;
  final String? alternateSystem;

  const ReferenceFrame({
    this.astronomicalBody,
    this.alternateSystem,
  });

  bool get hasAlternateSystems => alternateSystem != null;

  factory ReferenceFrame.fromMap(Map<String, dynamic> map) {
    return ReferenceFrame(
      astronomicalBody: map['astronomical_body'] as String?,
      alternateSystem: map['alternate_system'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (astronomicalBody != null) 'astronomical_body': astronomicalBody,
      if (alternateSystem != null) 'alternate_system': alternateSystem,
    };
  }
}
