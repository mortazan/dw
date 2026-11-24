import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
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
            _group(context, 'عمومی', [
              ListTile(
                leading: const Icon(Icons.person_outline, color: kPrimary),
                title: const Text('نام شما'),
                subtitle: Text(appState.userName),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => _editName(context),
              ),
              ListTile(
                leading: UserAvatar(size: 40),
                title: const Text('عکس پروفایل'),
                subtitle: Text(
                  appState.avatarPath == null ? 'انتخاب از گالری' : 'تغییر یا حذف عکس',
                ),
                onTap: () => showAvatarOptions(context),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: kPrimary),
                title: const Text('متن خوش‌آمدگویی'),
                subtitle: Text(appState.greeting),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => editGreeting(context),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined, color: kPrimary),
                title: const Text('حالت نمایش'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final entry in const {
                        ThemeMode.system: 'سیستم',
                        ThemeMode.light: 'روشن',
                        ThemeMode.dark: 'تاریک',
                      }.entries)
                        ChoiceChip(
                          selected: appState.themeMode == entry.key,
                          onSelected: (_) => appState.setThemeMode(entry.key),
                          label: Text(entry.value),
                        ),
                    ],
                  ),
                ),
              ),
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
              ListTile(
                leading: const Icon(Icons.alarm_on_outlined, color: kPrimary),
                title: const Text('آزمایش آلارم با زنگ'),
                subtitle: const Text('باید با صدای زنگ و لرزش نمایش داده شود'),
                onTap: () async {
                  await NotificationService.requestPermission();
                  await NotificationService.showTest(alarm: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.verified_outlined, color: kPrimary),
                title: const Text('بررسی وضعیت اعلان و آلارم'),
                subtitle: const Text('اگر آلارم دقیق کار نمی‌کند اینجا را ببینید'),
                onTap: () => _diagnostics(context),
              ),
              ListTile(
                leading: const Icon(Icons.event_note_outlined, color: kPrimary),
                title: const Text('تنظیم تاریخ مناسبت‌های قمری'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final o in const [-2, -1, 0, 1, 2])
                        ChoiceChip(
                          selected: appState.hijriOffset == o,
                          onSelected: (_) => appState.setHijriOffset(o),
                          label: Text(o == 0 ? 'پیش‌فرض' : toFa(o > 0 ? '+$o' : '$o')),
                        ),
                    ],
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _group(context, 'اعلان صبحگاهی', [
              SwitchListTile(
                secondary: const Icon(Icons.wb_sunny_outlined, color: kPrimary),
                title: const Text('خلاصه کارهای امروز'),
                subtitle: const Text('هر روز در ساعت دلخواه یک اعلان خلاصه می‌آید'),
                value: appState.morningEnabled,
                onChanged: (on) async {
                  await appState.setMorning(enabled: on);
                  if (on) await NotificationService.requestPermission();
                },
              ),
              ListTile(
                enabled: appState.morningEnabled,
                leading: const Icon(Icons.schedule, color: kPrimary),
                title: const Text('ساعت اعلان'),
                trailing: Text(
                  timeText(
                    DateTime(2000, 1, 1, appState.morningHour, appState.morningMinute),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: appState.morningHour,
                      minute: appState.morningMinute,
                    ),
                  );
                  if (picked != null) {
                    await appState.setMorning(
                      hour: picked.hour,
                      minute: picked.minute,
                    );
                  }
                },
              ),
            ]),
            const SizedBox(height: 14),
            _group(context, 'پشتیبان‌گیری', [
              ListTile(
                leading: const Icon(Icons.copy_all_outlined, color: kPrimary),
                title: const Text('کپی پشتیبان (JSON)'),
                subtitle: const Text(
                  'متن پشتیبان کپی می‌شود؛ آن را در جایی امن (مثلاً پیام‌های ذخیره‌شده) نگه دارید. تصویر و صدا در آن نیست.',
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(ClipboardData(text: appState.exportJson()));
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'پشتیبان ${toFa(appState.tasks.length)} کار کپی شد',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore_outlined, color: kPrimary),
                title: const Text('بازیابی از پشتیبان'),
                subtitle: const Text('متن JSON را بچسبانید'),
                onTap: () => _restore(context),
              ),
            ]),
            const SizedBox(height: 14),
            _group(context, 'داده‌ها', [
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined, color: kPrimary),
                title: const Text('افزودن داده نمونه'),
                subtitle: const Text('برای دیدن ظاهر نمودارها'),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await appState.addSamples();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('داده نمونه اضافه شد')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, color: kPrimary),
                title: const Text('پاک‌کردن کارهای انجام‌شده'),
                onTap: () => _confirmClear(context),
              ),
            ]),
            const SizedBox(height: 14),
            _group(context, 'درباره', [
              ListTile(
                leading: const Icon(Icons.info_outline, color: kPrimary),
                title: const Text('درباره مدیریت زمان'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'مدیریت زمان',
                  applicationVersion: '1.3.0',
                  children: const [
                    Text('اپلیکیشن فارسی مدیریت کارهای روزانه. داده‌ها فقط روی همین دستگاه ذخیره می‌شوند.'),
                  ],
                ),
              ),
            ]),
          ],
        ),
      );

  Widget _group(BuildContext context, String title, List<Widget> children) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
            child: Text(
              title,
              style: const TextStyle(color: kMuted, fontWeight: FontWeight.bold),
            ),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: pal(context).border),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      );

  Future<void> _diagnostics(BuildContext context) async {
    final s = await NotificationService.status();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('وضعیت اعلان‌ها'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.enabled ? '✅ مجوز اعلان فعال است' : '❌ مجوز اعلان داده نشده'),
            const SizedBox(height: 6),
            Text(s.exact ? '✅ آلارم دقیق مجاز است' : '❌ آلارم دقیق مجاز نیست'),
            const SizedBox(height: 12),
            const Text(
              'برای اطمینان از کار کردن وقتی برنامه بسته است، در تنظیمات گوشی بخش باتری، '
              'برنامه «مدیریت زمان» را روی «بدون محدودیت» بگذارید. در بعضی گوشی‌ها '
              '(شیائومی، سامسونگ، هوآوی) باید «شروع خودکار» هم فعال باشد.',
              style: TextStyle(fontSize: 12.5, color: kMuted),
            ),
          ],
        ),
        actions: [
          if (!s.exact)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await NotificationService.requestExactAlarms();
              },
              child: const Text('دادن مجوز آلارم دقیق'),
            ),
          if (!s.enabled)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await NotificationService.requestPermission();
              },
              child: const Text('دادن مجوز اعلان'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

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

  Future<void> _restore(BuildContext context) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    // Result: null = cancel, true = replace all, false = add to existing.
    final replace = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('بازیابی از پشتیبان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 6,
              minLines: 4,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: '{ "app": "DayFlow", ... }',
                border: OutlineInputBorder(),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) controller.text = data!.text!;
                },
                icon: const Icon(Icons.paste),
                label: const Text('چسباندن از کلیپ‌بورد'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('افزودن به موجود‌ها'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('جایگزینی همه'),
          ),
        ],
      ),
    );
    final text = controller.text;
    controller.dispose();
    if (replace == null) return;
    try {
      final added = await appState.importJson(text, replace: replace);
      messenger.showSnackBar(
        SnackBar(content: Text('${toFa(added)} کار بازیابی شد')),
      );
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
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
