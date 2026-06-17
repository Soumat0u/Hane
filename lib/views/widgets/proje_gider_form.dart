import 'package:flutter/material.dart';

import 'package:hane/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/project.dart';
import 'package:hane/models/financial_transaction.dart';
import 'package:hane/models/finance_entities.dart';

/// Projeye özel gider ekleme panelini alttan yukarı açar.
Future<void> showProjeGiderForm(BuildContext context, Project project) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProjeGiderForm(project: project),
  );
}


class ProjeGiderForm extends StatefulWidget {
  final Project project;
  const ProjeGiderForm({super.key, required this.project});

  @override
  State<ProjeGiderForm> createState() => _ProjeGiderFormState();
}

class _ProjeGiderFormState extends State<ProjeGiderForm> {
  // İnşaat odaklı gider türü
  String _giderTuru = 'Malzeme'; // Malzeme / İşçilik / Diğer

  DateTime _date = DateTime.now();
  Category? _anaKategori;
  Category? _altKategori;

  final _tutarController = TextEditingController();
  final _miktarController = TextEditingController();
  String _birim = 'Adet';
  final _tedarikciController = TextEditingController();
  String? _odemeKaynagi;
  final _aciklamaController = TextEditingController();

  bool _saving = false;

  static const _birimler = ['Adet', 'm³', 'm²', 'ton', 'kg', 'paket', 'sefer', 'gün', 'Diğer'];
  static const _aylar = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  @override
  void dispose() {
    _tutarController.dispose();
    _miktarController.dispose();
    _tedarikciController.dispose();
    _aciklamaController.dispose();
    super.dispose();
  }

