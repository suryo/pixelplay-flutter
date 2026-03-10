package com.example.pixelplay

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private var isPlaying = false
    private var mediaType = "audio"
    private val CHANNEL = "pixelplay/pip"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updatePlaybackStatus") {
                isPlaying = call.argument<Boolean>("isPlaying") ?: false
                mediaType = call.argument<String>("mediaType") ?: "audio"
                
                // If already in PiP, update the params (e.g. aspect ratio)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isInPictureInPictureMode) {
                    val ratio = if (mediaType == "video") Rational(16, 9) else Rational(1, 1)
                    val params = PictureInPictureParams.Builder()
                        .setAspectRatio(ratio)
                        .build()
                    setPictureInPictureParams(params)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onUserLeaveHint() {
        if (isPlaying && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ratio = if (mediaType == "video") Rational(16, 9) else Rational(1, 1)
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(ratio)
                .build()
            enterPictureInPictureMode(params)
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: android.content.res.Configuration?) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).invokeMethod("onPiPModeChanged", isInPictureInPictureMode)
        }
    }
}
