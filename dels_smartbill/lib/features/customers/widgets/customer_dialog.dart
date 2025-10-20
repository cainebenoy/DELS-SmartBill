import 'package:flutter/material.dart';
import '../../../core/design/app_colors.dart';

class CustomerDialogResult {
  final String name;
  final String phone;
  final String email;
  final String address;

  const CustomerDialogResult({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
  });
}

class CustomerDialog extends StatefulWidget {
  final CustomerDialogResult? initial;

  const CustomerDialog({super.key, this.initial});

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.initial?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.initial?.email ?? '');
    _addressCtrl = TextEditingController(text: widget.initial?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Customer' : 'Edit Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.secondary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone *',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.secondary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email *',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.secondary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!v.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  labelText: 'Address',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.secondary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                CustomerDialogResult(
                  name: _nameCtrl.text.trim(),
                  phone: _phoneCtrl.text.trim(),
                  email: _emailCtrl.text.trim(),
                  address: _addressCtrl.text.trim(),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
