import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'theme.dart';

/// A small, stable hash for the screen-lock PIN (not meant for real secrets).
String pinHashOf(String pin) {
  var h = 0xcbf29ce484222325;
  for (final c in 'dayflow:$pin'.codeUnits) {
    h ^= c;
    h = (h * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return h.toRadixString(16);
}

/// Shows a PIN screen over the app when a PIN is set, at start and after the
/// app was in the background for a while.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  bool locked = appState.pinHash != null;
  DateTime? leftAt;
  String entered = '';
  bool wrong = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      leftAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = leftAt;
      leftAt = null;
      if (appState.pinHash != null &&
          away != null &&
          DateTime.now().difference(away).inSeconds > 20) {
        setState(() {
          locked = true;
          entered = '';
        });
      }
    }
  }

  void _press(String d) {
    if (entered.length >= 4) return;
    setState(() {
      entered += d;
      wrong = false;
    });
    if (entered.length == 4) {
      if (pinHashOf(entered) == appState.pinHash) {
        setState(() {
          locked = false;
          entered = '';
        });
      } else {
        setState(() {
          wrong = true;
          entered = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          widget.child,
          if (locked && appState.pinHash != null)
            Positioned.fill(
              child: Material(
                color: pal(context).bg,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: 48, color: kPrimary),
                      const SizedBox(height: 14),
                      Text(
                        wrong ? 'رمز اشتباه است' : 'رمز برنامه را وارد کنید',
                        style: TextStyle(
                          fontSize: 16,
                          color: wrong ? const Color(0xFFE5484D) : null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 4; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < entered.length ? kPrimary : Colors.transparent,
                                border: Border.all(color: kPrimary, width: 2),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      for (final row in const [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                        ['', '0', '<'],
                      ])
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final k in row)
                              Padding(
                                padding: const EdgeInsets.all(6),
                                child: SizedBox(
                                  width: 74,
                                  height: 64,
                                  child: k.isEmpty
                                      ? null
                                      : TextButton(
                                          style: TextButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            backgroundColor: pal(context).card,
                                          ),
                                          onPressed: () => k == '<'
                                              ? setState(() {
                                                  if (entered.isNotEmpty) {
                                                    entered = entered.substring(
                                                      0,
                                                      entered.length - 1,
                                                    );
                                                  }
                                                })
                                              : _press(k),
                                          child: k == '<'
                                              ? const Icon(Icons.backspace_outlined)
                                              : Text(
                                                  k,
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
}
