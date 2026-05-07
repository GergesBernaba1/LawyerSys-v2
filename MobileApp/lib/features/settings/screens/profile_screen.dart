import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qadaya_lawyersys/core/localization/app_localizations.dart';
import 'package:qadaya_lawyersys/features/authentication/repositories/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _tenantNameController = TextEditingController();
  final _tenantPhoneController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _canManageTenant = false;
  int? _countryId;
  List<Map<String, dynamic>> _countries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _jobTitleController.dispose();
    _tenantNameController.dispose();
    _tenantPhoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<AuthRepository>();
    try {
      final results = await Future.wait([
        repo.getMyProfile(),
        repo.getCountries(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final countries = results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;
      setState(() {
        _countries = countries;
        _userNameController.text = (profile['userName'] ?? '').toString();
        _fullNameController.text = (profile['fullName'] ?? '').toString();
        _emailController.text = (profile['email'] ?? '').toString();
        _phoneController.text = (profile['phoneNumber'] ?? '').toString();
        _addressController.text = (profile['address'] ?? '').toString();
        _jobTitleController.text = (profile['jobTitle'] ?? '').toString();
        _tenantNameController.text = (profile['tenantName'] ?? '').toString();
        _tenantPhoneController.text =
            (profile['tenantPhoneNumber'] ?? '').toString();
        _countryId = (profile['countryId'] is int)
            ? profile['countryId'] as int
            : int.tryParse((profile['countryId'] ?? '').toString());
        _canManageTenant = profile['canManageTenant'] == true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _countryId == null) return;

    setState(() => _saving = true);
    final repo = context.read<AuthRepository>();

    try {
      await repo.updateMyProfile(
        userName: _userNameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        countryId: _countryId!,
        address: _addressController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        tenantName: _canManageTenant ? _tenantNameController.text.trim() : null,
        tenantPhoneNumber:
            _canManageTenant ? _tenantPhoneController.text.trim() : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdatedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _userNameController,
                    decoration: InputDecoration(labelText: l.username),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.usernameRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(labelText: l.fullName),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.fullNameRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: l.email),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.emailIsRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: l.phoneNumber),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _countryId,
                    decoration: InputDecoration(labelText: l.country),
                    items: _countries
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: (c['id'] is int)
                                ? c['id'] as int
                                : int.tryParse((c['id'] ?? '').toString()),
                            child: Text((c['name'] ?? '').toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _countryId = value),
                    validator: (v) => v == null ? l.countryRequired : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: l.address),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _jobTitleController,
                    decoration: InputDecoration(labelText: l.jobTitle),
                  ),
                  if (_canManageTenant) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tenantNameController,
                      decoration: InputDecoration(labelText: l.tenantName),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tenantPhoneController,
                      decoration: InputDecoration(labelText: l.tenantPhone),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.save),
                  ),
                ],
              ),
            ),
    );
  }
}
