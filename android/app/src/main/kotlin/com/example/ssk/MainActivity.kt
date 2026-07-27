package com.example.ssk

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "ssk/google_maps_launcher"

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
    }
}
