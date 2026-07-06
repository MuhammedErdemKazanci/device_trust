// [DeviceTrust/iOS] DeviceTrustNative.h
// Collects native security signals (Objective-C/C++)

#import <Foundation/Foundation.h>
#include <stdbool.h>

// Collect native security signals – returns a JSON string
FOUNDATION_EXPORT NSString * _Nonnull DTNCollectNativeSignalsJSON(void);

// Suspicious dyld image check based on the image basename
// (exposed for regression tests; used internally by the dyld scan)
FOUNDATION_EXPORT bool DTNIsSuspiciousImagePath(const char * _Nullable path);

// Anti-debug wrapper (Release + physical devices, called by Swift)
FOUNDATION_EXPORT void DTNDenyDebuggerAttach(void);
