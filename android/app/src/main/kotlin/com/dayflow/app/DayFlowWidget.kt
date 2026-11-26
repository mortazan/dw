package com.dayflow.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import org.json.JSONArray
import java.util.Calendar
import java.util.Locale

data class WidgetItem(
    val id: String,
    val time: String,
    val title: String,
    val done: Boolean,
    val category: String,
    val color: Int,
)

fun faDigits(text: String): String {
    val digits = "۰۱۲۳۴۵۶۷۸۹"
    val out = StringBuilder()
    for (ch in text) {
        out.append(if (ch in '0'..'9') digits[ch - '0'] else ch)
    }
    return out.toString()
}

/** Home-screen widget listing today's tasks (scrolls when they do not fit). */
class DayFlowWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            manager.updateAppWidget(id, build(context, id))
        }
        manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
    }

    override fun onEnabled(context: Context) {
        refresh(context)
    }

    companion object {
        const val PREFS = "dayflow_widget"

        /** Stores the data sent by the app and redraws every widget. */
        fun store(context: Context, tasks: String?, categories: String?) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString("tasks", tasks ?: "[]")
                .putString("categories", categories ?: "[]")
                .commit()
            refresh(context)
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, DayFlowWidget::class.java))
            if (ids.isEmpty()) return
            for (id in ids) {
                manager.updateAppWidget(id, build(context, id))
            }
            manager.notifyAppWidgetViewDataChanged(ids, R.id.widget_list)
        }

        /** Today's tasks: open ones first, then finished ones, each group by time. */
        fun loadItems(context: Context): List<WidgetItem> {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val colors = HashMap<String, Int>()
            try {
                val cats = JSONArray(prefs.getString("categories", "[]") ?: "[]")
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

            val items = ArrayList<WidgetItem>()
            try {
                val array = JSONArray(prefs.getString("tasks", "[]") ?: "[]")
                for (i in 0 until array.length()) {
                    val task = array.getJSONObject(i)
                    val date = task.optString("date")
                    if (date.startsWith(today)) {
                        val category = task.optString("category")
                        items.add(
                            WidgetItem(
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
            items.sortWith(compareBy<WidgetItem>({ it.done }, { it.time }))
            return items
        }

        private fun build(context: Context, widgetId: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_today)
            val items = loadItems(context)
            views.setTextViewText(
                R.id.widget_subtitle,
                faDigits("${items.count { it.done }} از ${items.size}"),
            )

            // The scrolling list of tasks.
            val service = Intent(context, DayFlowWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            views.setRemoteAdapter(R.id.widget_list, service)
            views.setEmptyView(R.id.widget_list, R.id.widget_empty)

            // Tapping a task opens it in the app (the id is added per row).
            val template = Intent(context, MainActivity::class.java).apply {
                action = "dayflow.OPEN_TASK"
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            val mutable = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            }
            views.setPendingIntentTemplate(
                R.id.widget_list,
                PendingIntent.getActivity(
                    context,
                    1,
                    template,
                    PendingIntent.FLAG_UPDATE_CURRENT or mutable,
                ),
            )

            // The header opens the app.
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launch != null) {
                val pending = PendingIntent.getActivity(
                    context,
                    0,
                    launch,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_title, pending)
                views.setOnClickPendingIntent(R.id.widget_subtitle, pending)
            }
            return views
        }

    }
}
