package com.example.ssk

import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs

class MainActivity : FlutterActivity() {
    private val channelName = "ssk/google_maps_launcher"
    private val shareChannelName = "plugins.flutter.io/share"
    private val bubbleChannelName = "ssk/driver_bubble"

    private var bubbleView: View? = null
    private var bubbleParams: WindowManager.LayoutParams? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openDirections" -> {
                        try {
                            val origin = call.argument<String>("origin")
                            val destination = call.argument<String>("destination")
                            if (origin.isNullOrBlank() || destination.isNullOrBlank()) {
                                result.success(false)
                                return@setMethodCallHandler
                            }

                            val uri = Uri.parse(
                                "https://www.google.com/maps/dir/?api=1" +
                                    "&origin=$origin" +
                                    "&destination=$destination" +
                                    "&travelmode=driving"
                            )
                            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (error: Exception) {
                            result.success(false)
                        }
                    }
                    "openNavigationUrl" -> {
                        try {
                            val url = call.argument<String>("url")
                            if (url.isNullOrBlank()) {
                                result.success(false)
                                return@setMethodCallHandler
                            }
                            val uri = Uri.parse(url)
                            // Prefer Google Maps when installed, fall back to chooser.
                            val mapsIntent = Intent(Intent.ACTION_VIEW, uri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                setPackage("com.google.android.apps.maps")
                            }
                            try {
                                startActivity(mapsIntent)
                            } catch (e: Exception) {
                                val fallback = Intent(Intent.ACTION_VIEW, uri).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(fallback)
                            }
                            result.success(true)
                        } catch (error: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, shareChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "share" -> {
                        try {
                            val text = call.argument<String>("text")
                            val subject = call.argument<String>("subject") ?: "Share"
                            if (text.isNullOrBlank()) {
                                result.success(null)
                                return@setMethodCallHandler
                            }

                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "text/plain"
                                putExtra(Intent.EXTRA_SUBJECT, subject)
                                putExtra(Intent.EXTRA_TEXT, text)
                            }
                            startActivity(Intent.createChooser(intent, subject))
                            result.success(null)
                        } catch (error: Exception) {
                            result.notImplemented()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, bubbleChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasOverlayPermission" -> {
                        result.success(hasOverlayPermission())
                    }
                    "requestOverlayPermission" -> {
                        result.success(openOverlaySettings())
                    }
                    "showBubble" -> {
                        val label = call.argument<String>("label") ?: "SSK"
                        result.success(showBubble(label))
                    }
                    "hideBubble" -> {
                        hideBubble()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        // When the driver taps the bubble we bring the app forward and hide
        // the overlay; also hide it whenever the app itself is foreground so
        // it never covers our own trip UI.
        hideBubble()
    }

    override fun onDestroy() {
        hideBubble()
        super.onDestroy()
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    /**
     * Opens the system screen for this app's "Display over other apps" toggle
     * directly (not the generic list), with fallbacks for OEM skins that
     * ignore the direct deep link.
     */
    private fun openOverlaySettings(): Boolean {
        // 1) Direct per-app overlay page (stock Android / Samsung / Pixel).
        try {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            return true
        } catch (error: Exception) {
            // Fall through to App info.
        }
        // 2) App info page: the overlay toggle lives one tap away
        // ("Special app access" / "Display over other apps").
        try {
            val intent = Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", packageName, null)
            ).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            return true
        } catch (error: Exception) {
            return false
        }
    }

    private fun dp(value: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value,
            resources.displayMetrics
        ).toInt()
    }

    private fun showBubble(label: String): Boolean {
        if (!hasOverlayPermission()) {
            return false
        }
        try {
            hideBubble()
            val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            val size = dp(60f)

            val circleBg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(0xFF1F9D55.toInt())
                setStroke(dp(2f), 0xFFFFFFFF.toInt())
            }

            val textView = TextView(this).apply {
                text = if (label.length > 4) label.take(4) else label.ifBlank { "SSK" }
                setTextColor(0xFFFFFFFF.toInt())
                textSize = 15f
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }

            val container = FrameLayout(this).apply {
                background = circleBg
                addView(
                    textView,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT
                    )
                )
                // Shadow on supported versions.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    elevation = dp(6f).toFloat()
                }
            }

            val params = WindowManager.LayoutParams(
                size,
                size,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = dp(16f)
                y = dp(220f)
            }

            var initialX = 0
            var initialY = 0
            var initialTouchX = 0f
            var initialTouchY = 0f
            var downTime = 0L

            container.setOnTouchListener { view, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        downTime = System.currentTimeMillis()
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        try {
                            windowManager.updateViewLayout(view, params)
                        } catch (e: Exception) {
                            // View may have been removed; ignore.
                        }
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        val movedX = abs(event.rawX - initialTouchX)
                        val movedY = abs(event.rawY - initialTouchY)
                        val elapsed = System.currentTimeMillis() - downTime
                        if (movedX < 12 && movedY < 12 && elapsed < 600) {
                            bringAppToFront()
                            view.post { hideBubble() }
                        }
                        true
                    }
                    else -> false
                }
            }

            windowManager.addView(container, params)
            bubbleView = container
            bubbleParams = params
            return true
        } catch (error: Exception) {
            hideBubble()
            return false
        }
    }

    private fun hideBubble() {
        try {
            val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            bubbleView?.let { windowManager.removeViewImmediate(it) }
        } catch (error: Exception) {
            // Already removed; ignore.
        } finally {
            bubbleView = null
            bubbleParams = null
        }
    }

    private fun bringAppToFront() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(intent)
        } catch (error: Exception) {
            // Best effort; the overlay hides anyway.
        }
    }
}
