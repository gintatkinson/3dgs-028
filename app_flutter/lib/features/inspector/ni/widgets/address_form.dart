import 'package:flutter/material.dart';

/// Physical Address form with country-code pattern validation [A-Z]{2}.
///
/// Renders editable fields for address, postal_code, state, city, and
/// country_code. The country_code field validates against `^[A-Z]{2}$`.
/// Shows validation errors inline. Calls [onSave] when the user commits
/// a field, passing the full updated data map.
///
/// @realizes UML::AddressForm
class AddressForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Future<String?> Function(Map<String, dynamic> updatedData) onSave;

  const AddressForm({
    super.key,
    required this.initialData,
    required this.onSave,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final Map<String, String?> _errors = {};
  final Map<String, TextEditingController> _controllers = {};

  static const _fields = [
    ('address', 'Address'),
    ('postal_code', 'Postal Code'),
    ('state', 'State'),
    ('city', 'City'),
    ('country_code', 'Country Code'),
  ];

  static final _countryCodePattern = RegExp(r'^[A-Z]{2}$');

  @override
  void initState() {
    super.initState();
    for (final (key, _) in _fields) {
      _controllers[key] = TextEditingController(
        text: widget.initialData[key]?.toString() ?? '',
      );
    }
  }

  @override
  void didUpdateWidget(covariant AddressForm old) {
    super.didUpdateWidget(old);
    if (old.initialData != widget.initialData) {
      for (final (key, _) in _fields) {
        _controllers[key]?.text = widget.initialData[key]?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _commit(String key) async {
    final data = <String, dynamic>{};
    for (final (k, _) in _fields) {
      data[k] = _controllers[k]?.text;
    }
    final error = await widget.onSave(data);
    if (mounted) {
      setState(() => _errors[key] = error);
    }
  }

  String? _validateCountryCode(String value) {
    if (value.isNotEmpty && !_countryCodePattern.hasMatch(value)) {
      return 'Must be 2 uppercase letters (e.g. JP)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (key, label) in _fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _controllers[key],
                  style: const TextStyle(fontSize: 13),
                  keyboardType: key == 'country_code'
                      ? TextInputType.text
                      : TextInputType.text,
                  textCapitalization: key == 'country_code'
                      ? TextCapitalization.characters
                      : TextCapitalization.none,
                  decoration: InputDecoration(
                    errorText: _errors[key] ??
                        (key == 'country_code'
                            ? _validateCountryCode(
                                _controllers[key]?.text ?? '')
                            : null),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onSubmitted: (_) => _commit(key),
                  onChanged: key == 'country_code'
                      ? (_) {
                          setState(() {});
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
