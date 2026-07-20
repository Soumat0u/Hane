import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hane/models/finance_entities.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/theme/responsive.dart';

class KategoriYonetimiView extends StatefulWidget {
  const KategoriYonetimiView({super.key});

  @override
  State<KategoriYonetimiView> createState() => _KategoriYonetimiViewState();
}

class _KategoriYonetimiViewState extends State<KategoriYonetimiView> {
  String _filterType = 'all'; // 'all' | 'cost' | 'income'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFormSheet(BuildContext context, {Category? category, int? defaultParentId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KategoriFormSheet(
        category: category,
        defaultParentId: defaultParentId,
        defaultType: _filterType == 'income' ? 'income' : 'cost',
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Category cat) async {
    final fp = context.read<FinanceProvider>();
    final subcats = fp.categories.where((c) => c.parentId == cat.id).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
          subcats.isNotEmpty
              ? '"${cat.name}" kategorisini silmek istediğinize emin misiniz?\n\n'
                  'Uyarı: Bu kategorinin ${subcats.length} adet alt kategorisi bulunmaktadır. Silindiğinde alt kategorileri de kaldırılacaktır.'
              : '"${cat.name}" kategorisini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true && cat.id != null) {
      await fp.deleteCategory(cat.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${cat.name}" silindi.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final allCats = fp.categories;

    final query = _searchQuery.trim().toLowerCase();
    final rootCategories = allCats.where((c) {
      if (c.parentId != null) return false;
      if (_filterType == 'cost' && !c.isCost) return false;
      if (_filterType == 'income' && !c.isIncome) return false;

      if (query.isEmpty) return true;

      final subcats = allCats.where((sc) => sc.parentId == c.id);
      final matchesName = c.name.toLowerCase().contains(query);
      final matchesGroup = c.group.toLowerCase().contains(query);
      final matchesSub = subcats.any((sc) => sc.name.toLowerCase().contains(query));

      return matchesName || matchesGroup || matchesSub;
    }).toList();

    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kategori Yönetimi',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.brand),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: 'Yeni Kategori',
            onPressed: () => _openFormSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs & Search Bar Container
          Container(
            color: context.colors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Kategori veya grup ara...',
                    hintStyle: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: context.colors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.colors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Type Filter Chips
                Row(
                  children: [
                    _buildFilterChip('Tümü (${allCats.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Gider (${allCats.where((c) => c.isCost).length})',
                      'cost',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Gelir (${allCats.where((c) => c.isIncome).length})',
                      'income',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List Body
          Expanded(
            child: rootCategories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Kategori bulunamadı.',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: centeredPagePadding(context, maxContentWidth: 700, horizontal: 16, top: 16, bottom: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: rootCategories.length,
                    itemBuilder: (context, index) {
                      final root = rootCategories[index];
                      final subcats = allCats.where((sc) => sc.parentId == root.id).toList();

                      return _buildRootCategoryCard(context, root, subcats);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openFormSheet(context),
        backgroundColor: context.colors.brand,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Yeni Kategori', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? context.colors.brand : context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : context.colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRootCategoryCard(BuildContext context, Category root, List<Category> subcats) {
    final isIncome = root.isIncome;
    final color = isIncome ? context.colors.success : context.colors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          // Root Item Tile
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.folder_outlined, color: color, size: 20),
            ),
            title: Text(
              root.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.colors.textPrimary,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isIncome ? 'Gelir' : 'Gider',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
                if (root.group.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('• ${root.group}', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
                ],
                const SizedBox(width: 6),
                Text('• ${subcats.length} Alt', style: TextStyle(fontSize: 11, color: context.colors.textSecondary)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline_rounded, color: context.colors.brand, size: 20),
                  tooltip: 'Alt Kategori Ekle',
                  onPressed: () => _openFormSheet(context, defaultParentId: root.id),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: context.colors.textSecondary, size: 20),
                  tooltip: 'Düzenle',
                  onPressed: () => _openFormSheet(context, category: root),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: context.colors.danger, size: 20),
                  tooltip: 'Sil',
                  onPressed: () => _confirmDelete(context, root),
                ),
              ],
            ),
          ),

          // Subcategories
          if (subcats.isNotEmpty) ...[
            Divider(height: 1, color: context.colors.border),
            Container(
              padding: const EdgeInsets.only(left: 16, right: 12, top: 8, bottom: 8),
              color: context.colors.surfaceVariant.withOpacity(0.4),
              child: Column(
                children: subcats.map((sub) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_right_rounded, size: 18, color: context.colors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sub.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          icon: Icon(Icons.edit_outlined, color: context.colors.textSecondary, size: 18),
                          onPressed: () => _openFormSheet(context, category: sub),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          icon: Icon(Icons.delete_outline_rounded, color: context.colors.danger, size: 18),
                          onPressed: () => _confirmDelete(context, sub),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Category Form BottomSheet for Add & Edit
class _KategoriFormSheet extends StatefulWidget {
  final Category? category;
  final int? defaultParentId;
  final String defaultType;

  const _KategoriFormSheet({
    this.category,
    this.defaultParentId,
    required this.defaultType,
  });

  @override
  State<_KategoriFormSheet> createState() => _KategoriFormSheetState();
}

class _KategoriFormSheetState extends State<_KategoriFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _groupController;
  late String _type;
  int? _parentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _groupController = TextEditingController(text: cat?.group ?? '');
    _type = cat?.type ?? widget.defaultType;
    _parentId = cat?.parentId ?? widget.defaultParentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final fp = context.read<FinanceProvider>();

    try {
      final name = _nameController.text.trim();
      final group = _groupController.text.trim();

      if (widget.category != null && widget.category!.id != null) {
        await fp.updateCategory(
          id: widget.category!.id!,
          name: name,
          type: _type,
          parentId: _parentId,
          group: group.isNotEmpty ? group : 'Diğer',
        );
      } else {
        await fp.createCategory(
          name: name,
          type: _type,
          parentId: _parentId,
          group: group.isNotEmpty ? group : 'Diğer',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.category != null ? 'Kategori güncellendi.' : 'Yeni kategori eklendi.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız oldu. Lütfen tekrar deneyin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = context.watch<FinanceProvider>();
    final isEdit = widget.category != null;

    // Available root categories for parent selection
    final availableParents = fp.categories.where((c) {
      if (c.parentId != null) return false;
      if (c.type != _type) return false;
      if (isEdit && c.id == widget.category!.id) return false;
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Kategoriyi Düzenle' : 'Yeni Kategori',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name Input
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Kategori Adı',
                  hintText: 'Örn. İnşaat Malzemeleri',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Kategori adı zorunludur' : null,
              ),
              const SizedBox(height: 14),

              // Type Selector
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(
                  labelText: 'Tür',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'cost', child: Text('Maliyet / Gider')),
                  DropdownMenuItem(value: 'income', child: Text('Gelir')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _type = val;
                      _parentId = null; // reset parent if type changes
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Group Input
              TextFormField(
                controller: _groupController,
                decoration: InputDecoration(
                  labelText: 'Grup (opsiyonel)',
                  hintText: 'Örn. Malzeme, İşçilik, Genel',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),

              // Parent Category Dropdown
              DropdownButtonFormField<int?>(
                value: _parentId,
                decoration: InputDecoration(
                  labelText: 'Üst Kategori (Alt Kategori ise)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('- Ana Kategori (Üst Yok) -'),
                  ),
                  ...availableParents.map(
                    (p) => DropdownMenuItem<int?>(
                      value: p.id,
                      child: Text(p.name),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _parentId = val),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        isEdit ? 'Kaydet' : 'Kategori Ekle',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
