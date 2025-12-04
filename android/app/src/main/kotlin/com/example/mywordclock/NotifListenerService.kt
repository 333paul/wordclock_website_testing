package com.example.mywordclock

import android.content.Intent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class NotifListenerService : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        broadcast(activeNotifications.isNotEmpty())
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        broadcast(activeNotifications.isNotEmpty())
    }

    private fun broadcast(has: Boolean) {
        val intent = Intent(ACTION).setPackage(packageName).putExtra(EXTRA_HAS, has)
        sendBroadcast(intent)
    }

    companion object {
        const val ACTION = "com.example.mywordclock.NOTIF_STATUS"
        const val EXTRA_HAS = "has"
    }
}
