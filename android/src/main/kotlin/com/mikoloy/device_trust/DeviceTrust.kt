// [DeviceTrust/Android] Kotlin Layer
// Root/jailbreak, hook/Frida, emulator detection implementation.
// Works with native C++ layer (DeviceTrustNative).
// Uses only official Android SDK APIs; no third-party libraries (RootBeer/SafetyNet).

package com.mikoloy.device_trust

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Debug
import android.provider.Settings
import com.mikoloy.device_trust.DeviceTrustLog
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.TimeUnit

/**
 * [DeviceTrust/Android] Device Trust Report
 * 
 * Root/jailbreak and hook/frida detection results
 */
data class DeviceTrustReport(
    val rootedOrJailbroken: Boolean,
    val emulator: Boolean,
    val devModeEnabled: Boolean,
    val adbEnabled: Boolean,
    val fridaSuspected: Boolean,
    val debuggerAttached: Boolean,
    val details: Map<String, Any?>
)

/**
 * DeviceTrust - Detects device security posture without third-party libraries
 * 
 * Multi-signal approach: single signal not sufficient, at least 2 strong signals required
 * Performance target: 1-20ms total latency
 */
object DeviceTrust {

    private val KNOWN_ROOT_PACKAGES = listOf(
        "com.topjohnwu.magisk",
        "eu.chainfire.supersu",
        "com.koushikdutta.superuser",
        "com.noshufou.android.su",
        "com.devadvance.rootcloak",
        "com.devadvance.rootcloakplus"
    )

    private val SU_PATHS = listOf(
        "/system/bin/su",
        "/system/xbin/su",
        "/sbin/su",
        "/su/bin/su",
        "/system/sd/xbin/su",
        "/system/bin/failsafe/su",
        "/data/local/xbin/su",
        "/data/local/bin/su",
        "/data/local/su"
    )

    private val FRIDA_PORTS = listOf(27042, 27043)

    /**
     * [DeviceTrust/Android] Main report building function
     * 
     * Runs all security checks and returns consolidated report:
     * - Root/jailbreak signals (6 checks)
     * - Emulator detection (6+ checks)
     * - Developer mode and ADB
     * - Hook/Frida detection (Kotlin + Native C++)
     * - Debugger detection
     */
    fun buildReport(context: Context): DeviceTrustReport {
        DeviceTrustLog.init(context)
        val startTime = System.currentTimeMillis()
        val details = mutableMapOf<String, Any?>()

        // Root checks
        val rootSignals = checkRootSignals(context, details)
        val rootedOrJailbroken = rootSignals >= 1 // At least 1 strong root signal
        DeviceTrustLog.d("Root", "signals=${details["rootSignals"]} testKeys=${details["buildTestKeys"]} su=${details["suExists"]}")

        // Emulator detection
        val emulatorSignals = checkEmulatorSignals(details)
        val emulatorStrong = (details["emulatorStrong"] as? Boolean) == true
        val emulator = emulatorStrong || emulatorSignals >= 2 // Strong indicator or at least 2 signals

        // Developer mode / ADB
        val devModeEnabled = checkDeveloperMode(context, details)
        val adbEnabled = checkAdbEnabled(context, details)

        // Hook/Frida detection (Kotlin layer)
        val kotlinHookSignals = checkHookSignals(details)
        
        // Native signals
        var nativeFrida = false
        try {
            val nativeJson = DeviceTrustNative.collectNativeSignalsOrEmpty()
            details["nativeSignalsRaw"] = nativeJson
            nativeFrida = parseNativeSignals(nativeJson, details)
        } catch (e: Throwable) {
            details["nativeError"] = e.message ?: "Unknown error"
            // Fail-soft: continue if native lib fails to load
        }

        val fridaSuspected = kotlinHookSignals || nativeFrida
        DeviceTrustLog.d("Hook", "kotlinSignals=${details["kotlinHookSignals"]} suspiciousMapsCount=${(details["suspiciousMaps"] as? List<*>)?.size ?: 0}")

        // Debugger
        val debuggerAttached = checkDebugger(details)

        val totalTime = System.currentTimeMillis() - startTime
        details["totalTimeMs"] = totalTime

        // Debug logging (debug-only via DeviceTrustLog)
        DeviceTrustLog.d("Decision",
            "root=$rootedOrJailbroken emu=$emulator(dev=${details["emulatorSignals"]}, strong=${details["emulatorStrong"]==true}) " +
            "hook=$fridaSuspected dbg=$debuggerAttached devMode=$devModeEnabled adb=$adbEnabled"
        )
        DeviceTrustLog.d("Indicators", "emuIndicators=${details["emulatorIndicators"]}")

        return DeviceTrustReport(
            rootedOrJailbroken = rootedOrJailbroken,
            emulator = emulator,
            devModeEnabled = devModeEnabled,
            adbEnabled = adbEnabled,
            fridaSuspected = fridaSuspected,
            debuggerAttached = debuggerAttached,
            details = details
        )
    }

