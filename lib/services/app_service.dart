import 'package:flutter/services.dart';

/// An installed app the user can pick (Android only).
class InstalledApp {
  const InstalledApp(this.name, this.package);

  final String name;
  final String package;
}

class AppService {
  AppService._();

  static const _channel = MethodChannel('dayflow/apps');

  /// Value stored in a link field when an app is chosen: `app:<package>|<name>`.
  static String encode(InstalledApp app) => 'app:${app.package}|${app.name}';

  static bool isApp(String value) => value.startsWith('app:');

  static String nameOf(String value) {
    final rest = value.substring(4);
    final i = rest.indexOf('|');
    return i < 0 ? rest : rest.substring(i + 1);
  }

  static String packageOf(String value) {
    final rest = value.substring(4);
    final i = rest.indexOf('|');
    return i < 0 ? rest : rest.substring(0, i);
  }

  static Future<List<InstalledApp>> list() async {
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>('list');
      return [
        for (final m in raw ?? const <Map<Object?, Object?>>[])
          InstalledApp('${m['name']}', '${m['package']}'),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> launch(String package) async {
    try {
      return await _channel.invokeMethod<bool>('launch', package) ?? false;
    } catch (_) {
      return false;
    }
  }
}
