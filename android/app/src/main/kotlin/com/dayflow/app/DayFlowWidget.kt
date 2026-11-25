package com.dayflow.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar
import java.util.Locale

/** Home-screen widget listing today's tasks. Data is read from Flutter's SharedPreferences. */
class DayFlowWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            manager.updateAppWidget(id, build(context))
        }
    }

    override fun onEnabled(context: Context) {
        refresh(context)
    }

    private data class Item(
        val id: String,
        val time: String,
        val title: String,
        val done: Boolean,
        val category: String,
        val color: Int,
    )

    companion object {
        private const val MAX_ROWS = 5

        private val rows = intArrayOf(
            R.id.widget_row1, R.id.widget_row2, R.id.widget_row3,
            R.id.widget_row4, R.id.widget_row5,
        )
        private val bars = intArrayOf(
            R.id.widget_bar1, R.id.widget_bar2, R.id.widget_bar3,
            R.id.widget_bar4, R.id.widget_bar5,
        )
        private val titles = intArrayOf(
            R.id.widget_title1, R.id.widget_title2, R.id.widget_title3,
            R.id.widget_title4, R.id.widget_title5,
        )
        private val subs = intArrayOf(
            R.id.widget_sub1, R.id.widget_sub2, R.id.widget_sub3,
            R.id.widget_sub4, R.id.widget_sub5,
        )
        private val times = intArrayOf(
            R.id.widget_time1, R.id.widget_time2, R.id.widget_time3,
            R.id.widget_time4, R.id.widget_time5,
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

            // Category name -> color.
            val colors = HashMap<String, Int>()
            try {
                val cats = JSONArray(prefs.getString("flutter.categories", "[]") ?: "[]")
                for (i in 0 until cats.length()) {
                    val c = cats.getJSONObject(i)
                    colors[c.optString("name")] = c.optLong("color").toInt()
                }
            } catch (_: Exception) {
            }

            val now = Calendar.getInstance()
            // Locale.ENGLISH: the default locale could print Persian digits.
            val today = String.format(
                Locale.ENGLISH,
                "%04d-%02d-%02d",
                now.get(Calendar.YEAR),
                now.get(Calendar.MONTH) + 1,
                now.get(Calendar.DAY_OF_MONTH),
            )

            val items = ArrayList<Item>()
            try {
                val array = JSONArray(prefs.getString("flutter.tasks", "[]") ?: "[]")
                for (i in 0 until array.length()) {
                    val task = array.getJSONObject(i)
                    val date = task.optString("date")
                    if (date.startsWith(today)) {
                        val category = task.optString("category")
                        items.add(
                            Item(
                                id = task.optString("id"),
                                time = if (date.length >= 16) date.substring(11, 16) else "",
                                title = task.optString("title"),
                                done = task.optBoolean("done"),
                                category = category,
                                color = colors[category] ?: Color.parseColor("#6C47E8"),
                            ),
                        )
                    }
                }
            } catch (_: Exception) {
            }
            // Open tasks first, then finished ones; each group by time.
            items.sortWith(compareBy<Item>({ it.done }, { it.time }))

            val doneCount = items.count { it.done }
            views.setTextViewText(
                R.id.widget_subtitle,
                faDigits("$doneCount از ${items.size}"),
            )
            views.setViewVisibility(
                R.id.widget_empty,
                if (items.isEmpty()) View.VISIBLE else View.GONE,
            )

            for (index in 0 until MAX_ROWS) {
                if (index < items.size) {
                    val item = items[index]
                    views.setViewVisibility(rows[index], View.VISIBLE)
                    views.setInt(bars[index], "setBackgroundColor", item.color)
                    views.setTextViewText(
                        titles[index],
                        if (item.done) "✓ ${item.title}" else item.title,
                    )
                    views.setTextColor(
                        titles[index],
                        if (item.done) Color.parseColor("#8A88A0") else Color.parseColor("#1E1B3A"),
                    )
                    views.setTextViewText(subs[index], item.category)
                    views.setTextViewText(times[index], faDigits(item.time))
                    views.setOnClickPendingIntent(rows[index], openTask(context, item.id, index + 1))
                } else {
                    views.setViewVisibility(rows[index], View.GONE)
                }
            }

            if (items.size > MAX_ROWS) {
                views.setViewVisibility(R.id.widget_more, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_more,
                    faDigits("و ${items.size - MAX_ROWS} کار دیگر"),
                )
            } else {
                views.setViewVisibility(R.id.widget_more, View.GONE)
            }

            // Tapping the header or empty space opens the app.
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pending = PendingIntent.getActivity(
                    context,
                    0,
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
                views.setOnClickPendingIntent(R.id.widget_title, pending)
            }
            return views
        }

        /** Opens the app on the details of one task. */
        private fun openTask(context: Context, taskId: String, requestCode: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "dayflow.OPEN_TASK"
                data = Uri.parse("dayflow://task/$taskId")
                putExtra("taskId", taskId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