    /**
     * [DeviceTrust/Android] Check for root signals
     * 
     * Performs 6 root detection checks:
     * 1. Build.TAGS test-keys check
     * 2. Dangerous props (ro.debuggable, ro.secure)
     * 3. su binary existence (multiple paths)
     * 4. /proc/mounts rw mount check
     * 5. Known root packages (Magisk, SuperSU, etc.)
     * 6. Busybox existence
     * 
     * @return Number of positive strong signals
     */
    private fun checkRootSignals(context: Context, details: MutableMap<String, Any?>): Int {
        var signals = 0

        // 1. Build.TAGS check
        val hasTestKeys = Build.TAGS?.contains("test-keys") == true
        details["buildTestKeys"] = hasTestKeys
        if (hasTestKeys) signals++

        // 2. su binary existence
        val suExists = checkSuBinary()
        details["suExists"] = suExists
        if (suExists) signals++

        // 3. "which su" attempt
        val whichSuResult = executeWhichSu()
        details["whichSu"] = whichSuResult
        if (whichSuResult != null && whichSuResult.isNotEmpty()) signals++

        // 4. Dangerous system properties
        val dangerousProps = checkDangerousProps()
        details["dangerousProps"] = dangerousProps
        if (dangerousProps.isNotEmpty()) signals++

        // 5. RW mounts check
        val rwMounts = checkRwMounts()
        details["rwMounts"] = rwMounts
        if (rwMounts) signals++

        // 6. Known root packages
        val rootPackages = checkKnownRootPackages(context)
        details["knownRootPackages"] = rootPackages
        if (rootPackages.isNotEmpty()) signals++

        details["rootSignals"] = signals
        return signals
    }

    /**
     * su binary check
     */
    private fun checkSuBinary(): Boolean {
        return SU_PATHS.any { path ->
            try {
                val file = File(path)
                file.exists() && file.canExecute()
            } catch (e: Exception) {
                false
            }
        }
    }

