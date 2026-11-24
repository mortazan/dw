import 'dart:io';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? pal(context).card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: pal(context).border),
        ),
        child: child,
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(color: kMuted)),
            ],
          ),
        ),
      );
}

/// The user's profile photo, or their initial on a gradient when none is set.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => _build(),
      );

  Widget _build() {
    final path = appState.avatarPath;
    if (path != null && File(path).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Reload when the photo changes (the file name is unique each time).
          key: ValueKey(path),
        ),
      );
    }
    final name = appState.userName.trim();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [kPrimary, Color(0xFF9B83F5)]),
      ),
      child: Text(
        name.isEmpty ? '؟' : name.substring(0, 1),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

Future<void> showAvatarOptions(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: pal(context).card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: kPrimary),
            title: const Text('انتخاب عکس از گالری'),
            onTap: () async {
              Navigator.pop(sheetContext);
              await appState.pickAvatar();
            },
          ),
          if (appState.avatarPath != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFE5484D)),
              title: const Text('حذف عکس'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await appState.removeAvatar();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Shows a small dialog with a text field. Returns the entered text, or null
/// if cancelled.
Future<String?> editTextDialog(
  BuildContext context, {
  required String title,
  required String initial,
  String? hint,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: null,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('ذخیره'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<void> editGreeting(BuildContext context) async {
  final text = await editTextDialog(
    context,
    title: 'متن خوش‌آمدگویی',
    initial: appState.greeting,
    hint: defaultGreeting,
  );
  if (text != null) await appState.setGreeting(text);
}
