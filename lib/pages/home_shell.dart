import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../state/app_state.dart';
import '../widgets/task_tile.dart';
import 'alarm_page.dart';
import '../theme.dart';
import 'add_task_page.dart';
import 'calendar_page.dart';
import 'categories_page.dart';
import 'dashboard_page.dart';
import 'settings_page.dart';
import 'tasks_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  final controllers = List.generate(5, (_) => ScrollController());

  @override
  void initState() {
    super.initState();
    NotificationService.alarmRequests.addListener(_showAlarm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermission();
      _showAlarm();
      WidgetService.listen(_openTask);
    });
  }

  @override
  void dispose() {
    NotificationService.alarmRequests.removeListener(_showAlarm);
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _showAlarm() {
    final info = NotificationService.alarmRequests.value;
    if (info == null || !mounted) return;
    NotificationService.alarmRequests.value = null;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AlarmPage(info: info),
      ),
    );
  }

  /// A task row of the home-screen widget was tapped.
  void _openTask(String id) {
    if (!mounted) return;
    for (final t in appState.tasks) {
      if (t.id == id) {
        showTaskDetails(context, t);
        return;
      }
    }
  }

  /// Tapping the tab that is already open scrolls it back to the top.
  void _onTab(int i) {
    if (i == index) {
      final c = controllers[i];
      if (c.hasClients) {
        c.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      setState(() => index = i);
    }
  }

  static const _items = [
    (Icons.home_rounded, 'داشبورد'),
    (Icons.calendar_month_outlined, 'تقویم'),
    (Icons.checklist_rounded, 'کارها'),
    (Icons.folder_outlined, 'دسته‌بندی‌ها'),
    (Icons.settings_outlined, 'تنظیمات'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: index,
            children: [
              DashboardPage(
                onSeeAll: () => setState(() => index = 2),
                controller: controllers[0],
              ),
              CalendarPage(controller: controllers[1]),
              TasksPage(controller: controllers[2]),
              CategoriesPage(controller: controllers[3]),
              SettingsPage(controller: controllers[4]),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: () => openTaskEditor(context),
          child: const Icon(Icons.add, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: pal(context).card,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _onTab(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: index == i ? pal(context).primarySoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _items[i].$1,
                              color: index == i ? kPrimary : kMuted,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _items[i].$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight:
                                    index == i ? FontWeight.bold : FontWeight.w500,
                                color: index == i ? kPrimary : kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}
