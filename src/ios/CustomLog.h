//
//  MyLog.h
//
//  Created by Richard Lewin on 29/11/2016.
//
//

#import "DDLog.h"

#define LOG_CONTEXT_DEVELOPER 1
#define LOG_CONTEXT_CLIENT 2
#define LOG_CONTEXT_NATIVE 3

#define DeveloperLogInfo(frmt, ...)   LOG_MAYBE(NO, DDLogLevelInfo, DDLogFlagInfo, LOG_CONTEXT_DEVELOPER, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ClientLogInfo(frmt, ...)   LOG_MAYBE(NO, DDLogLevelInfo, DDLogFlagInfo, LOG_CONTEXT_CLIENT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define NativeLogInfo(frmt, ...)   LOG_MAYBE(NO, DDLogLevelInfo, DDLogFlagInfo, LOG_CONTEXT_NATIVE, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define DeveloperLogDebug(frmt, ...)   LOG_MAYBE(NO, DDLogLevelDebug, DDLogFlagDebug, LOG_CONTEXT_DEVELOPER, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ClientLogDebug(frmt, ...)   LOG_MAYBE(NO, DDLogLevelDebug, DDLogFlagDebug, LOG_CONTEXT_CLIENT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define NativeLogDebug(frmt, ...)   LOG_MAYBE(NO, DDLogLevelDebug, DDLogFlagDebug, LOG_CONTEXT_NATIVE, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define DeveloperLogWarn(frmt, ...)   LOG_MAYBE(NO, DDLogLevelWarning, DDLogFlagWarning, LOG_CONTEXT_DEVELOPER, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ClientLogWarn(frmt, ...)   LOG_MAYBE(NO, DDLogLevelWarning, DDLogFlagWarning, LOG_CONTEXT_CLIENT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define NativeLogWarn(frmt, ...)   LOG_MAYBE(NO, DDLogLevelWarning, DDLogFlagWarning, LOG_CONTEXT_NATIVE, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define DeveloperLogError(frmt, ...)   LOG_MAYBE(NO, DDLogLevelError, DDLogFlagError, LOG_CONTEXT_DEVELOPER, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define ClientLogError(frmt, ...)   LOG_MAYBE(NO, DDLogLevelError, DDLogFlagError, LOG_CONTEXT_CLIENT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define NativeLogError(frmt, ...)   LOG_MAYBE(NO, DDLogLevelError, DDLogFlagError, LOG_CONTEXT_NATIVE, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

