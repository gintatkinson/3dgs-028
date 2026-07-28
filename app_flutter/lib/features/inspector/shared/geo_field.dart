import 'package:flutter/material.dart';

/// Reusable editable field with validation on submit/blur.
///
/// Shows a label above, a [TextField] below, and error text on validation
/// failure. Supports numeric keyboard, disable state, and focus-based commit.
/// Validates on [onSubmitted] by calling [onSave] and displaying the returned
/// error string below the field.
///
/// @realizes UML::GeoField
class GeoField extends StatefulWidget {
  final String label;
  final String? value;
  final bool isNumeric;
  final bool enabled;
  final Future<String?> Function(String value) onSave;

  const GeoField({
    super.key,
    required this.label,
    this.value,
    this.isNumeric = false,
    this.enabled = true,
    required this.onSave,
  });

  @override
  State<GeoField> createState() => _GeoFieldState();
}

class _GeoFieldState extends State<GeoField> {
  late TextEditingController _controller;
  String? _error;
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant GeoField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_committed) {
      _controller.text = widget.value ?? '';
    }
    if (old.value != widget.value && _committed) {
      _controller.text = widget.value ?? '';
      _committed = false;
      setState(() => _error = null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _commit() async {
    _committed = true;
    final error = await widget.onSave(_controller.text);
    if (mounted) {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: widget.isNumeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              errorText: _error,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            onSubmitted: (_) => _commit(),
          ),
        ],
      ),
    );
  }
}
