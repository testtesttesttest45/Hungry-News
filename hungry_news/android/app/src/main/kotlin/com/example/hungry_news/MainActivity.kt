package com.example.hungry_news

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app/minimize"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "moveTaskToBack") {
                    moveTaskToBack(true) // Minimize the app
                    result.success(null) // Notify Flutter that the method was successful
                } else {
                    result.notImplemented() // Handle unimplemented methods
                }
            }
    }
}
