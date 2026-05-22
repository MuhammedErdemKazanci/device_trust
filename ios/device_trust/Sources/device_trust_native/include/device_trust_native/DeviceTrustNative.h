// [DeviceTrust/iOS] DeviceTrustNative.h
// Collects native security signals (Objective-C/C++)

#import <Foundation/Foundation.h>

// Collect native security signals – returns a JSON string
FOUNDATION_EXPORT NSString * _Nonnull DTNCollectNativeSignalsJSON(void);

// Anti-debug wrapper (Release + physical devices, called by Swift)
FOUNDATION_EXPORT void DTNDenyDebuggerAttach(void);
