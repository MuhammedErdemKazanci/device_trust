// [DeviceTrust/iOS][Native] DeviceTrustNative.mm
// Objective-C++ implementation — Mach VM, dyld, dladdr checks

#import "DeviceTrustNative.h"
#import <TargetConditionals.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <sys/time.h>
#if !TARGET_IPHONE_SIMULATOR
  #if __has_include(<sys/ptrace.h>)
    #include <sys/ptrace.h>
  #else
    #include <sys/types.h>
    // Fallback declaration if <sys/ptrace.h> is not available in the SDK
    typedef char* caddr_t;
    extern "C" int ptrace(int, pid_t, caddr_t, int);
    #ifndef PT_DENY_ATTACH
      #define PT_DENY_ATTACH 31
    #endif
  #endif
#endif
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

// Suspicious library names (for lowercase comparison)
static const char* suspiciousNames[] = {
    "frida",
    "fridagadget",
    "substrate",
    "substitute",
    "tweakinject",
    "cynject",
    "libhooker",
    "xcon",
    "sslkillswitch",
    NULL
};

// Fast lowercase substring search
static bool containsSuspicious(const char* path) {
    if (!path) return false;
    
    // Convert path to lowercase (stack buffer)
    char lowerPath[1024];
    size_t len = strlen(path);
    if (len >= sizeof(lowerPath)) len = sizeof(lowerPath) - 1;
    
    for (size_t i = 0; i < len; i++) {
        lowerPath[i] = tolower((unsigned char)path[i]);
    }
    lowerPath[len] = '\0';
    
    // Search for suspicious names
    for (int i = 0; suspiciousNames[i] != NULL; i++) {
        if (strstr(lowerPath, suspiciousNames[i]) != NULL) {
            return true;
        }
    }
    return false;
}

// JSON escape helper (simple)
static NSString* escapeJSON(const char* str) {
    if (!str) return @"";
    NSString* ns = [NSString stringWithUTF8String:str];
    if (!ns) return @"";
    
    // Simple escape: ", \, newline
    ns = [ns stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    ns = [ns stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    ns = [ns stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    ns = [ns stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    return ns;
}

NSString* DTNCollectNativeSignalsJSON(void) {
    struct timeval start, end;
    gettimeofday(&start, NULL);
    
    int rwxSegments = 0;
    bool hasRwx = false;
    NSMutableArray* dyldSuspicious = [NSMutableArray array];
    NSString* envDYLD = @"";
    NSString* libcGetpidImage = @"";
    bool libcGetpidUnexpected = false;
    
    // 1. Mach VM - RWX segment scan
    @try {
        mach_port_t task = mach_task_self();
        vm_address_t address = 0;
        vm_size_t size = 0;
        
        for (int limit = 0; limit < 1000; limit++) { // Infinite-loop guard
            vm_region_basic_info_data_64_t info;
            mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
            mach_port_t objectName = MACH_PORT_NULL;
            
            kern_return_t kr = vm_region_64(task, &address, &size, VM_REGION_BASIC_INFO_64,
                                           (vm_region_info_t)&info, &count, &objectName);
            
            if (kr != KERN_SUCCESS) break;
            
            // Check WRITE and EXECUTE bits
            if ((info.protection & VM_PROT_WRITE) && (info.protection & VM_PROT_EXECUTE)) {
                rwxSegments++;
                hasRwx = true;
                if (rwxSegments >= 4) break; // Early exit (4+ RWX segments suspicious)
            }
            
            address += size;
        }
    } @catch (NSException* e) {
        // Silent fail-soft
    }
    
    // 2. DYLD image list - scan for suspicious libraries
    @try {
        uint32_t imageCount = _dyld_image_count();
        int foundCount = 0;
        
        for (uint32_t i = 0; i < imageCount && foundCount < 8; i++) {
            const char* imageName = _dyld_get_image_name(i);
            if (imageName && containsSuspicious(imageName)) {
                [dyldSuspicious addObject:escapeJSON(imageName)];
                foundCount++;
            }
        }
    } @catch (NSException* e) {
        // Silent fail-soft
    }
    
    // 3. getpid symbol check via dladdr
    @try {
        Dl_info info;
        if (dladdr((void*)getpid, &info) != 0 && info.dli_fname) {
            libcGetpidImage = escapeJSON(info.dli_fname);
            
            // Expected paths: /usr/lib/libSystem*, /usr/lib/system/*
            const char* fname = info.dli_fname;
            if (!(strstr(fname, "/usr/lib/libsystem") || 
                  strstr(fname, "/usr/lib/system/") ||
                  strstr(fname, "/usr/lib/libSystem"))) {
                libcGetpidUnexpected = true;
            }
        }
    } @catch (NSException* e) {
        // Silent fail-soft
    }
    
    // 4. DYLD_INSERT_LIBRARIES environment variable
    @try {
        const char* dyldInsert = getenv("DYLD_INSERT_LIBRARIES");
        if (dyldInsert && strlen(dyldInsert) > 0) {
            envDYLD = escapeJSON(dyldInsert);
        }
    } @catch (NSException* e) {
        // Silent fail-soft
    }
    
    // Duration calculation
    gettimeofday(&end, NULL);
    long timeMs = (end.tv_sec - start.tv_sec) * 1000 + (end.tv_usec - start.tv_usec) / 1000;
    
    // Build JSON (manual, single line)
    NSMutableString* json = [NSMutableString stringWithString:@"{"];
    [json appendFormat:@"\"rwxSegments\":%d,", rwxSegments];
    [json appendFormat:@"\"hasRwx\":%@,", hasRwx ? @"true" : @"false"];
    
    // dyldSuspicious array
    [json appendString:@"\"dyldSuspicious\":["];
    for (NSUInteger i = 0; i < dyldSuspicious.count; i++) {
        [json appendFormat:@"\"%@\"%@", dyldSuspicious[i], (i < dyldSuspicious.count - 1) ? @"," : @""];
    }
    [json appendString:@"],"];
    
    [json appendFormat:@"\"envDYLD\":\"%@\",", envDYLD];
    [json appendFormat:@"\"libcGetpidImage\":\"%@\",", libcGetpidImage];
    [json appendFormat:@"\"libcGetpidUnexpected\":%@,", libcGetpidUnexpected ? @"true" : @"false"];
    [json appendFormat:@"\"nativeTimeMs\":%ld", timeMs];
    [json appendString:@"}"];
    
    #if DEBUG
    NSLog(@"[DeviceTrust/Native] JSON: rwx=%d dyld=%lu env=%@ pid=%@ time=%ldms",
          rwxSegments, (unsigned long)dyldSuspicious.count,
          envDYLD.length > 0 ? @"YES" : @"NO",
          libcGetpidUnexpected ? @"UNEXPECTED" : @"OK",
          timeMs);
    #endif
    
    return json;
}

/// Deny debugger attach (Release + real device; called from Swift)
void DTNDenyDebuggerAttach(void) {
#if !TARGET_IPHONE_SIMULATOR
  #if defined(PT_DENY_ATTACH) || __has_include(<sys/ptrace.h>)
    ptrace(PT_DENY_ATTACH, 0, 0, 0);
  #endif
#endif
}
