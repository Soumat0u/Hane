import 'package:flutter/material.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hane/utils/formatters.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/views/widgets/app_form.dart';
import 'package:hane/views/cari_hesap_detay_view.dart';

/// Cari hesap türü -> görünen ad eşlemesi (backend Contact.KIND_CHOICES ile aynı sıra).
const Map<String, String> kContactKindLabels = {
  'supplier': 'Tedarikçi',
  'customer': 'Müşteri',
  'subcontractor': 'Taşeron',
  'government': 'Devlet',
  'bank': 'Banka',
  'other': 'Diğer',
};

class CariHesaplarView extends StatelessWidget {
  const CariHesaplarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        title: Text('Cari Hesaplar',
            style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1_rounded, color: context.colors.brand),
            onPressed: () => _showNewContactForm(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<FinanceProvider>(
          builder: (context, fp, child) {
            final byKind = fp.contactsByKind;
            final hasAny = byKind.values.any((l) => l.isNotEmpty);

            return RefreshIndicator(
              onRefresh: fp.refreshSilently,
              child: !hasAny
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Container(
                        height: MediaQuery.of(context).size.height - 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Henüz cari hesap bulunmuyor.', style: TextStyle(color: Colors.grey[500])),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => _showNewContactForm(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Yeni Cari Ekle'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final kind in kContactKindLabels.keys)
                            if ((byKind[kind] ?? const <Contact>[]).isNotEmpty) ...[
                              _buildSectionHeader(context, kContactKindLabels[kind]!.toUpperCase()),
                              _buildGroupList(context, byKind[kind]!),
                              const SizedBox(height: 24),
                            ],
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: context.colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, List<Contact> contacts) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          ...contacts.asMap().entries.map((entry) {
            final idx = entry.key;
            final c = entry.value;
            return Column(
              children: [
                _buildListItem(context: context, contact: c, isLast: idx == contacts.length - 1),
                if (idx < contacts.length - 1) Divider(height: 1, indent: 16, color: context.colors.surfaceVariant),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListItem({required BuildContext context, required Contact contact, bool isLast = false}) {
    final isDebt = contact.balance > 0;
    final isCredit = contact.balance < 0;
    final color = isDebt ? context.colors.danger : (isCredit ? context.colors.success : context.colors.textSecondary);
    final label = isDebt ? 'Borcumuz' : (isCredit ? 'Alacağımız' : '');

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CariHesapDetayView(contact: contact)));
      },
      borderRadius: isLast
          ? const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))
          : const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                contact.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.colors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(contact.balance.abs()),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                ),
                if (label.isNotEmpty)
                  Text(label, style: TextStyle(fontSize: 11, color: color)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.colors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showNewContactForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewContactForm(),
    );
  }
}

class _NewContactForm extends StatefulWidget {
  const _NewContactForm();

  @override
  State<_NewContactForm> createState() => _NewContactFormState();
}

class _NewContactFormState extends State<_NewContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _taxNumberCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _kind = 'supplier';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _taxNumberCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final contact = Contact(
      name: _nameCtrl.text.trim(),
      kind: _kind,
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      taxNumber: _taxNumberCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
    );
    try {
      await context.read<FinanceProvider>().addContact(contact);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.scaffold,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Yeni Cari Ekle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
              const SizedBox(height: 20),
              AppTextField(controller: _nameCtrl, label: 'Ad / Unvan', required: true),
              AppDropdown<String>(
                  label: 'Tür', value: _kind, options: kContactKindLabels, onChanged: (v) => setState(() => _kind = v!)),
              AppTextField(controller: _phoneCtrl, label: 'Telefon', hint: 'Opsiyonel'),
              AppTextField(controller: _emailCtrl, label: 'E-posta', hint: 'Opsiyonel'),
              AppTextField(controller: _taxNumberCtrl, label: 'Vergi No', hint: 'Opsiyonel'),
              AppTextField(controller: _noteCtrl, label: 'Not', hint: 'Opsiyonel'),
              const SizedBox(height: 8),
              AppSaveButton(saving: _saving, onPressed: _save),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
