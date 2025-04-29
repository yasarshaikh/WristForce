package com.epam.wristforce.presentation

import android.app.Application
import android.util.Log
import com.google.firebase.FirebaseApp

class WearApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        NotificationUtils.createNotificationChannel(this)
        try {
            FirebaseApp.initializeApp(this)
            Log.d("WearApplication", "Firebase initialized successfully")
        } catch (e: Exception) {
            Log.e("WearApplication", "Firebase initialization failed", e)
        }
    }
}