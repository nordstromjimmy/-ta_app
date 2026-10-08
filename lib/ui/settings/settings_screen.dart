import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/company_info.dart';
import '../../data/repositories/settings_repository.dart';
import '../core/widgets/ata_image.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _picker = ImagePicker();

  late final TextEditingController _name;
  late final TextEditingController _contactPerson;
  late final TextEditingController _orgNumber;
  late final TextEditingController _address;
  late final TextEditingController _postalCode;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _website;

  XFile? _newLogo;
  bool _removeLogo = false;
  bool _saving = false;

  List<TextEditingController> get _controllers => [
    _name,
    _contactPerson,
    _orgNumber,
    _address,
    _postalCode,
    _city,
    _phone,
    _email,
    _website,
  ];

  @override
  void initState() {
    super.initState();
    final c = context.read<SettingsRepository>().company;
    _name = TextEditingController(text: c.name);
    _contactPerson = TextEditingController(text: c.contactPerson);
    _orgNumber = TextEditingController(text: c.orgNumber);
    _address = TextEditingController(text: c.address);
    _postalCode = TextEditingController(text: c.postalCode);
    _city = TextEditingController(text: c.city);
    _phone = TextEditingController(text: c.phone);
    _email = TextEditingController(text: c.email);
    _website = TextEditingController(text: c.website);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      // No imageQuality, so PNG logos keep their transparency.
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
      );
      if (image == null || !mounted) return;
      setState(() {
        _newLogo = image;
        _removeLogo = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showMessage('Kunde inte öppna bildbiblioteket: ${e.message ?? e.code}');
    }
  }

  void _clearLogo() {
    setState(() {
      _newLogo = null;
      _removeLogo = true;
    });
  }

  File? _logoPreview(SettingsRepository repo) {
    final newLogo = _newLogo;
    if (newLogo != null) return File(newLogo.path);
    if (_removeLogo) return null;
    return repo.logoFile;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await context.read<SettingsRepository>().saveCompany(
        CompanyInfo(
          name: _name.text.trim(),
          contactPerson: _contactPerson.text.trim(),
          orgNumber: _orgNumber.text.trim(),
          address: _address.text.trim(),
          postalCode: _postalCode.text.trim(),
          city: _city.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          website: _website.text.trim(),
        ),
        newLogo: _newLogo,
        removeLogo: _removeLogo,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Inställningarna sparades')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Kunde inte spara: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SettingsRepository>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Inställningar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Företagsuppgifter', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Visas i sidhuvud och sidfot på exporterade PDF:er.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _LogoPicker(
            file: _logoPreview(repo),
            onPick: _pickLogo,
            onRemove: _clearLogo,
          ),
          const SizedBox(height: 24),
          _Field(controller: _name, label: 'Företagsnamn'),
          _Field(
            controller: _contactPerson,
            label: 'Kontaktperson',
            hint: 'Ditt namn',
          ),
          _Field(
            controller: _orgNumber,
            label: 'Organisationsnummer',
            hint: '556677-8899',
            capitalization: TextCapitalization.none,
          ),
          _Field(controller: _address, label: 'Adress'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _Field(
                  controller: _postalCode,
                  label: 'Postnummer',
                  capitalization: TextCapitalization.none,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _Field(controller: _city, label: 'Ort'),
              ),
            ],
          ),
          _Field(
            controller: _phone,
            label: 'Telefon',
            keyboardType: TextInputType.phone,
            capitalization: TextCapitalization.none,
          ),
          _Field(
            controller: _email,
            label: 'E-post',
            keyboardType: TextInputType.emailAddress,
            capitalization: TextCapitalization.none,
          ),
          _Field(
            controller: _website,
            label: 'Webbplats',
            keyboardType: TextInputType.url,
            capitalization: TextCapitalization.none,
            isLast: true,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Spara'),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.capitalization = TextCapitalization.words,
    this.isLast = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final file = this.file;
    final colors = Theme.of(context).colorScheme;

    if (file == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size.fromHeight(96),
        ),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Lägg till logotyp'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white, // Matches the PDF page.
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: AtaImage(
            key: ValueKey(file.path),
            file: file,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Byt logotyp'),
            ),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.close),
              label: const Text('Ta bort'),
            ),
          ],
        ),
      ],
    );
  }
}
