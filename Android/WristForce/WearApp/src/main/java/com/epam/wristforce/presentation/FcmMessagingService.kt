package com.epam.wristforce.presentation

import android.Manifest
import android.R
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresPermission
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class FcmMessagingService : FirebaseMessagingService() {

    override fun onCreate() {
        super.onCreate()
        // Fetch the FCM token when the service starts
        fetchFcmToken()
    }

    @RequiresPermission(Manifest.permission.POST_NOTIFICATIONS)
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "Received FCM message: ${remoteMessage.messageId}")

        // Extract notification type and data
        val notificationType = remoteMessage.data["type"] ?: "unknown"

        // Handle different notification types
        when (notificationType) {
            "approval" -> {
                val actions = remoteMessage.data["actions"]?.split(",") ?: listOf("Approve", "Reject", "Pending")
                val notificationId = remoteMessage.data["notificationId"]
                showApprovalNotification(
                    title = remoteMessage.notification?.title ?: "Approval Request",
                    body = remoteMessage.notification?.body ?: "You have a new action to take.",
                    notificationId = notificationId,
                    actions = actions
                )
            }
            "reminder" -> {
                showReminderNotification(
                    title = remoteMessage.notification?.title ?: "Reminder",
                    body = remoteMessage.notification?.body ?: "Don't miss this event.",
                )
            }
            else -> {
                Log.w(TAG, "Unknown notification type received.")
            }
        }
    }

    // Method to show approval notification with actions
    @RequiresPermission(Manifest.permission.POST_NOTIFICATIONS)
    private fun showApprovalNotification(title: String, body: String, notificationId: String?, actions: List<String>) {
        if (actions.isEmpty()) {
            Log.e(TAG, "No actions provided for approval notification!")
            return
        }

        val approveIntent = Intent(this, ActionReceiver::class.java).apply {
            action = "ACTION_APPROVE"
            putExtra("notificationId", notificationId)
        }

        val rejectIntent = Intent(this, ActionReceiver::class.java).apply {
            action = "ACTION_DECLINE"
            putExtra("notificationId", notificationId)
        }

        val pendingIntent = Intent(this, ActionReceiver::class.java).apply {
            action = "ACTION_PENDING"
            putExtra("notificationId", notificationId)
        }

        val approvePendingIntent = PendingIntent.getBroadcast(this, 0, approveIntent, PendingIntent.FLAG_IMMUTABLE)
        val rejectPendingIntent = PendingIntent.getBroadcast(this, 1, rejectIntent, PendingIntent.FLAG_IMMUTABLE)
        val pendingPendingIntent = PendingIntent.getBroadcast(this, 2, pendingIntent, PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, "report_channel")
            .setSmallIcon(R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .apply {
                if (actions.size > 0) addAction(NotificationCompat.Action(0, actions[0], approvePendingIntent))
                if (actions.size > 1) addAction(NotificationCompat.Action(0, actions[1], rejectPendingIntent))
                if (actions.size > 2) addAction(NotificationCompat.Action(0, actions[2], pendingPendingIntent))
            }
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(this).notify(notificationId?.hashCode() ?: System.currentTimeMillis().toInt(), notification)
    }

    // Method to show reminder notification
    @RequiresPermission(Manifest.permission.POST_NOTIFICATIONS)
    private fun showReminderNotification(title: String, body: String) {
        val notification = NotificationCompat.Builder(this, "report_channel")
            .setSmallIcon(R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(this).notify((title + body).hashCode(), notification)
    }


    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM Token: $token")
        // Optionally send the token to your server
        saveTokenToFirestore(token)
    }

    private fun fetchFcmToken() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val token = FirebaseMessaging.getInstance().token.await()
                Log.d(TAG, "FCM Token: $token")
                // Optionally send the token to your server
                saveTokenToFirestore(token)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to fetch FCM token", e)
            }
        }
    }

    private fun saveTokenToFirestore(token: String) {
        // Get an instance of Firestore
        val firestore = FirebaseFirestore.getInstance()

        // Construct the device information
        val deviceName = "${Build.MANUFACTURER} ${Build.MODEL}" // Eg: "Samsung Galaxy S10"
        val deviceInfo = mapOf(
            "device_name" to deviceName,
            "fcm_token" to token,
            "timestamp" to System.currentTimeMillis() // Optional: Adds a timestamp
        )

        // Save the token in Firestore under the 'device_tokens' collection
        val collectionName = "device_tokens"
        val documentName = deviceName.replace(" ", "_") // Use device name as the document ID

        firestore.collection(collectionName)
            .document(documentName) // Creates/updates the document with device-specific ID
            .set(deviceInfo) // Write the device info
            .addOnSuccessListener {
                Log.d(TAG, "FCM token successfully saved in Firestore for device $deviceName")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to save FCM token to Firestore for device $deviceName", e)
            }
    }

    companion object {
        private const val TAG = "FcmMessagingService"
    }
}
