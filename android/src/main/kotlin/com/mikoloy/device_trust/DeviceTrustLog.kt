// [DeviceTrust] Consistent debug logging (debug-only)

package com.mikoloy.device_trust

import android.content.Context
import android.content.pm.ApplicationInfo
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

object DeviceTrustLog {
    private val enabledFlag = AtomicBoolean(false)

    fun init(context: Context) {
        val debuggable = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        enabledFlag.set(debuggable)
    }

    fun d(scope: String, msg: String) {
        if (enabledFlag.get()) {
            Log.d("DeviceTrust/$scope", msg)
        }
    }
}
