import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hane/theme/app_theme.dart';
import 'package:hane/providers/finance_provider.dart';
import 'package:hane/models/todo.dart';

/// Basit yapılacaklar listesi: üstteki Kişisel/Projeler sekmesinden geçiş yapılır.
class TodoPanel extends StatefulWidget {
  const TodoPanel({super.key});

  @override
  State<TodoPanel> createState() => _TodoPanelState();
}

class _TodoPanelState extends State<TodoPanel> {
  String _scope = Todo.personal;
  final TextEditingController _titleController = TextEditingController();
  int? _selectedProjectId;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _add(FinanceProvider fp) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    if (_scope == Todo.project && _selectedProjectId == null) return;
    setState(() => _saving = true);
    try {
      await fp.addTodo(Todo(
        title: title,
        scope: _scope,
        projectId: _scope == Todo.project ? _selectedProjectId : null,
      ));
      _titleController.clear();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, fp, child) {
        final list = fp.todos.where((t) {
          if (t.scope != _scope) return false;
          if (_scope == Todo.project) return _selectedProjectId != null && t.projectId == _selectedProjectId;
          return true;
        }).toList();
        final projects = fp.projects;
        final canAdd = _scope == Todo.personal || _selectedProjectId != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'YAPILACAKLAR',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: context.colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTab(context, 'Kişisel', Icons.person_outline_rounded, Todo.personal)),
                const SizedBox(width: 8),
                Expanded(child: _buildTab(context, 'Projeler', Icons.folder_open_rounded, Todo.project)),
              ],
            ),
            if (_scope == Todo.project) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _selectedProjectId,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: context.colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.border)),
                ),
                hint: const Text('Proje seçin...'),
                items: [
                  for (final p in projects)
                    if (p.id != null) DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
            ],
            if (canAdd) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Yeni madde ekle...',
                        isDense: true,
                        filled: true,
                        fillColor: context.colors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: context.colors.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _saving ? null : () => _add(fp),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(backgroundColor: context.colors.brand, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (_scope == Todo.project && _selectedProjectId == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Maddeleri görmek için bir proje seçin.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              )
            else if (list.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  _scope == Todo.personal ? 'Henüz kişisel madde yok.' : 'Bu projede henüz madde yok.',
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < list.length; i++) ...[
                      _buildTodoRow(context, fp, list[i]),
                      if (i < list.length - 1) Divider(height: 1, indent: 16, color: context.colors.surfaceVariant),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, String label, IconData icon, String scope) {
    final active = _scope == scope;
    return InkWell(
      onTap: () => setState(() => _scope = scope),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? context.colors.brand.withValues(alpha: 0.12) : context.colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? context.colors.brand : context.colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? context.colors.brand : context.colors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: active ? context.colors.brand : context.colors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoRow(BuildContext context, FinanceProvider fp, Todo t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: t.isDone,
            onChanged: (_) => fp.toggleTodo(t),
            activeColor: context.colors.brand,
          ),
          Expanded(
            child: Text(
              t.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: t.isDone ? TextDecoration.lineThrough : null,
                color: t.isDone ? context.colors.textSecondary : context.colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: context.colors.textSecondary),
            visualDensity: VisualDensity.compact,
            onPressed: () => fp.deleteTodo(t.id!),
          ),
        ],
      ),
    );
  }
}
