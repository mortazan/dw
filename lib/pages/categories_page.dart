import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/field_actions.dart';
import 'tasks_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key, this.controller});

  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'دسته‌بندی‌ها',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: kPrimary),
                  onPressed: () => showCategoryEditor(context),
                  icon: const Icon(Icons.add),
                  label: const Text('دسته جدید'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final c in categories) _row(context, c),
          ],
        ),
      );

  Widget _row(BuildContext context, Cat c) {
    final list = appState.tasks.where((t) => catOf(t.category).name == c.name);
    final total = list.length;
    final done = list.where((t) => t.done).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskListScreen(
              title: c.name,
              filter: (t) => catOf(t.category).name == c.name,
            ),
          ),
        ),
        child: AppCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(c.icon, color: c.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : done / total,
                        minHeight: 6,
                        color: c.color,
                        backgroundColor: c.color.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${toFa(done)}/${toFa(total)}',
                style: const TextStyle(color: kMuted),
              ),
              IconButton(
                tooltip: 'ویرایش',
                onPressed: () => showCategoryEditor(context, existing: c),
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Create a category, or edit/delete [existing].
Future<void> showCategoryEditor(BuildContext context, {Cat? existing}) async {
  final nameController = TextEditingController(text: existing?.name ?? '');
  var color = existing?.color ?? categoryColors.first;
  var iconIndex = existing?.iconIndex ?? 0;
  var fields = [...?existing?.fields];
  String? error;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null ? 'دسته جدید' : 'ویرایش دسته'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: existing == null,
                decoration: InputDecoration(
                  labelText: 'نام دسته',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 16),
              const Text('رنگ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in categoryColors)
                    GestureDetector(
                      onTap: () => setState(() => color = c),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == c
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: color == c
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('آیکون', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < categoryIcons.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => iconIndex = i),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconIndex == i
                              ? color.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIcons[i],
                          color: iconIndex == i ? color : kMuted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'فیلدهای اضافی هنگام ثبت کار',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'مثلاً شماره تلفن (با انتخاب از مخاطبین) یا لینک برنامه',
                style: TextStyle(color: kMuted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final f in fields)
                    InputChip(
                      avatar: Icon(fieldIcon(f.type), size: 16),
                      label: Text(f.required ? '${f.label} *' : f.label),
                      onDeleted: () => setState(
                        () => fields = fields.where((x) => x.id != f.id).toList(),
                      ),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('فیلد جدید'),
                    onPressed: () async {
                      final f = await _showFieldEditor(context);
                      if (f != null) setState(() => fields = [...fields, f]);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (existing != null && categories.length > 1)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE5484D)),
              onPressed: () {
                Navigator.pop(dialogContext);
                appState.deleteCategory(existing.name);
                messengerKey.currentState
                  ?..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('دسته حذف شد؛ کارهای آن به «سایر» رفتند'),
                    ),
                  );
              },
              child: const Text('حذف'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                setState(() => error = 'نام دسته را وارد کنید');
                return;
              }
              final ok = await appState.saveCategory(
                Cat(name, color, iconIndex, fields),
                oldName: existing?.name,
              );
              if (!ok) {
                setState(() => error = 'این نام قبلاً استفاده شده است');
                return;
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    ),
  );
  nameController.dispose();
}

Future<CatField?> _showFieldEditor(BuildContext context) async {
  final labelController = TextEditingController();
  var type = FieldType.phone;
  var required = true;
  final result = await showDialog<CatField>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('فیلد جدید'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'عنوان فیلد'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final t in FieldType.values)
                  ChoiceChip(
                    selected: type == t,
                    onSelected: (_) => setState(() {
                      type = t;
                      if (labelController.text.trim().isEmpty) {
                        labelController.text = t.label;
                      }
                    }),
                    label: Text(t.label),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: required,
              onChanged: (v) => setState(() => required = v),
              title: const Text('اجباری'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              final label = labelController.text.trim();
              if (label.isEmpty) return;
              Navigator.pop(
                dialogContext,
                CatField(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  label: label,
                  type: type,
                  required: required,
                ),
              );
            },
            child: const Text('افزودن'),
          ),
        ],
      ),
    ),
  );
  labelController.dispose();
  return result;
}
