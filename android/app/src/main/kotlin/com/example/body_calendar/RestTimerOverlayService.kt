package com.example.body_calendar

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.Locale
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.hypot

class RestTimerOverlayService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var windowManager: WindowManager
    private var overlayView: TextView? = null
    private var timerActive = false
    private var paused = false
    private var appVisible = true
    private var initialDuration = 0
    private var pausedRemaining = 0
    private var deadlineElapsedRealtime = 0L
    private var lastDisplayedRemaining = -1
    private var exerciseName = ""
    private var selectedDateEpochMs = 0L
    private var ownerId: String? = null
    private var groupId: String? = null
    private var sessionIndex = -1
    private var recordDay = -1

    private val timerTick = object : Runnable {
        override fun run() {
            if (!timerActive || paused) return
            val remaining = remainingSeconds()
            if (remaining <= 0) {
                finishTimer()
                return
            }
            updateSurfaces(remaining)
            handler.postDelayed(this, TICK_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            if (!restoreState()) {
                stopSelf()
                return START_NOT_STICKY
            }
            if (!ensureForeground(currentRemaining())) return START_NOT_STICKY
            refreshTimer()
            refreshOverlayVisibility()
            return START_STICKY
        }

        when (intent.action) {
            ACTION_START, ACTION_UPDATE, ACTION_RESUME -> {
                timerActive = true
                paused = false
                initialDuration = intent.getIntExtra(EXTRA_INITIAL_DURATION, initialDuration)
                pausedRemaining = intent.getIntExtra(EXTRA_REMAINING_TIME, pausedRemaining)
                deadlineElapsedRealtime = intent.getLongExtra(
                    EXTRA_DEADLINE_ELAPSED_REALTIME,
                    SystemClock.elapsedRealtime() + pausedRemaining * 1_000L,
                )
                if (intent.hasExtra(EXTRA_APP_VISIBLE)) {
                    appVisible = intent.getBooleanExtra(EXTRA_APP_VISIBLE, true)
                }
                exerciseName = intent.getStringExtra(EXTRA_EXERCISE_NAME) ?: ""
                selectedDateEpochMs = intent.getLongExtra(EXTRA_SELECTED_DATE_EPOCH_MS, 0L)
                ownerId = intent.getStringExtra(EXTRA_OWNER_ID)
                groupId = intent.getStringExtra(EXTRA_GROUP_ID)
                sessionIndex = intent.getIntExtra(EXTRA_SESSION_INDEX, -1)
                recordDay = intent.getIntExtra(EXTRA_RECORD_DAY, -1)
                saveState()
                if (!ensureForeground(currentRemaining())) return START_NOT_STICKY
                refreshTimer()
                refreshOverlayVisibility()
            }
            ACTION_PAUSE -> {
                if (!timerActive && !restoreState()) return START_NOT_STICKY
                paused = true
                initialDuration = intent.getIntExtra(EXTRA_INITIAL_DURATION, initialDuration)
                pausedRemaining = intent.getIntExtra(EXTRA_REMAINING_TIME, currentRemaining())
                handler.removeCallbacks(timerTick)
                saveState()
                if (!ensureForeground(pausedRemaining)) return START_NOT_STICKY
                updateSurfaces(pausedRemaining)
                refreshOverlayVisibility()
            }
            ACTION_SET_APP_VISIBLE -> {
                if (!timerActive && !restoreState()) return START_NOT_STICKY
                appVisible = intent.getBooleanExtra(EXTRA_APP_VISIBLE, true)
                saveState()
                if (!ensureForeground(currentRemaining())) return START_NOT_STICKY
                refreshTimer()
                refreshOverlayVisibility()
            }
            ACTION_STOP -> {
                stopTimer(clearSavedState = true)
                return START_NOT_STICKY
            }
            else -> {
                if (!restoreState()) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                if (!ensureForeground(currentRemaining())) return START_NOT_STICKY
                refreshTimer()
                refreshOverlayVisibility()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(timerTick)
        removeOverlay()
        super.onDestroy()
    }

    private fun refreshTimer() {
        handler.removeCallbacks(timerTick)
        if (paused) {
            updateSurfaces(pausedRemaining)
            return
        }
        val remaining = remainingSeconds()
        if (remaining <= 0) {
            finishTimer()
            return
        }
        updateSurfaces(remaining)
        handler.postDelayed(timerTick, TICK_INTERVAL_MS)
    }

    private fun remainingSeconds(): Int {
        val remainingMs = (deadlineElapsedRealtime - SystemClock.elapsedRealtime()).coerceAtLeast(0L)
        return ceil(remainingMs / 1_000.0).toInt()
    }

    private fun currentRemaining(): Int = if (paused) pausedRemaining else remainingSeconds()

    private fun updateSurfaces(remaining: Int) {
        if (remaining == lastDisplayedRemaining) return
        lastDisplayedRemaining = remaining
        overlayView?.text = timerText(remaining)
        val notificationManager =
            getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        try {
            notificationManager.notify(NOTIFICATION_ID, buildNotification(remaining))
        } catch (_: SecurityException) {
            // Android 13+ may hide notifications when the user denies permission.
        }
    }

    private fun ensureForeground(remaining: Int): Boolean {
        val notification = buildNotification(remaining)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            return true
        } catch (_: SecurityException) {
            timerActive = false
            handler.removeCallbacks(timerTick)
            removeOverlay()
            getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE).edit().clear().apply()
            stopSelf()
            return false
        }
    }

    private fun buildNotification(remaining: Int): Notification {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            putExtra(MainActivity.EXTRA_OPEN_TIMER, true)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            OPEN_TIMER_REQUEST_CODE,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("펌핑데이 휴식 타이머")
            .setContentText(formatDuration(remaining))
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "휴식 타이머",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "운동 중 휴식 타이머를 백그라운드에서 유지합니다."
            setShowBadge(false)
        }
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager)
            .createNotificationChannel(channel)
    }

    private fun refreshOverlayVisibility() {
        if (!timerActive || appVisible || !canDrawOverlay()) {
            removeOverlay()
            return
        }
        showOverlay()
    }

    private fun canDrawOverlay(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun showOverlay() {
        if (overlayView != null) {
            updateSurfaces(currentRemaining())
            return
        }

        val pill = TextView(this).apply {
            text = timerText(currentRemaining())
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            minHeight = dp(48)
            setPadding(dp(18), dp(10), dp(18), dp(10))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(24).toFloat()
                setColor(Color.rgb(0, 122, 255))
                setStroke(dp(1), Color.argb(46, 255, 255, 255))
            }
            elevation = dp(8).toFloat()
        }
        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = dp(12)
            y = dp(52)
        }
        attachDragAndTapListener(pill, params)

        try {
            windowManager.addView(pill, params)
            overlayView = pill
        } catch (_: Exception) {
            overlayView = null
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun attachDragAndTapListener(
        view: View,
        params: WindowManager.LayoutParams,
    ) {
        val touchSlop = ViewConfiguration.get(this).scaledTouchSlop.toFloat()
        var downRawX = 0f
        var downRawY = 0f
        var startX = 0
        var startY = 0
        view.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downRawX = event.rawX
                    downRawY = event.rawY
                    startX = params.x
                    startY = params.y
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val maxX = (resources.displayMetrics.widthPixels - view.width).coerceAtLeast(0)
                    val maxY = (resources.displayMetrics.heightPixels - view.height).coerceAtLeast(0)
                    params.x = (startX - (event.rawX - downRawX).toInt()).coerceIn(0, maxX)
                    params.y = (startY + (event.rawY - downRawY).toInt()).coerceIn(0, maxY)
                    try {
                        windowManager.updateViewLayout(view, params)
                    } catch (_: Exception) {
                        // The service may be stopping while a touch is in progress.
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val distance = hypot(event.rawX - downRawX, event.rawY - downRawY)
                    if (distance <= touchSlop) openTimerInApp()
                    true
                }
                else -> false
            }
        }
    }

    private fun openTimerInApp() {
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                putExtra(MainActivity.EXTRA_OPEN_TIMER, true)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
        )
    }

    private fun removeOverlay() {
        overlayView?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (_: Exception) {
                // Already detached.
            }
        }
        overlayView = null
    }

    private fun finishTimer() {
        stopTimer(clearSavedState = true)
    }

    private fun stopTimer(clearSavedState: Boolean) {
        timerActive = false
        handler.removeCallbacks(timerTick)
        removeOverlay()
        if (clearSavedState) {
            getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE).edit().clear().apply()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun saveState() {
        getSharedPreferences(PREFERENCES_NAME, MODE_PRIVATE).edit()
            .putBoolean(KEY_ACTIVE, timerActive)
            .putBoolean(KEY_PAUSED, paused)
            .putBoolean(KEY_APP_VISIBLE, appVisible)
            .putInt(KEY_INITIAL_DURATION, initialDuration)
            .putInt(KEY_PAUSED_REMAINING, pausedRemaining)
            .putLong(KEY_DEADLINE_ELAPSED_REALTIME, deadlineElapsedRealtime)
            .putInt(KEY_BOOT_COUNT, currentBootCount(this) ?: -1)
            .putLong(KEY_SAVED_ELAPSED_REALTIME, SystemClock.elapsedRealtime())
            .putLong(KEY_SAVED_WALL_CLOCK, System.currentTimeMillis())
            .putString(KEY_EXERCISE_NAME, exerciseName)
            .putLong(KEY_SELECTED_DATE_EPOCH_MS, selectedDateEpochMs)
            .putString(KEY_OWNER_ID, ownerId)
            .putString(KEY_GROUP_ID, groupId)
            .putInt(KEY_SESSION_INDEX, sessionIndex)
            .putInt(KEY_RECORD_DAY, recordDay)
            .apply()
    }

    private fun restoreState(): Boolean {
        val preferences = validatedPreferences(this) ?: return false
        timerActive = true
        paused = preferences.getBoolean(KEY_PAUSED, false)
        appVisible = preferences.getBoolean(KEY_APP_VISIBLE, true)
        initialDuration = preferences.getInt(KEY_INITIAL_DURATION, 0)
        pausedRemaining = preferences.getInt(KEY_PAUSED_REMAINING, 0)
        deadlineElapsedRealtime = preferences.getLong(KEY_DEADLINE_ELAPSED_REALTIME, 0L)
        exerciseName = preferences.getString(KEY_EXERCISE_NAME, "") ?: ""
        selectedDateEpochMs = preferences.getLong(KEY_SELECTED_DATE_EPOCH_MS, 0L)
        ownerId = preferences.getString(KEY_OWNER_ID, null)
        groupId = preferences.getString(KEY_GROUP_ID, null)
        sessionIndex = preferences.getInt(KEY_SESSION_INDEX, -1)
        recordDay = preferences.getInt(KEY_RECORD_DAY, -1)
        return true
    }

    private fun timerText(seconds: Int): String = "⏱  ${formatDuration(seconds)}"

    private fun formatDuration(seconds: Int): String {
        val safeSeconds = seconds.coerceAtLeast(0)
        return String.format(
            Locale.US,
            "%02d:%02d",
            safeSeconds / 60,
            safeSeconds % 60,
        )
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            resources.displayMetrics,
        ).toInt()
    }

    companion object {
        const val ACTION_START = "body_calendar.rest_timer.START"
        const val ACTION_UPDATE = "body_calendar.rest_timer.UPDATE"
        const val ACTION_RESUME = "body_calendar.rest_timer.RESUME"
        const val ACTION_PAUSE = "body_calendar.rest_timer.PAUSE"
        const val ACTION_STOP = "body_calendar.rest_timer.STOP"
        const val ACTION_SET_APP_VISIBLE = "body_calendar.rest_timer.SET_APP_VISIBLE"

        const val EXTRA_INITIAL_DURATION = "initialDuration"
        const val EXTRA_REMAINING_TIME = "remainingTime"
        const val EXTRA_DEADLINE_ELAPSED_REALTIME = "deadlineElapsedRealtime"
        const val EXTRA_APP_VISIBLE = "appVisible"
        const val EXTRA_EXERCISE_NAME = "exerciseName"
        const val EXTRA_SELECTED_DATE_EPOCH_MS = "selectedDateEpochMs"
        const val EXTRA_OWNER_ID = "ownerId"
        const val EXTRA_GROUP_ID = "groupId"
        const val EXTRA_SESSION_INDEX = "sessionIndex"
        const val EXTRA_RECORD_DAY = "recordDay"

        private const val PREFERENCES_NAME = "rest_timer_overlay_service"
        private const val KEY_ACTIVE = "active"
        private const val KEY_PAUSED = "paused"
        private const val KEY_APP_VISIBLE = "appVisible"
        private const val KEY_INITIAL_DURATION = "initialDuration"
        private const val KEY_PAUSED_REMAINING = "pausedRemaining"
        private const val KEY_DEADLINE_ELAPSED_REALTIME = "deadlineElapsedRealtime"
        private const val KEY_BOOT_COUNT = "bootCount"
        private const val KEY_SAVED_ELAPSED_REALTIME = "savedElapsedRealtime"
        private const val KEY_SAVED_WALL_CLOCK = "savedWallClock"
        private const val KEY_EXERCISE_NAME = "exerciseName"
        private const val KEY_SELECTED_DATE_EPOCH_MS = "selectedDateEpochMs"
        private const val KEY_OWNER_ID = "ownerId"
        private const val KEY_GROUP_ID = "groupId"
        private const val KEY_SESSION_INDEX = "sessionIndex"
        private const val KEY_RECORD_DAY = "recordDay"
        private const val NOTIFICATION_CHANNEL_ID = "rest_timer_overlay"
        private const val NOTIFICATION_ID = 4107
        private const val OPEN_TIMER_REQUEST_CODE = 4108
        private const val TICK_INTERVAL_MS = 250L
        private const val DEADLINE_SANITY_MARGIN_SECONDS = 60L

        fun hasActiveTimer(context: Context): Boolean {
            return validatedPreferences(context) != null
        }

        fun getSnapshot(context: Context): Map<String, Any?>? {
            val preferences = validatedPreferences(context) ?: return null
            val isPaused = preferences.getBoolean(KEY_PAUSED, false)
            val remaining = if (isPaused) {
                preferences.getInt(KEY_PAUSED_REMAINING, 0)
            } else {
                val remainingMs = (
                    preferences.getLong(KEY_DEADLINE_ELAPSED_REALTIME, 0L) -
                        SystemClock.elapsedRealtime()
                    ).coerceAtLeast(0L)
                ceil(remainingMs / 1_000.0).toInt()
            }
            if (remaining <= 0) {
                clearInvalidState(context, preferences)
                return null
            }
            return hashMapOf(
                "active" to true,
                "paused" to isPaused,
                "initialDuration" to preferences.getInt(KEY_INITIAL_DURATION, 0),
                "remainingTime" to remaining,
                "exerciseName" to preferences.getString(KEY_EXERCISE_NAME, ""),
                "selectedDateEpochMs" to
                    preferences.getLong(KEY_SELECTED_DATE_EPOCH_MS, 0L),
                "ownerId" to preferences.getString(KEY_OWNER_ID, null),
                "groupId" to preferences.getString(KEY_GROUP_ID, null),
                "sessionIndex" to preferences.getInt(KEY_SESSION_INDEX, -1)
                    .takeIf { it >= 0 },
                "recordDay" to preferences.getInt(KEY_RECORD_DAY, -1)
                    .takeIf { it >= 0 },
            )
        }

        private fun validatedPreferences(context: Context): SharedPreferences? {
            val preferences =
                context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
            if (!preferences.getBoolean(KEY_ACTIVE, false)) return null

            val currentBootCount = currentBootCount(context)
            val storedBootCount = preferences.getInt(KEY_BOOT_COUNT, -1)
            val initialDuration = preferences.getInt(KEY_INITIAL_DURATION, 0)
            val isPaused = preferences.getBoolean(KEY_PAUSED, false)
            val metadataValid =
                !preferences.getString(KEY_EXERCISE_NAME, "").isNullOrBlank() &&
                    preferences.getLong(KEY_SELECTED_DATE_EPOCH_MS, 0L) > 0L
            val bootValid = currentBootCount?.let { it == storedBootCount }
            val savedElapsedRealtime =
                preferences.getLong(KEY_SAVED_ELAPSED_REALTIME, -1L)
            val savedWallClock = preferences.getLong(KEY_SAVED_WALL_CLOCK, -1L)
            val elapsedDelta = SystemClock.elapsedRealtime() - savedElapsedRealtime
            val wallDelta = System.currentTimeMillis() - savedWallClock
            val fallbackBootContinuityValid =
                savedElapsedRealtime >= 0L &&
                    savedWallClock >= 0L &&
                    elapsedDelta >= 0L &&
                    wallDelta >= 0L &&
                    abs(elapsedDelta - wallDelta) <= FALLBACK_CLOCK_SKEW_MILLIS
            val stateValid = when {
                !metadataValid || initialDuration <= 0 -> false
                bootValid == false -> false
                bootValid == null && !fallbackBootContinuityValid -> false
                isPaused -> {
                    val remaining = preferences.getInt(KEY_PAUSED_REMAINING, 0)
                    remaining in 1..(initialDuration + DEADLINE_SANITY_MARGIN_SECONDS.toInt())
                }
                else -> {
                    val remainingMs =
                        preferences.getLong(KEY_DEADLINE_ELAPSED_REALTIME, 0L) -
                            SystemClock.elapsedRealtime()
                    val maximumRemainingMs =
                        (initialDuration + DEADLINE_SANITY_MARGIN_SECONDS) * 1_000L
                    remainingMs in 1L..maximumRemainingMs
                }
            }
            if (bootValid == null && !stateValid) {
                clearInvalidState(context, preferences)
                return null
            }
            if (!stateValid) {
                clearInvalidState(context, preferences)
                return null
            }
            return preferences
        }

        private fun currentBootCount(context: Context): Int? {
            return try {
                Settings.Global.getInt(
                    context.contentResolver,
                    Settings.Global.BOOT_COUNT,
                    -1,
                ).takeIf { it >= 0 }
            } catch (_: Exception) {
                null
            }
        }

        private fun clearInvalidState(
            context: Context,
            preferences: SharedPreferences,
        ) {
            preferences.edit().clear().apply()
            context.stopService(Intent(context, RestTimerOverlayService::class.java))
        }

        private const val FALLBACK_CLOCK_SKEW_MILLIS = 60_000L
    }
}
