package com.dayflow.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar

/** Home-screen widget listing today's tasks. Data is read from Flutter's SharedPreferences. */
class DayFlowWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            manager.updateAppWidget(id, build(context))
        }
    }

    companion object {
        private val rows = intArrayOf(
            R.id.widget_row1, R.id.widget_row2, R.id.widget_row3,
            R.id.widget_row4, R.id.widget_row5,
        )

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, DayFlowWidget::class.java))
            for (id in ids) {
                manager.updateAppWidget(id, build(context))
            }
        }

        private fun faDigits(text: String): String {
            val digits = "۰۱۲۳۴۵۶۷۸۹"
            val out = StringBuilder()
            for (ch in text) {
                out.append(if (ch in '0'..'9') digits[ch - '0'] else ch)
            }
            return out.toString()
        }

        private fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_today)

            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val raw = prefs.getString("flutter.tasks", "[]") ?: "[]"

            val now = Calendar.getInstance()
            val today = String.format(
                "%04d-%02d-%02d",
                now.get(Calendar.YEAR),
                now.get(Calendar.MONTH) + 1,
                now.get(Calendar.DAY_OF_MONTH),
            )

            // (time, title, done) for today's tasks.
            val items = ArrayList<Triple<String, String, Boolean>>()
            try {
                val array = JSONArray(raw)
                for (i in 0 until array.length()) {
                    val task = array.getJSONObject(i)
                    val date = task.optString("date")
                    if (date.startsWith(today)) {
                        val time = if (date.length >= 16) date.substring(11, 16) else ""
                        items.add(Triple(time, task.optString("title"), task.optBoolean("done")))
                    }
                }
            } catch (_: Exception) {
            }
            items.sortBy { it.first }

            val doneCount = items.count { it.third }
            views.setTextViewText(
                R.id.widget_subtitle,
                faDigits("$doneCount از ${items.size} کار انجام شده"),
            )

            for ((index, rowId) in rows.withIndex()) {
                if (index < items.size) {
                    val (time, title, done) = items[index]
                    val mark = if (done) "✓" else "•"
                    views.setTextViewText(rowId, faDigits("$mark $time  $title"))
                    views.setViewVisibility(rowId, android.view.View.VISIBLE)
                } else if (index == 0) {
                    views.setTextViewText(rowId, "برای امروز کاری ثبت نشده است")
                    views.setViewVisibility(rowId, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(rowId, android.view.View.GONE)
                }
            }

            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pending = PendingIntent.getActivity(
                    context,
                    0,
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
            }
            return views
        }
    }
}
