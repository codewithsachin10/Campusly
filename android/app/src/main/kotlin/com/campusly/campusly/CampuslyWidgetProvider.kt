package com.campusly.campusly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class CampuslyWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val ongoingTitle = widgetData.getString("ongoing_title", "No Ongoing Class")
                val ongoingRoom = widgetData.getString("ongoing_room", "Relax or review your notes ✨")
                val nextTitle = widgetData.getString("next_title", "No Upcoming Class")
                val nextRoom = widgetData.getString("next_room", "Have a great day ahead! 🌟")

                setTextViewText(R.id.widget_ongoing_title, ongoingTitle)
                setTextViewText(R.id.widget_ongoing_room, ongoingRoom)
                setTextViewText(R.id.widget_next_title, nextTitle)
                setTextViewText(R.id.widget_next_room, nextRoom)

                val pendingIntentWithData = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_ongoing_title, pendingIntentWithData)
                setOnClickPendingIntent(R.id.widget_next_title, pendingIntentWithData)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
