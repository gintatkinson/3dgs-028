import 'package:app_flutter/domain/type_descriptor.dart';

final _controlCharsRegex = RegExp(r'[\x00-\x1f\x7f]');

class ReferenceFrameValidation {
  final bool isValid;
  final Map<String, dynamic> sanitizedFrame;
  final String sanitizedFrameName;

  const ReferenceFrameValidation({
    required this.isValid,
    required this.sanitizedFrame,
    required this.sanitizedFrameName,
  });
}

String sanitizeFrameName(String name) {
  var result = name.trim();
  result = result.replaceAll(_controlCharsRegex, '');
  if (result.toLowerCase().startsWith('the-')) {
    result = result.substring(4);
  }
  return result.toUpperCase();
}

ReferenceFrameValidation validateReferenceFrame(
  Map<String, dynamic> frame, {
  String? frameName,
  bool alternateSystemEnabled = false,
}) {
  if (frameName != null) {
    for (final codeUnit in frameName.codeUnits) {
      if (codeUnit <= 0x1f || codeUnit == 0x7f) {
        return ReferenceFrameValidation(
          isValid: false,
          sanitizedFrame: frame,
          sanitizedFrameName: sanitizeFrameName(frameName),
        );
      }
    }
  }

  if (frame['alternateSystem'] != null && !alternateSystemEnabled) {
    return ReferenceFrameValidation(
      isValid: false,
      sanitizedFrame: frame,
      sanitizedFrameName: frameName != null ? sanitizeFrameName(frameName) : '',
    );
  }

  return ReferenceFrameValidation(
    isValid: true,
    sanitizedFrame: frame,
    sanitizedFrameName: frameName != null ? sanitizeFrameName(frameName) : '',
  );
}

/// Generic validation function that evaluates constraints on a map of input values.
bool validateFields(Map<String, dynamic> input, List<FieldDescriptor> descriptors) {
  for (final fd in descriptors) {
    final value = input[fd.key];

    // If missing/empty, check required constraint. Otherwise skip validation if not required.
    if (value == null || (value is String && value.isEmpty)) {
      if (fd.required) {
        return false;
      }
      continue;
    }

    final strVal = value.toString();
    if (fd.type == 'int') {
      final parsed = int.tryParse(strVal);
      if (parsed == null) return false;
      if (fd.minValue != null && parsed < fd.minValue!) return false;
      if (fd.maxValue != null && parsed > fd.maxValue!) return false;
    } else if (fd.type == 'double' || fd.type == 'real') {
      final parsed = double.tryParse(strVal);
      if (parsed == null) return false;
      if (fd.minValue != null && parsed < fd.minValue!) return false;
      if (fd.maxValue != null && parsed > fd.maxValue!) return false;
    } else if (fd.type == 'string') {
      if (fd.pattern != null && fd.pattern!.isNotEmpty) {
        final regex = RegExp(fd.pattern!);
        if (!regex.hasMatch(strVal)) return false;
      }
    } else if (fd.type == 'enum') {
      if (fd.enumOptions != null && !fd.enumOptions!.contains(strVal)) {
        return false;
      }
    }
  }
  return true;
}
