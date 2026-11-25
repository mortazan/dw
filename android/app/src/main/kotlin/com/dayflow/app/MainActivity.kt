package com.dayflow.app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingContact: MethodChannel.Result? = null
    private var widgetChannel: MethodChannel? = null
    private var pendingTask: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) {
            pendingTask = intent?.getStringExtra("taskId")
        }
    }

    // A task row of the home-screen widget was tapped while the app is open.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val id = intent.getStringExtra("taskId")
        if (id != null) {
            val channel = widgetChannel
            if (channel != null) {
                channel.invokeMethod("openTask", id)
            } else {
                pendingTask = id
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Lets Flutter ask the home-screen widget to redraw after tasks change.
        widgetChannel = MethodChannel(messenger, "dayflow/widget")
        widgetChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    DayFlowWidget.refresh(applicationContext)
                    result.success(null)
                }
                "takeTask" -> {
                    result.success(pendingTask)
                    pendingTask = null
                }
                else -> result.notImplemented()
            }
        }

        // Installed apps: list them and launch one by package name.
        MethodChannel(messenger, "dayflow/apps").setMethodCallHandler { call, result ->
            when (call.method) {
                "list" -> {
                    val main = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
                    val apps = packageManager.queryIntentActivities(main, 0)
                        .map {
                            mapOf(
                                "name" to it.loadLabel(packageManager).toString(),
                                "package" to it.activityInfo.packageName,
                            )
                        }
                        .filter { it["package"] != packageName }
                        .distinctBy { it["package"] }
                        .sortedBy { it["name"]?.lowercase() }
                    result.success(apps)
                }
                "launch" -> {
                    val pkg = call.arguments as? String
                    val launch = if (pkg == null) null else packageManager.getLaunchIntentForPackage(pkg)
                    if (launch == null) {
                        result.success(false)
                    } else {
                        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(launch)
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Picks a phone number with the system contact picker (no permission needed).
        MethodChannel(messenger, "dayflow/contacts").setMethodCallHandler { call, result ->
            if (call.method == "pick") {
                pendingContact?.success(null)
                pendingContact = result
                val intent = Intent(
                    Intent.ACTION_PICK,
                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                )
                startActivityForResult(intent, CONTACT_REQUEST)
            } else {
                result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CONTACT_REQUEST) return
        val result = pendingContact
        pendingContact = null
        var answer: Map<String, String>? = null
        val uri = data?.data
        if (resultCode == Activity.RESULT_OK && uri != null) {
            val columns = arrayOf(
                ContactsContract.CommonDataKinds.Phone.NUMBER,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            )
            contentResolver.query(uri, columns, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    answer = mapOf(
                        "phone" to (cursor.getString(0) ?: ""),
                        "name" to (cursor.getString(1) ?: ""),
                    )
                }
            }
        }
        result?.success(answer)
    }

    companion object {
        private const val CONTACT_REQUEST = 4711
    }
}
