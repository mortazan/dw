package com.dayflow.app

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import android.widget.RemoteViewsService

/** Supplies the rows of the widget's scrolling list. */
class DayFlowWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Factory(private val context: Context) : RemoteViewsFactory {
        private var items: List<WidgetItem> = emptyList()

        override fun onCreate() {}

        override fun onDataSetChanged() {
            items = DayFlowWidget.loadItems(context)
        }

        override fun onDestroy() {}

        override fun getCount(): Int = items.size

        override fun getViewAt(position: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_item)
            if (position >= items.size) return views
            val item = items[position]
            views.setInt(R.id.widget_bar, "setBackgroundColor", item.color)
            views.setTextViewText(
                R.id.widget_item_title,
                if (item.done) "✓ ${item.title}" else item.title,
            )
            views.setTextColor(
                R.id.widget_item_title,
                if (item.done) Color.parseColor("#8A88A0") else Color.parseColor("#1E1B3A"),
            )
            views.setTextViewText(R.id.widget_item_sub, item.category)
            views.setTextViewText(R.id.widget_item_time, faDigits(item.time))
            views.setOnClickFillInIntent(
                R.id.widget_item_root,
                Intent().putExtra("taskId", item.id),
            )
            return views
        }

        override fun getLoadingView(): RemoteViews? = null

        override fun getViewTypeCount(): Int = 1

        override fun getItemId(position: Int): Long = position.toLong()

        override fun hasStableIds(): Boolean = false
    }
}
