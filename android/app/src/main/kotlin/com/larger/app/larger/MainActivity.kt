package com.larger.app.larger

import android.content.Context
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CONTROL_CHANNEL = "com.example.larger/media_control"
    private val STATUS_CHANNEL = "com.example.larger/media_status"
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playPause" -> {
                    sendMediaKeyEvent(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                    result.success(null)
                }
                "next" -> {
                    sendMediaKeyEvent(KeyEvent.KEYCODE_MEDIA_NEXT)
                    result.success(null)
                }
                "previous" -> {
                    sendMediaKeyEvent(KeyEvent.KEYCODE_MEDIA_PREVIOUS)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STATUS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var isPolling = false
                private val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    isPolling = true
                    val runnable = object : Runnable {
                        override fun run() {
                            if (!isPolling) return
                            events?.success(audioManager.isMusicActive)
                            mainHandler.postDelayed(this, 1000)
                        }
                    }
                    mainHandler.post(runnable)
                }

                override fun onCancel(arguments: Any?) {
                    isPolling = false
                }
            }
        )
    }

    private fun sendMediaKeyEvent(keyCode: Int) {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val eventTime = SystemClock.uptimeMillis()
        val downEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, keyCode, 0)
        audioManager.dispatchMediaKeyEvent(downEvent)
        val upEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, keyCode, 0)
        audioManager.dispatchMediaKeyEvent(upEvent)
    }
}
