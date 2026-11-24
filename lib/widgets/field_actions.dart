import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme.dart';

IconData fieldIcon(FieldType type) {
  switch (type) {
    case FieldType.phone:
      return Icons.call_outlined;
    case FieldType.link:
      return Icons.open_in_new;
    case FieldType.text:
      return Icons.notes_outlined;
  }
}

void _message(String text) => messengerKey.currentState
  ?..clearSnackBars()
  ..showSnackBar(SnackBar(content: Text(text)));

Future<void> _open(Uri uri) async {
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _message('برنامه‌ای برای باز کردن این مورد پیدا نشد');
  } catch (_) {
    _message('برنامه‌ای برای باز کردن این مورد پیدا نشد');
  }
}

/// Runs the natural action for a field value: call/SMS for phones, open the
/// link or app for links, copy for plain text.
Future<void> runFieldAction(
  BuildContext context,
  CatField field,
  String value,
) async {
  switch (field.type) {
    case FieldType.phone:
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: pal(context).card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.call, color: kGreen),
                title: const Text('تماس'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(Uri(scheme: 'tel', path: value));
                },
              ),
              ListTile(
                leading: const Icon(Icons.sms_outlined, color: kBlue),
                title: const Text('پیامک'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(Uri(scheme: 'sms', path: value));
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: kMuted),
                title: const Text('کپی شماره'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Clipboard.setData(ClipboardData(text: value));
                  _message('شماره کپی شد');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    case FieldType.link:
      var url = value.trim();
      if (!url.contains('://') && !url.contains(':')) url = 'https://$url';
      final uri = Uri.tryParse(url);
      if (uri == null) {
        _message('آدرس معتبر نیست');
        return;
      }
      await _open(uri);
    case FieldType.text:
      await Clipboard.setData(ClipboardData(text: value));
      _message('کپی شد');
  }
}
