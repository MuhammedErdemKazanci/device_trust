// [DeviceTrust/Android] DeviceTrustNative - JNI Bridge
// Collects security signals from native C++ layer.
// Fail-soft design: App won't crash if native lib fails to load, returns empty JSON.

package com.mikoloy.device_trust

/**
 * [DeviceTrust/Android] DeviceTrustNative - JNI bridge
 * 
 * Collects security signals from native C++ layer:
 * - /proc/self/maps RWX segment analysis
 * - /proc/self/fd Frida file descriptors
 * - dladdr symbol check (libc getpid)
 * - Suspicious module list
 * 
 * Fail-soft: if lib fails to load, loaded=false; app won't crash
 */
object DeviceTrustNative {

    private var loaded: Boolean = false

    init {
        try {
            System.loadLibrary("device_trust_native")
            loaded = true
        } catch (e: UnsatisfiedLinkError) {
            // Native lib failed to load - fail-soft, app continues
            loaded = false
        } catch (e: Exception) {
            // Unexpected error - fail-soft
            loaded = false
        }
    }

    /**
     * Collects native signals and returns JSON string (private)
     * 
     * JSON format:
     * {
     *   "rwxSegments": <int>,
     *   "hasRwx": <bool>,
     *   "fridaLibLoaded": <bool>,
     *   "fdFrida": <bool>,
     *   "libcGetpidSo": "<string>",
     *   "libcGetpidUnexpected": <bool>,
     *   "nativeTimeMs": <double>,
     *   "suspiciousModules": [<string>, ...]
     * }
     */
    private external fun collectNativeSignals(): String

    /**
     * [DeviceTrust/Android] Collects native signals (fail-soft)
     * 
     * Calls collectNativeSignals() if native lib is loaded.
     * Returns empty JSON on any error.
     * 
     * Fail-soft behavior:
     * - If native lib not loaded → "{}"
     * - If JNI call fails → "{}"
     * - App never crashes
     * 
     * @return JSON string; "{}" if native lib not loaded or error occurs
     */
    fun collectNativeSignalsOrEmpty(): String {
        if (!loaded) {
            return "{}"
        }

        return try {
            collectNativeSignals()
        } catch (e: UnsatisfiedLinkError) {
            "{}"
        } catch (e: Exception) {
            "{}"
        }
    }
}
