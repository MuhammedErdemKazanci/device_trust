// [DeviceTrust/iOS] DeviceTrust.swift
// Jailbreak, Hook/Frida, Emulator, Debugger detection (iOS)

import Foundation
import UIKit
import Darwin

// MARK: - DeviceTrustReport

struct DeviceTrustReport {
    let rootedOrJailbroken: Bool
    let emulator: Bool
    let devModeEnabled: Bool
    let adbEnabled: Bool
    let fridaSuspected: Bool
    let debuggerAttached: Bool
    let details: [String: Any]
    
    func toMap() -> [String: Any] {
        return [
            "rootedOrJailbroken": rootedOrJailbroken,
            "emulator": emulator,
            "devModeEnabled": devModeEnabled,
            "adbEnabled": adbEnabled,
            "fridaSuspected": fridaSuspected,
            "debuggerAttached": debuggerAttached,
            "details": details
        ]
    }
}

// MARK: - DeviceTrust

class DeviceTrust {
    
    #if DEBUG
    private static func log(_ scope: String, _ msg: String) {
        print("[DeviceTrust/\(scope)] \(msg)")
    }
    #endif
    
    // Known jailbreak paths and files
    private static let jailbreakPaths = [
        "/Applications/Cydia.app",
        "/Applications/Sileo.app",
        "/Applications/Zebra.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/Library/MobileSubstrate/DynamicLibraries",
        "/usr/sbin/sshd",
        "/usr/bin/sshd",
        "/usr/libexec/sftp-server",
        "/etc/apt",
        "/etc/apt/sources.list.d",
        "/private/var/lib/apt",
        "/private/var/lib/cydia",
        "/private/var/mobile/Library/SBSettings/Themes",
        "/private/var/tmp/cydia.log",
        "/var/jb",
        "/var/lib/cydia",
        "/bin/bash",
        "/bin/sh",
        "/usr/bin/ssh",
        "/.installed_unc0ver",
        "/.bootstrapped_electra",
        "/usr/share/jailbreak/injectme.plist" // Jailbreak marker file
    ]
    
    // URL Schemes (must be declared in Info.plist)
    private static let jailbreakSchemes = [ // Jailbreak tool URL schemes
        "cydia://",
        "sileo://",
        "zbra://",
        "filza://",
        "undecimus://",
        "activator://"
    ]
    
    // MARK: - buildReport (Main function)
    
    static func buildReport() -> DeviceTrustReport {
        var details: [String: Any] = [:]
        
        // 1. Simulator detection
        let isEmulator: Bool
        #if targetEnvironment(simulator)
        isEmulator = true
        #else
        isEmulator = false
        #endif
        details["simulator"] = isEmulator
        
        // 2. Jailbreak detection
        let jbPathHits = checkJailbreakPaths() // Check for jailbreak files
        let jbWriteTest = checkSandboxEscape() // Test sandbox restrictions
        let urlSchemeHits = checkURLSchemes() // Check for jailbreak URL schemes
        
        details["jbPathHits"] = jbPathHits
        details["jbWriteTest"] = jbWriteTest
        details["urlSchemeHits"] = urlSchemeHits
        
        // 3. Native signals (Hook/Frida)
        let nativeSignals = collectNativeSignals()
        
        // Append native details to details map
        details["nativeDyldSuspicious"] = nativeSignals.dyldSuspicious
        details["nativeHasRwx"] = nativeSignals.hasRwx
        details["nativeRwxSegments"] = nativeSignals.rwxSegments
        details["nativeEnvDYLD"] = nativeSignals.envDYLD
        details["nativeLibcGetpidUnexpected"] = nativeSignals.libcGetpidUnexpected
        details["nativeLibcGetpidImage"] = nativeSignals.libcGetpidImage
        details["nativeTimeMs"] = nativeSignals.nativeTimeMs
        
        // 4. Debugger detection
        let debuggerAttached = isDebuggerAttached()
        details["debuggerViaSysctl"] = debuggerAttached
        
        // 5. Frida/Hook decision (raw calculation)
        let shouldIgnoreRwx = isEmulator
        let fridaRaw = (!nativeSignals.dyldSuspicious.isEmpty) ||
                       (!nativeSignals.envDYLD.isEmpty) ||
                       nativeSignals.libcGetpidUnexpected ||
                       (debuggerAttached && !nativeSignals.dyldSuspicious.isEmpty) ||
                       (!shouldIgnoreRwx && nativeSignals.hasRwx && nativeSignals.rwxSegments >= 4)
        
        // iOS'ta DevMode ve ADB yok
        let devModeEnabled = false
        let adbEnabled = false
        
        // Raw jailbreak decision
        let rootedRaw = !jbPathHits.isEmpty || jbWriteTest || !urlSchemeHits.isEmpty
        
        // --- Simulator cleanups ---
        let rootedFinal = isEmulator ? false : rootedRaw
        let fridaFinal  = isEmulator ? false : fridaRaw
        details["simAdjusted"] = isEmulator
        if isEmulator {
            details["simIgnored"] = ["rooted": rootedRaw, "frida": fridaRaw]
        }
        
        // Debug log (DEBUG only)
        #if DEBUG
        var reasons: [String] = []
        if isEmulator { reasons.append("emu") }
        if debuggerAttached { reasons.append("dbg") }
        if rootedFinal { reasons.append("root") }
        if fridaFinal { reasons.append("hook") }
        let reasonStr = reasons.isEmpty ? "none" : reasons.joined(separator: "|")
        
        log("iOS", "rooted=\(rootedFinal) emu=\(isEmulator) frida=\(fridaFinal) dbg=\(debuggerAttached) reason=\(reasonStr) " +
            "jbPaths=\(jbPathHits.count) jbWrite=\(jbWriteTest) urls=\(urlSchemeHits.count) " +
            "dyld=\(nativeSignals.dyldSuspicious.count) envDYLD=\(!nativeSignals.envDYLD.isEmpty) " +
            "rwx=\(nativeSignals.rwxSegments) pidUnexpected=\(nativeSignals.libcGetpidUnexpected)")
        #endif
        
        return DeviceTrustReport(
            rootedOrJailbroken: rootedFinal,
            emulator: isEmulator,
            devModeEnabled: devModeEnabled,
            adbEnabled: adbEnabled,
            fridaSuspected: fridaFinal,
            debuggerAttached: debuggerAttached,
            details: details
        )
    }
    
