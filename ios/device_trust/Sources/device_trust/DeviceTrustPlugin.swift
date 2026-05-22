import Flutter
import UIKit

public class DeviceTrustPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "device_trust", binaryMessenger: registrar.messenger())
    let instance = DeviceTrustPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDeviceTrustReport":
      // Call DeviceTrust.buildReport() defined in DeviceTrust.swift
      let report = DeviceTrust.buildReport()
      result(report.toMap())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}