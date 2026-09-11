package com.example.ssk

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ssk/google_maps_launcher"
    private val shareChannelName = "plugins.flutter.io/share"

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
    }
}
