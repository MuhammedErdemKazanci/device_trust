import Flutter
import UIKit
import XCTest


@testable import device_trust
#if canImport(device_trust_native)
import device_trust_native
#endif

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  func testUnknownMethodReturnsNotImplemented() {
    let plugin = DeviceTrustPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertTrue(result as? NSObject === FlutterMethodNotImplemented)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }

  // Regression test for issue #8: Apple's DTXConnectionServices framework
  // must not be flagged as suspicious (contains "xcon" as a substring).
  func testDTXConnectionServicesIsNotSuspicious() {
    XCTAssertFalse(DTNIsSuspiciousImagePath(
      "/System/Library/PrivateFrameworks/DTXConnectionServices.framework/DTXConnectionServices"))
  }

  func testBenignSystemImagesAreNotSuspicious() {
    XCTAssertFalse(DTNIsSuspiciousImagePath("/usr/lib/libSystem.B.dylib"))
    XCTAssertFalse(DTNIsSuspiciousImagePath(
      "/System/Library/Frameworks/UIKit.framework/UIKit"))
    // Suspicious token in a directory component must not trigger a match
    XCTAssertFalse(DTNIsSuspiciousImagePath("/var/frida/libSafe.dylib"))
    XCTAssertFalse(DTNIsSuspiciousImagePath(nil))
    XCTAssertFalse(DTNIsSuspiciousImagePath(""))
  }

  func testKnownInjectionImagesAreSuspicious() {
    XCTAssertTrue(DTNIsSuspiciousImagePath("/usr/lib/frida/frida-agent.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath(
      "/private/var/containers/Bundle/Application/App.app/Frameworks/FridaGadget.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath("/usr/lib/libsubstrate.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath(
      "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate"))
    XCTAssertTrue(DTNIsSuspiciousImagePath("/usr/lib/libsubstitute.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath("/usr/lib/TweakInject.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath("/usr/lib/libcycript.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath("/usr/bin/cynject"))
    XCTAssertTrue(DTNIsSuspiciousImagePath("/usr/lib/libhooker.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath(
      "/Library/MobileSubstrate/DynamicLibraries/SSLKillSwitch2.dylib"))
    // xCon-related images (boundary-aware match)
    XCTAssertTrue(DTNIsSuspiciousImagePath(
      "/Library/MobileSubstrate/DynamicLibraries/xCon.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath(
      "/Library/MobileSubstrate/DynamicLibraries/xCon0.dylib"))
    XCTAssertTrue(DTNIsSuspiciousImagePath("/usr/lib/libxcon.dylib"))
  }

}
