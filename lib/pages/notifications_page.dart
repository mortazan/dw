import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

Future<void> showNotificationsSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: pal(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) => ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final overdue = appState.overdue;
            final reminders = appState.upcomingReminders;
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'اعلان‌ها',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                if (overdue.isEmpty && reminders.isEmpty)
                  const EmptyState('اعلان جدیدی وجود ندارد'),
                if (overdue.isNotEmpty) ...[
                  const Text(
                    'کارهای به تعویق افتاده',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => appState.moveOverdue(0),
                          icon: const Icon(Icons.today_outlined, size: 18),
                          label: const Text('همه به امروز'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => appState.moveOverdue(1),
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: const Text('همه به فردا'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final t in overdue) TaskTile(task: t, showDate: true),
                ],
                if (reminders.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'یادآورهای پیش‌رو',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final t in reminders) TaskTile(task: t, showDate: true),
                ],
              ],
            );
          },
        ),
      ),
    );
