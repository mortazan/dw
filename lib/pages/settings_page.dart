import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/notification_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../lock.dart';
import '../widgets/common.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.controller});

  final ScrollController? controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'تنظیمات',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Expanded(
              child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
          children: [
            _group(context, 'عمومی', [
              ListTile(
                leading: Icon(Icons.person_outline, color: kPrimary),
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
                leading: Icon(Icons.chat_bubble_outline, color: kPrimary),
                title: const Text('متن خوش‌آمدگویی'),
                subtitle: Text(appState.greeting),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => editGreeting(context),
              ),
              ListTile(
                leading: Icon(Icons.dark_mode_outlined, color: kPrimary),
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
                leading: Icon(Icons.palette_outlined, color: kPrimary),
                title: const Text('رنگ تم'),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < accentChoices.length; i++)
                        GestureDetector(
                          onTap: () => appState.setAccent(i),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: accentChoices[i].$2,
                              shape: BoxShape.circle,
                              border: appState.accentIndex == i
                                  ? Border.all(color: pal(context).card, width: 3)
                                  : null,
                              boxShadow: appState.accentIndex == i
                                  ? [
                                      BoxShadow(
                                        color: accentChoices[i].$2,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: appState.accentIndex == i
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.notifications_outlined, color: kPrimary),
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
                leading: Icon(Icons.alarm_on_outlined, color: kPrimary),
                title: const Text('آزمایش آلارم با زنگ'),
                subtitle: const Text('باید با صدای زنگ و لرزش نمایش داده شود'),
                onTap: () async {
                  await NotificationService.requestPermission();
                  await NotificationService.showTest(alarm: true);
                },
              ),
              ListTile(
                leading: Icon(Icons.verified_outlined, color: kPrimary),
                title: const Text('بررسی وضعیت اعلان و آلارم'),
                subtitle: const Text('اگر آلارم دقیق کار نمی‌کند اینجا را ببینید'),
                onTap: () => _diagnostics(context),
              ),
              ListTile(
                leading: Icon(Icons.event_note_outlined, color: kPrimary),
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
                secondary: Icon(Icons.wb_sunny_outlined, color: kPrimary),
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
                leading: Icon(Icons.schedule, color: kPrimary),
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
              SwitchListTile(
                secondary: Icon(Icons.nightlight_outlined, color: kPrimary),
                title: const Text('مرور شبانه'),
                subtitle: const Text('هر شب ساعت ۲۱ برای مرور و انتقال کارهای مانده'),
                value: appState.eveningReview,
                onChanged: (v) async {
                  if (v) await NotificationService.requestPermission();
                  await appState.setEveningReview(v);
                },
              ),
            ]),
            const SizedBox(height: 14),
            _group(context, 'پشتیبان‌گیری', [
              ListTile(
                leading: Icon(Icons.save_alt_outlined, color: kPrimary),
                title: const Text('ذخیره پشتیبان در فایل'),
                subtitle: const Text('فایل را در حافظه یا پوشه دلخواه ذخیره کنید'),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final d = DateTime.now();
                  String two(int n) => n.toString().padLeft(2, '0');
                  final name = 'time-manager-${d.year}${two(d.month)}${two(d.day)}.json';
                  final bytes = Uint8List.fromList(utf8.encode(appState.exportJson()));
                  try {
                    final path = await FilePicker.platform.saveFile(
                      dialogTitle: 'ذخیره پشتیبان',
                      fileName: name,
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                      bytes: bytes,
                    );
                    if (path != null) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('فایل پشتیبان ذخیره شد')),
                      );
                    }
                  } catch (_) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('ذخیره فایل انجام نشد')),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.file_open_outlined, color: kPrimary),
                title: const Text('بازیابی از فایل'),
                onTap: () async {
                  final r = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    withData: true,
                  );
                  final bytes = r?.files.single.bytes;
                  if (bytes == null || !context.mounted) return;
                  await _restore(context, initial: utf8.decode(bytes, allowMalformed: true));
                },
              ),
              SwitchListTile(
                secondary: Icon(Icons.event_repeat_outlined, color: kPrimary),
                title: const Text('یادآوری هفتگی پشتیبان'),
                subtitle: const Text('جمعه‌ها ساعت ۱۰ صبح'),
                value: appState.backupReminder,
                onChanged: (v) async {
                  if (v) await NotificationService.requestPermission();
                  await appState.setBackupReminder(v);
                },
              ),
              ListTile(
                leading: Icon(Icons.copy_all_outlined, color: kPrimary),
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
                leading: Icon(Icons.restore_outlined, color: kPrimary),
                title: const Text('بازیابی از پشتیبان'),
                subtitle: const Text('متن JSON را بچسبانید'),
                onTap: () => _restore(context),
              ),
            ]),
            const SizedBox(height: 14),
            _group(context, 'امنیت', [
              ListTile(
                leading: Icon(
                  appState.pinHash == null ? Icons.lock_open_outlined : Icons.lock_outline,
                  color: kPrimary,
                ),
                title: Text(
                  appState.pinHash == null ? 'تنظیم قفل برنامه' : 'غیرفعال کردن قفل برنامه',
                ),
                subtitle: const Text('رمز ۴ رقمی هنگام باز کردن برنامه'),
                onTap: () => appState.pinHash == null ? _setPin(context) : _removePin(context),
              ),
            ]),
            const SizedBox(height: 14),
            _group(context, 'داده‌ها', [
              ListTile(
                leading: Icon(Icons.auto_awesome_outlined, color: kPrimary),
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
                leading: Icon(Icons.cleaning_services_outlined, color: kPrimary),
                title: const Text('پاک‌کردن کارهای انجام‌شده'),
                onTap: () => _confirmClear(context),
              ),
            ]),
            const SizedBox(height: 14),
            _group(context, 'درباره', [
              ListTile(
                leading: Icon(Icons.info_outline, color: kPrimary),
                title: const Text('درباره مدیریت زمان'),
                onTap: () => _showAbout(context),
              ),
            ]),
          ],
        ),
            ),
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

  Future<void> _showAbout(BuildContext context) => showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary, Color(0xFF9B7BFF)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 14),
                const Text(
                  'مدیریت زمان',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'نسخه ${toFa('2.1.0')}',
                  style: const TextStyle(color: kMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 14),
                const Text(
                  'برنامه مدیریت کارهای روزانه',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.7, fontSize: 14),
                ),
                const SizedBox(height: 18),
                Divider(color: pal(context).border),
                const SizedBox(height: 10),
                const Text('طراح و برنامه‌نویس', style: TextStyle(color: kMuted, fontSize: 12)),
                const SizedBox(height: 4),
                const Text(
                  'مرتضی حیدری',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => launchUrl(
                    Uri.parse('https://t.me/MH0814'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF229ED9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'پیام در تلگرام',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('بستن'),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _setPin(BuildContext context) async {
    final a = TextEditingController();
    final b = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تنظیم رمز ۴ رقمی'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: a,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(labelText: 'رمز'),
              ),
              TextField(
                controller: b,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: InputDecoration(labelText: 'تکرار رمز', errorText: error),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                if (!RegExp(r'^\d{4}$').hasMatch(a.text) || a.text != b.text) {
                  setState(() => error = 'رمز باید ۴ رقم و دو بار یکسان باشد');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await appState.setPinHash(pinHashOf(a.text));
    a.dispose();
    b.dispose();
  }

  Future<void> _removePin(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رمز فعلی را وارد کنید'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, pinHashOf(c.text) == appState.pinHash),
            child: const Text('غیرفعال کن'),
          ),
        ],
      ),
    );
    c.dispose();
    if (ok == true) await appState.setPinHash(null);
  }

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

  Future<void> _restore(BuildContext context, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
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
