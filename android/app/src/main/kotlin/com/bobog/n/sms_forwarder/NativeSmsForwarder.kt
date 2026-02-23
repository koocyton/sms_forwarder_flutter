package com.bobog.n.sms_forwarder

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID

/**
 * Reads forwarding configs from Flutter SharedPreferences and sends
 * SMS content via HTTP API and/or email — all natively, no Flutter engine needed.
 */
object NativeSmsForwarder {

    private const val TAG = "NativeSmsForwarder"
    /** 由 Flutter 通过 MethodChannel 同步写入，后台收短信时只读此文件（Flutter 2.x 用 DataStore，无法直接读） */
    const val NATIVE_PREFS_NAME = "SmsForwarderNativePrefs"

    private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
    private const val FLUTTER_SMS_LOGS_KEY = "flutter.sms_logs"
    private const val MAX_LOGS = 200

    fun forward(context: Context, sender: String, body: String, onDone: (() -> Unit)? = null) {
        val prefs = context.getSharedPreferences(NATIVE_PREFS_NAME, Context.MODE_PRIVATE)

        val listeningEnabled = prefs.getBoolean("listening_enabled", false)
        if (!listeningEnabled) {
            onDone?.invoke()
            return
        }

        val date = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US)
            .format(java.util.Date())

        val apiJson = prefs.getString("api_configs", null)
        val emailJson = prefs.getString("email_configs", null)

        var pending = 0
        val doneLock = Any()
        fun checkDone() {
            synchronized(doneLock) {
                pending--
                if (pending <= 0) onDone?.invoke()
            }
        }

        var anyMatched = false

        if (!apiJson.isNullOrEmpty()) {
            try {
                val arr = JSONArray(apiJson)
                for (i in 0 until arr.length()) {
                    val cfg = arr.getJSONObject(i)
                    val enabled = cfg.optBoolean("enabled", true)
                    val matches = matchesFilter(sender, body, cfg)
                    if (!enabled) continue
                    if (!matches) continue
                    anyMatched = true
                    synchronized(doneLock) { pending++ }
                    val cfgName = cfg.optString("name", "?")
                    Thread {
                        var success = false
                        var errorMsg: String? = null
                        try {
                            sendHttp(cfg, sender, body, date)
                            success = true
                        } catch (e: Exception) {
                            errorMsg = e.toString()
                        } finally {
                            appendLogToFlutterPrefs(context, sender, body, cfgName, success, errorMsg)
                            checkDone()
                        }
                    }.start()
                }
            } catch (_: Exception) {}
        }

        if (!emailJson.isNullOrEmpty()) {
            try {
                val arr = JSONArray(emailJson)
                for (i in 0 until arr.length()) {
                    val cfg = arr.getJSONObject(i)
                    val enabled = cfg.optBoolean("enabled", true)
                    val matches = matchesFilter(sender, body, cfg)
                    if (!enabled) continue
                    if (!matches) continue
                    anyMatched = true
                    synchronized(doneLock) { pending++ }
                    val cfgName = cfg.optString("name", "?")
                    Thread {
                        var success = false
                        var errorMsg: String? = null
                        try {
                            sendEmail(cfg, sender, body, date)
                            success = true
                        } catch (e: Exception) {
                            errorMsg = e.toString()
                        } finally {
                            appendLogToFlutterPrefs(context, sender, body, cfgName, success, errorMsg)
                            checkDone()
                        }
                    }.start()
                }
            } catch (_: Exception) {}
        }

        if (!anyMatched) {
            val hasEnabledApi = try {
                val arr = if (!apiJson.isNullOrEmpty()) JSONArray(apiJson) else JSONArray()
                (0 until arr.length()).any { arr.getJSONObject(it).optBoolean("enabled", true) }
            } catch (_: Exception) { false }
            val hasEnabledEmail = try {
                val arr = if (!emailJson.isNullOrEmpty()) JSONArray(emailJson) else JSONArray()
                (0 until arr.length()).any { arr.getJSONObject(it).optBoolean("enabled", true) }
            } catch (_: Exception) { false }

            val reason = if (!hasEnabledApi && !hasEnabledEmail) {
                "没有启用的 API 或邮箱，请先添加并开启"
            } else {
                "未匹配任何规则（若设置了发送方/内容过滤，需包含对应关键词）"
            }
            appendLogToFlutterPrefs(context, sender, body, "SmsForward:NotForwarded", false, reason)
        }