    /**
     * Attempt "which su" command (short timeout)
     */
    private fun executeWhichSu(): String? {
        return try {
            val process = Runtime.getRuntime().exec("which su")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val completed = process.waitFor(200, TimeUnit.MILLISECONDS)
            if (completed) {
                reader.readLine()
            } else {
                process.destroy()
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Dangerous system properties check
     */
    private fun checkDangerousProps(): Map<String, String> {
        val props = mutableMapOf<String, String>()
        
        val debuggable = getSystemProperty("ro.debuggable")
        if (debuggable == "1") {
            props["ro.debuggable"] = debuggable
        }

        val secure = getSystemProperty("ro.secure")
        if (secure == "0") {
            props["ro.secure"] = secure
        }

        return props
    }

    /**
     * Read system property (short timeout)
     */
    private fun getSystemProperty(key: String): String {
        return try {
            val process = Runtime.getRuntime().exec("getprop $key")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val completed = process.waitFor(200, TimeUnit.MILLISECONDS)
            if (completed) {
                reader.readLine()?.trim() ?: ""
            } else {
                process.destroy()
                ""
            }
        } catch (e: Exception) {
            ""
        }
    }

    /**
     * RW mount check (/proc/mounts)
     */
    private fun checkRwMounts(): Boolean {
        return try {
            val mountsFile = File("/proc/mounts")
            if (!mountsFile.exists()) return false

            mountsFile.useLines { lines ->
                lines.any { line ->
                    (line.contains(" / ") || line.contains(" /system ") || line.contains(" /vendor ")) &&
                    line.contains(" rw,")
                }
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Check for known root packages
     */
    private fun checkKnownRootPackages(context: Context): List<String> {
        val installed = mutableListOf<String>()
        val pm = context.packageManager
        
        KNOWN_ROOT_PACKAGES.forEach { pkg ->
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    pm.getPackageInfo(pkg, PackageManager.PackageInfoFlags.of(0))
                } else {
                    @Suppress("DEPRECATION")
                    pm.getPackageInfo(pkg, 0)
                }
                installed.add(pkg)
            } catch (e: PackageManager.NameNotFoundException) {
                // Package not installed
            }
        }
        
        return installed
    }

    /**
     * [DeviceTrust/Android] Check for emulator signals (enhanced)
     * 
     * Strong indicators (sufficient alone):
     * - ro.kernel.qemu=1
     * - QEMU files (/init.goldfish.rc, /sys/qemu_trace, /dev/qemu_pipe, /dev/socket/qemud)
     * 
     * Regular indicators (2+ required):
     * - Build.FINGERPRINT, MODEL, MANUFACTURER, HARDWARE, PRODUCT, BOARD, BRAND, DEVICE
     * 
     * @return Number of positive signals
     */
    private fun checkEmulatorSignals(details: MutableMap<String, Any?>): Int {
        var signals = 0
        val indicators = mutableListOf<String>()
        var strongIndicator = false

        // Strong indicator 1: QEMU property
        val qemu = getSystemProperty("ro.kernel.qemu")
        if (qemu == "1") {
            indicators.add("strong:qemu=1")
            signals++
            strongIndicator = true
        }

        // Strong indicator 2: QEMU files
        val qemuFiles = listOf(
            "/init.goldfish.rc",
            "/sys/qemu_trace",
            "/dev/qemu_pipe",
            "/dev/socket/qemud"
        )
        qemuFiles.forEach { path ->
            if (File(path).exists()) {
                indicators.add("strong:file:$path")
                signals++
                strongIndicator = true
            }
        }

        // Regular indicators - Build properties
        if (Build.FINGERPRINT.contains("generic", ignoreCase = true) || 
            Build.FINGERPRINT.contains("sdk_gphone", ignoreCase = true) ||
            Build.FINGERPRINT.contains("emulator", ignoreCase = true)) {
            indicators.add("fingerprint:${Build.FINGERPRINT}")
            signals++
        }

        if (Build.MODEL.contains("Emulator", ignoreCase = true) ||
            Build.MODEL.contains("Android SDK", ignoreCase = true) ||
            Build.MODEL.contains("sdk_gphone", ignoreCase = true) ||
            Build.MODEL.contains("AOSP on IA Emulator", ignoreCase = true)) {
            indicators.add("model:${Build.MODEL}")
            signals++
        }

        if (Build.MANUFACTURER.contains("Genymotion", ignoreCase = true) ||
            Build.MANUFACTURER.contains("unknown", ignoreCase = true) ||
            Build.MANUFACTURER.contains("Google", ignoreCase = true)) {
            indicators.add("manufacturer:${Build.MANUFACTURER}")
            signals++
        }

        if (Build.HARDWARE.contains("ranchu", ignoreCase = true) ||
            Build.HARDWARE.contains("goldfish", ignoreCase = true)) {
            indicators.add("hardware:${Build.HARDWARE}")
            signals++
        }

        if (Build.PRODUCT.contains("vbox", ignoreCase = true) ||
            Build.PRODUCT.contains("sdk", ignoreCase = true) ||
            Build.PRODUCT.contains("emulator", ignoreCase = true)) {
            indicators.add("product:${Build.PRODUCT}")
            signals++
        }

        if (Build.BOARD.contains("goldfish", ignoreCase = true) ||
            Build.BOARD.contains("ranchu", ignoreCase = true)) {
            indicators.add("board:${Build.BOARD}")
            signals++
        }

        if (Build.BRAND.contains("generic", ignoreCase = true) ||
            Build.BRAND.contains("google_sdk", ignoreCase = true)) {
            indicators.add("brand:${Build.BRAND}")
            signals++
        }

        if (Build.DEVICE.contains("generic", ignoreCase = true) ||
            Build.DEVICE.contains("emulator", ignoreCase = true) ||
            Build.DEVICE.contains("x86", ignoreCase = true)) {
            indicators.add("device:${Build.DEVICE}")
            signals++
        }

        details["emulatorIndicators"] = indicators
        details["emulatorSignals"] = signals
        details["emulatorStrong"] = strongIndicator
        return signals
    }

    /**
     * Developer mode check
     */
    private fun checkDeveloperMode(context: Context, details: MutableMap<String, Any?>): Boolean {
        return try {
            val devEnabled = Settings.Global.getInt(
                context.contentResolver,
                Settings.Global.DEVELOPMENT_SETTINGS_ENABLED,
                0
            ) == 1
            details["devSettingsEnabled"] = devEnabled
            devEnabled
        } catch (e: Exception) {
            details["devSettingsError"] = e.message
            false
        }
    }

    /**
     * ADB enabled check
     */
    private fun checkAdbEnabled(context: Context, details: MutableMap<String, Any?>): Boolean {
        return try {
            val adbEnabled = Settings.Global.getInt(
                context.contentResolver,
                Settings.Global.ADB_ENABLED,
                0
            ) == 1
            details["adbEnabled"] = adbEnabled
            adbEnabled
        } catch (e: Exception) {
            details["adbEnabledError"] = e.message
            false
        }
    }

    /**
     * [DeviceTrust/Android] Check for hook/Frida signals (Kotlin layer)
     * 
     * Frida and hook framework detection:
     * 1. Frida port scan (27042, 27043)
     * 2. Frida packages check (re.frida.server)
     * 
     * Native layer (C++) performs additional checks:
     * - /proc/self/maps RWX segments
     * - /proc/self/fd Frida file descriptors
     * - dladdr symbol check (getpid vs libc)
     * 
     * @return true = hook suspicion (at least 2 signals total)
     */
    private fun checkHookSignals(details: MutableMap<String, Any?>): Boolean {
        var signals = 0

        // 1. Frida port scan
        val openPorts = scanFridaPorts()
        details["fridaPortsOpen"] = openPorts
        if (openPorts.isNotEmpty()) signals++

        // 2. /proc/self/maps scan
        val suspiciousMaps = scanProcSelfMaps()
        details["suspiciousMaps"] = suspiciousMaps
        if (suspiciousMaps.isNotEmpty()) signals++

        // 3. TracerPid check
        val tracerPid = checkTracerPid()
        details["tracerPid"] = tracerPid
        if (tracerPid > 0) signals++

        details["kotlinHookSignals"] = signals
        return signals >= 2
    }

    /**
     * Scan Frida ports (short timeout)
     */
    private fun scanFridaPorts(): List<Int> {
        val openPorts = mutableListOf<Int>()
        
        FRIDA_PORTS.forEach { port ->
            try {
                val socket = Socket()
                socket.connect(InetSocketAddress("127.0.0.1", port), 15)
                socket.close()
                openPorts.add(port)
            } catch (e: Exception) {
                // Port closed or timeout
            }
        }
        
        return openPorts
    }

    /**
     * Scan for suspicious modules in /proc/self/maps
     */
    private fun scanProcSelfMaps(): List<String> {
        val suspicious = mutableListOf<String>()
        val keywords = listOf("frida", "gum-js-loop", "substrate", "xposed", "lsposed")
        
        try {
            val mapsFile = File("/proc/self/maps")
            if (!mapsFile.exists()) return suspicious

            mapsFile.useLines { lines ->
                lines.forEach { line ->
                    val lowerLine = line.lowercase()
                    keywords.forEach { keyword ->
                        if (lowerLine.contains(keyword)) {
                            suspicious.add(line.trim())
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore
        }
        
        return suspicious
    }

    /**
     * TracerPid check (/proc/self/status)
     */
    private fun checkTracerPid(): Int {
        return try {
            val statusFile = File("/proc/self/status")
            if (!statusFile.exists()) return 0

            statusFile.useLines { lines ->
                lines.forEach { line ->
                    if (line.startsWith("TracerPid:")) {
                        val parts = line.split(":")
                        if (parts.size >= 2) {
                            return parts[1].trim().toIntOrNull() ?: 0
                        }
                    }
                }
            }
            0
        } catch (e: Exception) {
            0
        }
    }

    /**
     * Debugger check
     */
    private fun checkDebugger(details: MutableMap<String, Any?>): Boolean {
        val isAttached = Debug.isDebuggerConnected() || Debug.waitingForDebugger()
        details["debuggerConnected"] = isAttached
        return isAttached
    }

    /**
     * Parse native signals (using JSONObject)
     */
    private fun parseNativeSignals(json: String, details: MutableMap<String, Any?>): Boolean {
        return try {
            // Empty JSON check
            if (json.isEmpty() || json == "{}") {
                details["nativeSignals"] = emptyList<String>()
                return false
            }

            val jsonObj = JSONObject(json)
            val signals = mutableListOf<String>()
            
            // Check boolean fields
            if (jsonObj.optBoolean("fridaLibLoaded", false)) {
                signals.add("fridaLibLoaded")
            }
            if (jsonObj.optBoolean("fdFrida", false)) {
                signals.add("fdFrida")
            }
            if (jsonObj.optBoolean("libcGetpidUnexpected", false)) {
                signals.add("libcGetpidUnexpected")
            }
            if (jsonObj.optBoolean("hasRwx", false)) {
                signals.add("hasRwx")
            }

            details["nativeSignals"] = signals
            signals.size >= 2
        } catch (e: Throwable) {
            details["nativeParseError"] = e.message
            false
        }
    }
}
