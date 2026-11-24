package com.dayflow.app

import android.app.Activity
import android.content.Intent
import android.provider.ContactsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingContact: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Lets Flutter ask the home-screen widget to redraw after tasks change.
        MethodChannel(messenger, "dayflow/widget").setMethodCallHandler { call, result ->
            if (call.method == "update") {
                DayFlowWidget.refresh(applicationContext)
                result.success(null)
            } else {
                result.notImplemented()
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
