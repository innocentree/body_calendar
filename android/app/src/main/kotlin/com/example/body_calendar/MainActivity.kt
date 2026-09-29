package com.example.body_calendar

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.os.SystemClock
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var overlayChannel: MethodChannel? = null
    private var pendingOpenTimerRequest = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingOpenTimerRequest =
            pendingOpenTimerRequest || intent?.getBooleanExtra(EXTRA_OPEN_TIMER, false) == true
        overlayChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).also { channel ->
            channel.setMethodCallHandler(::handleOverlayMethodCall)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_OPEN_TIMER, false)) {
            pendingOpenTimerRequest = true
            notifyDartToOpenTimer()
        }
    }

    override fun onResume() {
        super.onResume()
        if (RestTimerOverlayService.hasActiveTimer(this) && isOverlayPermissionGranted()) {
            requestNotificationPermissionBestEffort()
        }
    }

    private fun handleOverlayMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isPermissionGranted" -> result.success(isOverlayPermissionGranted())
                "getSnapshot" -> result.success(RestTimerOverlayService.getSnapshot(this))
                "requestPermission" -> {
                    if (!isOverlayPermissionGranted() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val permissionIntent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName"),
                        )
                        startActivity(permissionIntent)
                    }
                    result.success(isOverlayPermissionGranted())
                }
                "start", "update", "resume" -> {
                    startOrUpdateTimer(call, result)
                }
                "pause" -> {
                    sendTimerCommand(RestTimerOverlayService.ACTION_PAUSE) {
                        putExtra(
                            RestTimerOverlayService.EXTRA_INITIAL_DURATION,
                            call.intArgument("initialDuration"),
                        )
                        putExtra(
                            RestTimerOverlayService.EXTRA_REMAINING_TIME,
                            call.intArgument("remainingTime"),
                        )
                    }
                    result.success(null)
                }
                "stop" -> {
                    if (RestTimerOverlayService.hasActiveTimer(this)) {
                        sendTimerCommand(RestTimerOverlayService.ACTION_STOP)
                    }
                    result.success(null)
                }
                "setAppVisible" -> {
                    if (RestTimerOverlayService.hasActiveTimer(this)) {
                        sendTimerCommand(RestTimerOverlayService.ACTION_SET_APP_VISIBLE) {
                            putExtra(
                                RestTimerOverlayService.EXTRA_APP_VISIBLE,
                                call.argument<Boolean>("visible") ?: true,
                            )
                        }
                    }
                    result.success(null)
                }
                "consumeOpenTimerRequest" -> {
                    val shouldOpen = pendingOpenTimerRequest
                    pendingOpenTimerRequest = false
                    intent?.removeExtra(EXTRA_OPEN_TIMER)
                    result.success(shouldOpen)
                }
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            result.error("REST_TIMER_OVERLAY", error.message, null)
        }
    }

    private fun startOrUpdateTimer(call: MethodCall, result: MethodChannel.Result) {
        val expiresAtEpochMs = call.longArgument("expiresAtEpochMs")
        val remainingFromWallClock =
            (expiresAtEpochMs - System.currentTimeMillis()).coerceAtLeast(0L)
        val deadlineElapsedRealtime = SystemClock.elapsedRealtime() + remainingFromWallClock
        val action = when (call.method) {
            "start" -> RestTimerOverlayService.ACTION_START
            "resume" -> RestTimerOverlayService.ACTION_RESUME
            else -> RestTimerOverlayService.ACTION_UPDATE
        }
        val serviceIntent = Intent(this, RestTimerOverlayService::class.java).apply {
            this.action = action
            putExtra(
                RestTimerOverlayService.EXTRA_INITIAL_DURATION,
                call.intArgument("initialDuration"),
            )
            putExtra(
                RestTimerOverlayService.EXTRA_REMAINING_TIME,
                call.intArgument("remainingTime"),
            )
            putExtra(
                RestTimerOverlayService.EXTRA_DEADLINE_ELAPSED_REALTIME,
                deadlineElapsedRealtime,
            )
            if (action == RestTimerOverlayService.ACTION_START) {
                putExtra(RestTimerOverlayService.EXTRA_APP_VISIBLE, true)
            }
            putExtra(
                RestTimerOverlayService.EXTRA_EXERCISE_NAME,
                call.argument<String>("exerciseName"),
            )
            putExtra(
                RestTimerOverlayService.EXTRA_SELECTED_DATE_EPOCH_MS,
                call.longArgument("selectedDateEpochMs"),
            )
            putExtra(
                RestTimerOverlayService.EXTRA_OWNER_ID,
                call.argument<String>("ownerId"),
            )
            putExtra(
                RestTimerOverlayService.EXTRA_GROUP_ID,
                call.argument<String>("groupId"),
            )
            putExtra(
                RestTimerOverlayService.EXTRA_SESSION_INDEX,
                call.optionalIntArgument("sessionIndex"),
            )
            putExtra(
                RestTimerOverlayService.EXTRA_RECORD_DAY,
                call.optionalIntArgument("recordDay"),
            )
        }
        if (action == RestTimerOverlayService.ACTION_START) {
            ContextCompat.startForegroundService(this, serviceIntent)
            if (isOverlayPermissionGranted()) requestNotificationPermissionBestEffort()
        } else {
            startService(serviceIntent)
        }
        result.success(null)
    }

    private fun sendTimerCommand(
        action: String,
        configure: Intent.() -> Unit = {},
    ) {
        startService(
            Intent(this, RestTimerOverlayService::class.java).apply {
                this.action = action
                configure()
            },
        )
    }

    private fun isOverlayPermissionGranted(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
    }

    private fun requestNotificationPermissionBestEffort() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val preferences = getSharedPreferences(ACTIVITY_PREFERENCES_NAME, MODE_PRIVATE)
        if (preferences.getBoolean(KEY_NOTIFICATION_PERMISSION_REQUESTED, false)) return
        preferences.edit().putBoolean(KEY_NOTIFICATION_PERMISSION_REQUESTED, true).apply()
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_PERMISSION_REQUEST_CODE,
        )
    }

    private fun notifyDartToOpenTimer() {
        val channel = overlayChannel ?: return
        channel.invokeMethod("openTimer", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (result == true) {
                    pendingOpenTimerRequest = false
                    intent?.removeExtra(EXTRA_OPEN_TIMER)
                }
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = Unit

            override fun notImplemented() = Unit
        })
    }

    private fun MethodCall.intArgument(name: String): Int {
        return (argument<Number>(name)?.toInt() ?: 0).coerceAtLeast(0)
    }

    private fun MethodCall.longArgument(name: String): Long {
        return argument<Number>(name)?.toLong() ?: 0L
    }

    private fun MethodCall.optionalIntArgument(name: String): Int {
        return argument<Number>(name)?.toInt() ?: -1
    }

    companion object {
        const val CHANNEL_NAME = "body_calendar/rest_timer_overlay"
        const val EXTRA_OPEN_TIMER = "body_calendar.open_rest_timer"
        private const val ACTIVITY_PREFERENCES_NAME = "rest_timer_overlay_activity"
        private const val KEY_NOTIFICATION_PERMISSION_REQUESTED =
            "notificationPermissionRequested"
        private const val NOTIFICATION_PERMISSION_REQUEST_CODE = 4109
    }
}
