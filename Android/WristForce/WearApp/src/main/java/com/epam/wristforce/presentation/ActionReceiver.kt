package com.epam.wristforce.presentation

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class ActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = when (intent.action) {
            "ACTION_APPROVE" -> "Approve"
            "ACTION_DECLINE" -> "Decline"
            "ACTION_PENDING" -> "Pending"
            else -> return
        }

        val notificationId = intent.getStringExtra("notificationId") ?: return // Get the notification ID

        CoroutineScope(Dispatchers.IO).launch {
            val dataClient = Wearable.getDataClient(context)
            val request = PutDataMapRequest.create("/report_action").apply {
                dataMap.putString("action", action)
                dataMap.putString("notificationId", notificationId)
                dataMap.putLong("timestamp", System.currentTimeMillis())
            }

            try {
                dataClient.putDataItem(request.asPutDataRequest().setUrgent()).await()
                Log.d("ActionReceiver", "Action $action for Notification ID $notificationId sent successfully")
            } catch (e: Exception) {
                Log.e("ActionReceiver", "Failed to send action", e)
            }
        }
    }
}