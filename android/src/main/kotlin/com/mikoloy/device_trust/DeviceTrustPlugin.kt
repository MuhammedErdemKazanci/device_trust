package com.mikoloy.device_trust

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** DeviceTrustPlugin */
class DeviceTrustPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var appContext: Context

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    appContext = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "device_trust")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getDeviceTrustReport" -> {
        try {
          val report = DeviceTrust.buildReport(appContext)
          val map = mapOf(
            "rootedOrJailbroken" to report.rootedOrJailbroken,
            "emulator" to report.emulator,
            "devModeEnabled" to report.devModeEnabled,
            "adbEnabled" to report.adbEnabled,
            "fridaSuspected" to report.fridaSuspected,
            "debuggerAttached" to report.debuggerAttached,
            "details" to report.details
          )
          result.success(map)
        } catch (e: Exception) {
          result.error("DEVICE_TRUST_ERROR", e.message, null)
        }
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}