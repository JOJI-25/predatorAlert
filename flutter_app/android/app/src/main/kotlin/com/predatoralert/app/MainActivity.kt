package com.predatoralert.app

import android.content.Intent
import android.os.Bundle
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.predatoralert.app/alert"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAlert" -> {
                    // Wake up screen and show app
                    wakeUpAndShow()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Make sure window shows over lock screen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
        )
        
        // Check if launched from predator alert
        if (intent?.getBooleanExtra("predator_alert", false) == true) {
            wakeUpAndShow()
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // Handle when app is already running and receives alert intent
        if (intent.getBooleanExtra("predator_alert", false)) {
            wakeUpAndShow()
        }
    }
    
    private fun wakeUpAndShow() {
        // Wake up the device
        val powerManager = getSystemService(POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "predatoralert:alertwake"
        )
        wakeLock.acquire(30000)  // 30 seconds
        
        // Make sure window is visible
        window.addFlags(
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
        
        // Release wake lock after delay
        android.os.Handler(mainLooper).postDelayed({
            if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }, 10000)
    }
}