    // MARK: - Jailbreak Detection
    
    /// Check for known jailbreak paths
    private static func checkJailbreakPaths() -> [String] {
        var hits: [String] = []
        let fileManager = FileManager.default
        
        for path in jailbreakPaths { // Iterate known jailbreak file paths
            // Check both file existence and symbolic links
            if fileManager.fileExists(atPath: path) {
                hits.append(path)
                if hits.count >= 5 { break } // Early exit
            } else {
                // Symbolic link check using lstat (lower level)
                var statInfo = stat()
                if lstat(path, &statInfo) == 0 {
                    hits.append(path)
                    if hits.count >= 5 { break }
                }
            }
        }
        
        return hits
    }
    
    /// Test sandbox escape (sandbox is relaxed on jailbroken devices)
    private static func checkSandboxEscape() -> Bool {
        let testPath = "/private/jb_test.txt"
        let testData = "test".data(using: .utf8)
        
        // Attempt to write outside sandbox
        if FileManager.default.createFile(atPath: testPath, contents: testData, attributes: nil) {
            // Write successful → possible jailbreak, cleanup
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        }
        
        return false
    }
    
    /// URL scheme query (must be declared in Info.plist)
    private static func checkURLSchemes() -> [String] {
        var hits: [String] = []
        let app: UIApplication = {
            if Thread.isMainThread {
                return UIApplication.shared
            } else {
                var tmp: UIApplication?
                DispatchQueue.main.sync { tmp = UIApplication.shared }
                return tmp!
            }
        }()
        
        for scheme in jailbreakSchemes { // Check if jailbreak URL schemes are available
            if let url = URL(string: scheme), app.canOpenURL(url) {
                hits.append(scheme)
            }
        }
        
        return hits
    }
    
    // MARK: - Native Signals
    
    private struct NativeSignals {
        let rwxSegments: Int
        let hasRwx: Bool
        let dyldSuspicious: [String]
        let envDYLD: String
        let libcGetpidImage: String
        let libcGetpidUnexpected: Bool
        let nativeTimeMs: Int // ms
    }
    
    /// Collect and parse signals from native C++ layer
    private static func collectNativeSignals() -> NativeSignals {
        // DTNCollectNativeSignalsJSON is bridged as non-optional String (see _Nonnull in header)
        let jsonString = DTNCollectNativeSignalsJSON()

        guard let jsonData = jsonString.data(using: .utf8),
              let json = (try? JSONSerialization.jsonObject(with: jsonData)) as? [String: Any] else {
            // Parse error → safe defaults
            return NativeSignals(
                rwxSegments: 0,
                hasRwx: false,
                dyldSuspicious: [],
                envDYLD: "",
                libcGetpidImage: "",
                libcGetpidUnexpected: false,
                nativeTimeMs: 0 // ms
            )
        }

        return NativeSignals(
            rwxSegments: json["rwxSegments"] as? Int ?? 0,
            hasRwx: json["hasRwx"] as? Bool ?? false,
            dyldSuspicious: json["dyldSuspicious"] as? [String] ?? [],
            envDYLD: json["envDYLD"] as? String ?? "",
            libcGetpidImage: json["libcGetpidImage"] as? String ?? "",
            libcGetpidUnexpected: json["libcGetpidUnexpected"] as? Bool ?? false,
            nativeTimeMs: json["nativeTimeMs"] as? Int ?? 0
        )
    }
    
    // MARK: - Debugger Detection
    
    /// sysctl-based debugger attachment check (Apple example)
    private static func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        if result != 0 {
            return false
        }
        
        // P_TRACED flag set indicates debugger attached
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    // MARK: - Anti-Debug (Release only)
    
    /// ptrace(PT_DENY_ATTACH) - Release only + Physical device
    static func denyDebuggerAttachIfNeeded() {
        #if !DEBUG && !targetEnvironment(simulator)
        DTNDenyDebuggerAttach()
        #endif
    }
}
