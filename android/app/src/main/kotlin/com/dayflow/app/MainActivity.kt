package com.dayflow.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets Flutter ask the home-screen widget to redraw after tasks change.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dayflow/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "update") {
                    DayFlowWidget.refresh(applicationContext)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