  String get _dateLabel => '${_date.day} ${_aylar[_date.month - 1]} ${_date.year}';
  String get _dateIso =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final fp = context.watch<FinanceProvider>();
    final accounts = fp.accounts.map((a) => a.name).toList();
    if (_odemeKaynagi == null && accounts.isNotEmpty) _odemeKaynagi = accounts.first;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 4, decoration: BoxDecoration(
                color: context.colors.border, borderRadius: BorderRadius.circular(2))),
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.business_center_rounded, color: context.colors.danger, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Proje Gideri Ekle',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                        Text(widget.project.name,
                            style: TextStyle(fontSize: 12, color: context.colors.textSecondary), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: context.colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.colors.surfaceVariant),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gider türü (inşaat odaklı)
                    _segmented(context),
                    const SizedBox(height: 18),

                    _field(context, 'TARİH', _tappable(context, _dateLabel, Icons.calendar_month_outlined, _pickDate)),
                    const SizedBox(height: 14),

                    _field(context, 'ANA KATEGORİ',
                        _tappable(context, _anaKategori?.name ?? 'Seçiniz', Icons.folder_open_rounded, _pickAna,
                            placeholder: _anaKategori == null)),
                    const SizedBox(height: 14),

                    _field(context, 'ALT KATEGORİ',
                        _tappable(context, 
                          _altKategori?.name ?? (_anaKategori == null ? 'Önce ana kategori' : 'Seçiniz (opsiyonel)'),
                          Icons.subdirectory_arrow_right_rounded,
                          _anaKategori == null ? null : _pickAlt,
                          placeholder: _altKategori == null,
                        )),
                    const SizedBox(height: 14),

                    // Tutar
                    _field(context, 'TUTAR', _input(context, _tutarController, prefix: '₺  ', keyboard: TextInputType.number, hint: '0')),
                    const SizedBox(height: 14),

                    // Miktar + Birim (inşaat odaklı)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _field(context, 'MİKTAR',
                              _input(context, _miktarController, keyboard: TextInputType.number, hint: 'örn. 12')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _field(context, 'BİRİM', _birimDropdown(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _field(context, 'TEDARİKÇİ / FİRMA', _input(context, _tedarikciController, hint: 'örn. Beton A.Ş.')),
                    const SizedBox(height: 14),

                    _field(context, 'ÖDEME KAYNAĞI',
                        accounts.isEmpty ? _tappable(context, 'Hesap yok', Icons.account_balance_wallet_outlined, null,
                            placeholder: true) : _accountDropdown(context, accounts)),
                    const SizedBox(height: 14),

                    _field(context, 'AÇIKLAMA', _input(context, _aciklamaController, hint: 'İsteğe bağlı not')),
                  ],
                ),
              ),
            ),
            // Kaydet
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _save(fp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.brand, foregroundColor: context.colors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.surface))
                        : const Text('GİDERİ KAYDET',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Eylemler ────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAna() async {
    final fp = context.read<FinanceProvider>();
    final selected = await _showCategorySheet(
      title: 'Ana Kategori',
      grouped: fp.mainCategoriesByGroup(income: false),
    );
    if (selected != null) {
      setState(() {
        _anaKategori = selected;
        _altKategori = null; // ana değişince alt sıfırlanır
      });
    }
  }

  Future<void> _pickAlt() async {
    final fp = context.read<FinanceProvider>();
    final selected = await _showSubSheet(fp, _anaKategori!);
    if (selected != null) setState(() => _altKategori = selected);
  }

  Future<void> _save(FinanceProvider fp) async {
    final amount = double.tryParse(_tutarController.text.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.')) ?? 0;
    if (_anaKategori == null) {
      _toast('Lütfen ana kategori seçin.');
      return;
    }
    if (amount <= 0) {
      _toast('Lütfen geçerli bir tutar girin.');
      return;
    }

    // Açıklamaya miktar/birim ve gider türünü ekle
    final parts = <String>[_giderTuru];
    if (_miktarController.text.trim().isNotEmpty) {
      parts.add('${_miktarController.text.trim()} $_birim');
    }
    if (_aciklamaController.text.trim().isNotEmpty) parts.add(_aciklamaController.text.trim());
    final description = parts.join(' • ');

    final category = _altKategori?.name ?? _anaKategori!.name;

    final t = FinancialTransaction(
      projectId: widget.project.id,
      type: 'Gider',
      amount: amount,
      date: _dateIso,
      category: category,
      description: description,
      sourceName: _odemeKaynagi ?? '',
      contactName: _tedarikciController.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await fp.addTransaction(t);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proje gideri kaydedildi.'), backgroundColor: context.colors.success),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _toast('Gider kaydedilemedi.');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Kategori seçim sayfaları ─────────────────────────────────────────────────

  Future<Category?> _showCategorySheet({
    required String title,
    required Map<String, List<Category>> grouped,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
            ),
            Divider(height: 1, color: context.colors.surfaceVariant),
            Expanded(
              child: ListView(
                children: [
                  for (final entry in grouped.entries) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
                      child: Text(entry.key.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.5)),
                    ),
                    for (final c in entry.value)
                      ListTile(
                        dense: true,
                        title: Text(c.name, style: TextStyle(fontSize: 14, color: context.colors.textPrimary)),
                        trailing: c.childCount > 0
                            ? Text('${c.childCount} alt', style: TextStyle(fontSize: 11, color: context.colors.textSecondary))
                            : null,
                        onTap: () => Navigator.pop(ctx, c),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Alt kategori seçimi + kullanıcı kendi alt kategorisini ekleyebilir
  Future<Category?> _showSubSheet(FinanceProvider fp, Category ana) {
    final controller = TextEditingController();
    bool adding = false;
    bool saving = false;
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          final subs = fp.subCategoriesOf(ana.id!);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: context.colors.border, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.folder_open_rounded, color: context.colors.danger, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${ana.name} • Alt Kategori',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: context.colors.surfaceVariant),
                  Expanded(
                    child: ListView(
                      children: [
                        if (subs.isEmpty && !adding)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('Henüz alt kategori yok. Aşağıdan ekleyebilirsiniz.',
                                style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
                          ),
                        for (final s in subs)
                          ListTile(
                            dense: true,
                            title: Text(s.name, style: TextStyle(fontSize: 14, color: context.colors.textPrimary)),
                            onTap: () => Navigator.pop(ctx, s),
                          ),
                        const SizedBox(height: 6),
                        if (adding)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: 'Yeni alt kategori adı',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: saving ? null : () async {
                                    final name = controller.text.trim();
                                    if (name.isEmpty) return;
                                    setSheet(() => saving = true);
                                    try {
                                      final created = await fp.addSubCategory(name: name, parentId: ana.id!, type: 'cost');
                                      if (ctx.mounted) Navigator.pop(ctx, created);
                                    } catch (_) {
                                      setSheet(() => saving = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: context.colors.danger, foregroundColor: context.colors.surface, elevation: 0),
                                  child: saving
                                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.surface))
                                      : const Text('Ekle'),
                                ),
                              ],
                            ),
                          )
                        else
                          ListTile(
                            dense: true,
                            leading: Icon(Icons.add_circle_outline_rounded, color: context.colors.danger, size: 22),
                            title: Text('Yeni alt kategori ekle',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.danger)),
                            onTap: () => setSheet(() => adding = true),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // ── Küçük UI yardımcıları ─────────────────────────────────────────────────────

  Widget _segmented(BuildContext context) {
    Widget item(String t, IconData ic) {
      final sel = _giderTuru == t;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _giderTuru = t),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: sel ? Color(0xFFFEF2F2) : context.colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? context.colors.danger : context.colors.border, width: sel ? 1.5 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ic, size: 20, color: sel ? context.colors.danger : context.colors.textSecondary),
                const SizedBox(height: 4),
                Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sel ? context.colors.danger : context.colors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(children: [
      item('Malzeme', Icons.inventory_2_outlined),
      item('İşçilik', Icons.engineering_outlined),
      item('Diğer', Icons.more_horiz_rounded),
    ]);
  }

  Widget _field(BuildContext context, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.colors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _tappable(BuildContext context, String text, IconData icon, VoidCallback? onTap, {bool placeholder = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: context.colors.border)),
        child: Row(
          children: [
            Expanded(child: Text(text,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                    color: placeholder ? context.colors.textSecondary : context.colors.textPrimary),
                overflow: TextOverflow.ellipsis)),
            Icon(icon, color: context.colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _input(BuildContext context, TextEditingController c, {String? prefix, String? hint, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.colors.textPrimary),
      decoration: InputDecoration(
        prefixText: prefix,
        prefixStyle: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(color: context.colors.textSecondary, fontSize: 14),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.colors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.colors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.colors.accent, width: 1.5)),
      ),
    );
  }

  Widget _birimDropdown(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: context.colors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _birim,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondary),
          items: _birimler.map((b) => DropdownMenuItem(value: b, child: Text(b,
              style: TextStyle(fontSize: 14, color: context.colors.textPrimary)))).toList(),
          onChanged: (v) => setState(() => _birim = v!),
        ),
      ),
    );
  }

  Widget _accountDropdown(BuildContext context, List<String> accounts) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: context.colors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: accounts.contains(_odemeKaynagi) ? _odemeKaynagi : accounts.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.textSecondary),
          items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a,
              style: TextStyle(fontSize: 14, color: context.colors.textPrimary), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _odemeKaynagi = v),
        ),
      ),
    );
  }
}