        if (pending == 0) onDone?.invoke()
    }

    @Synchronized
    private fun appendLogToFlutterPrefs(
        context: Context,
        sender: String,
        body: String,
        apiName: String,
        success: Boolean,
        errorMessage: String?
    ) {
        try {
            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            val raw = flutterPrefs.getString(FLUTTER_SMS_LOGS_KEY, null)
            val logs = if (!raw.isNullOrEmpty()) JSONArray(raw) else JSONArray()

            val entry = JSONObject().apply {
                put("id", UUID.randomUUID().toString())
                put("sender", sender)
                put("body", body)
                put("timestamp", java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", java.util.Locale.US).format(java.util.Date()))
                put("apiName", apiName)
                put("success", success)
                if (errorMessage != null) put("errorMessage", errorMessage)
            }

            val newLogs = JSONArray()
            newLogs.put(entry)
            for (i in 0 until minOf(logs.length(), MAX_LOGS - 1)) {
                newLogs.put(logs.get(i))
            }

            flutterPrefs.edit().putString(FLUTTER_SMS_LOGS_KEY, newLogs.toString()).apply()
        } catch (_: Exception) {}
    }

    private fun matchesFilter(sender: String, body: String, cfg: JSONObject): Boolean {
        val sf = optStringOrEmpty(cfg, "senderFilter")
        if (sf.isNotEmpty() && !sender.contains(sf)) return false
        val bf = optStringOrEmpty(cfg, "bodyFilter")
        if (bf.isNotEmpty() && !body.contains(bf)) return false
        return true
    }

    private fun optStringOrEmpty(cfg: JSONObject, key: String): String {
        if (!cfg.has(key) || cfg.isNull(key)) return ""
        val s = cfg.optString(key, "")
        if (s == "null") return ""
        return s
    }

    private fun sendHttp(cfg: JSONObject, sender: String, body: String, date: String) {
        val url = cfg.getString("url")
        val method = cfg.optString("method", "POST").uppercase()

        val headersObj = cfg.optJSONObject("headers")
        val headers = mutableMapOf<String, String>()
        headersObj?.keys()?.forEach { k -> headers[k] = headersObj.getString(k) }

        val template = cfg.optString("bodyTemplate", "")
        val payload: String = if (template.isNotEmpty()) {
            template
                .replace("{{sender}}", sender)
                .replace("{{body}}", body)
                .replace("{{date}}", date)
        } else {
            JSONObject().apply {
                put("sender", sender)
                put("body", body)
                put("date", date)
            }.toString()
        }

        val conn = URL(url).openConnection() as HttpURLConnection
        conn.requestMethod = method
        conn.connectTimeout = 15_000
        conn.readTimeout = 15_000
        if (!headers.containsKey("Content-Type")) {
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8")
        }
        headers.forEach { (k, v) -> conn.setRequestProperty(k, v) }

        if (method != "GET") {
            conn.doOutput = true
            OutputStreamWriter(conn.outputStream, Charsets.UTF_8).use { it.write(payload) }
        }

        val code = conn.responseCode
        conn.disconnect()
    }

    private fun sendEmail(cfg: JSONObject, sender: String, body: String, date: String) {
        val host = cfg.getString("smtpHost")
        val port = cfg.optInt("smtpPort", 465)
        val useSsl = cfg.optBoolean("useSsl", true)
        val username = cfg.optString("smtpUser", "").ifEmpty { null }
        val password = cfg.optString("smtpPassword", "").ifEmpty { null }
        val from = cfg.getString("fromEmail")
        val toEmails = cfg.getString("toEmails")
            .split(",").map { it.trim() }.filter { it.isNotEmpty() }
        if (toEmails.isEmpty()) throw IllegalArgumentException("未配置收件人")

        val subject = "短信转发: $sender"
        val text = "发送方: $sender\n时间: $date\n\n$body"

        NativeSmtpSender.sendSync(host, port, useSsl, username, password, from, toEmails, subject, text)
    }
}
