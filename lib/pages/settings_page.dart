import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            const Text(
              'تنظیمات',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: kPrimary),
                    title: const Text('نام شما'),
                    subtitle: Text(appState.userName),
                    trailing: const Icon(Icons.edit_outlined, size: 20),
                    onTap: () => _editName(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: kPrimary),
                    title: const Text('مجوز اعلان‌ها'),
                    subtitle: const Text('درخواست مجوز و ارسال اعلان آزمایشی'),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await NotificationService.requestPermission();
                      if (ok) {
                        await NotificationService.showTest();
                      } else {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('مجوز اعلان داده نشد. از تنظیمات گوشی فعالش کنید.'),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined, color: kPrimary),
                    title: const Text('پاک‌کردن کارهای انجام‌شده'),
                    onTap: () => _confirmClear(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: kPrimary),
                    title: const Text('درباره DayFlow'),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'DayFlow',
                      applicationVersion: '1.0.0',
                      children: const [
                        Text('اپلیکیشن فارسی مدیریت کارهای روزانه. داده‌ها فقط روی همین دستگاه ذخیره می‌شوند.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Future<void> _editName(BuildContext context) async {
    final controller = TextEditingController(text: appState.userName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('نام شما'),
        content: TextField(controller: controller, autofocus: true),
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
    if (name != null) await appState.setName(name);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('پاک‌کردن کارهای انجام‌شده'),
        content: const Text('همه کارهای انجام‌شده حذف شوند؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) await appState.clearDone();
  }
}
