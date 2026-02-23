package com.bobog.n.sms_forwarder

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val foregroundChannel = "com.bobog.n.sms_forwarder/foreground"
    private val smtpChannel = "com.bobog.n.sms_forwarder/smtp"
    private val configChannel = "com.bobog.n.sms_forwarder/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, foregroundChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "startListenForeground" -> {
                    try {
                        val intent = Intent(this, ListenForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("START_FAILED", e.message, null)
                    }
                }
                "stopListenForeground" -> {
                    try {
                        stopService(Intent(this, ListenForegroundService::class.java))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("STOP_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smtpChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendEmail" -> {
                    val host = call.argument<String>("host") ?: ""
                    val port = call.argument<Int>("port") ?: 465
                    val useSsl = call.argument<Boolean>("useSsl") ?: true
                    val username = call.argument<String>("username")
                    val password = call.argument<String>("password")
                    val from = call.argument<String>("from") ?: ""
                    val toList = call.argument<List<String>>("toList") ?: emptyList()
                    val subject = call.argument<String>("subject") ?: ""
                    val body = call.argument<String>("body") ?: ""

                    Thread {
                        try {
                            NativeSmtpSender.sendSync(
                                host, port, useSsl,
                                username, password,
                                from, toList, subject, body
                            )
                            runOnUiThread { result.success(true) }
                        } catch (e: Exception) {
                            val msg = buildString {
                                append(e.javaClass.simpleName)
                                append(": ")
                                append(e.message ?: "unknown")
                                var cause = e.cause
                                while (cause != null) {
                                    append(" -> ")
                                    append(cause.javaClass.simpleName)
                                    append(": ")
                                    append(cause.message ?: "unknown")
                                    cause = cause.cause
                                }
                            }
                            runOnUiThread { result.error("SMTP_FAILED", msg, null) }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, configChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncForwarderConfig" -> {
                    try {
                        val listeningEnabled = call.argument<Boolean>("listeningEnabled") ?: false
                        val apiConfigsJson = call.argument<String>("apiConfigsJson") ?: "[]"
                        val emailConfigsJson = call.argument<String>("emailConfigsJson") ?: "[]"
                        val prefs = getSharedPreferences(NativeSmsForwarder.NATIVE_PREFS_NAME, MODE_PRIVATE)
                        prefs.edit()
                            .putBoolean("listening_enabled", listeningEnabled)
                            .putString("api_configs", apiConfigsJson)
                            .putString("email_configs", emailConfigsJson)
                            .apply()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SYNC_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
