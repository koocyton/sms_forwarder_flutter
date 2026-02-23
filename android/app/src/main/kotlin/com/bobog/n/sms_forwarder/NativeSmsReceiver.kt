package com.bobog.n.sms_forwarder

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Telephony
import android.util.Log

/**
 * Native BroadcastReceiver that processes SMS when the app is NOT in the foreground.
 * When the app IS in the foreground, the telephony Flutter plugin handles it in Dart.
 */
class NativeSmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val foreground = isAppForeground(context)
        // Log.d(TAG, "NativeSmsReceiver: foreground=$foreground")
        if (foreground) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        val grouped = messages.groupBy { it.originatingAddress ?: "" }

        val pendingResult = goAsync()
        var count = grouped.size
        val lock = Any()
        for ((address, parts) in grouped) {
            if (address.isEmpty()) {
                synchronized(lock) { count--; if (count == 0) pendingResult.finish() }
                continue
            }
            val body = parts.joinToString("") { it.messageBody ?: "" }
            // Log.d(TAG, "NativeSmsReceiver: forwarding from $address")
            NativeSmsForwarder.forward(context.applicationContext, address, body) {
                synchronized(lock) {
                    count--
                    if (count <= 0) pendingResult.finish()
                }
            }
        }
        if (grouped.isEmpty()) pendingResult.finish()
    }

    companion object {
        private const val TAG = "NativeSmsReceiver"
    }

    private fun isAppForeground(context: Context): Boolean {
        val km = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        if (km?.isKeyguardLocked == true) return false

        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val myPid = Process.myPid()
        val list = am?.runningAppProcesses ?: return false
        for (info in list) {
            if (info.pid == myPid) {
                return info.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
            }
        }
        return false
    }
}
