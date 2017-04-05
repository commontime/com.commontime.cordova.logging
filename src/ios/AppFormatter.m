//
//  MyFormatter.m
//
//  Created by Richard Lewin on 29/11/2016.
//
//

#import "AppFormatter.h"

static NSString *const LOG_LEVEL_INFO = @"INFO";
static NSString *const LOG_LEVEL_DEBUG = @"DEBUG";
static NSString *const LOG_LEVEL_WARNING = @"WARN";
static NSString *const LOG_LEVEL_ERROR = @"ERROR";

@implementation AppFormatter
{
    NSString *logRootLevel;
}

- (id)init
{
    if((self = [super init])) {
        threadUnsafeDateFormatter = [[NSDateFormatter alloc] init];
        [threadUnsafeDateFormatter setDateFormat:@"d-M-yyyy HH:mm:ss.SSS"];
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    if([logMessage.message isEqualToString:@""])
        return logMessage.message;
    
    if(logRootLevel == nil)
        logRootLevel = @"";
    
    if(![self isLoglevelHighEnough:logMessage])
        return nil;
    
    NSString *dateAndTime = [threadUnsafeDateFormatter stringFromDate:(logMessage.timestamp)];
    
    if (logMessage.context == LOG_CONTEXT_APP || logMessage.context == 0)
        return [NSString stringWithFormat:@"%@", logMessage.message];
    else
        return nil;
}

- (void)setRootLogLevel:(DDLogLevel)logLevel
{
    logRootLevel = [self getRootLogLevelString:logLevel];
}

- (NSString*)getRootLogLevel
{
    return logRootLevel;
}

- (void)didAddToLogger:(id <DDLogger>)logger
{
    loggerCount++;
    NSAssert(loggerCount <= 1, @"This logger isn't thread-safe");
}

- (void)willRemoveFromLogger:(id <DDLogger>)logger
{
    loggerCount--;
}

- (BOOL)isLoglevelHighEnough:(DDLogMessage*)message
{
    NSString *messageLogLvel = [self getRootLogLevelString:message.level];
    
    if([logRootLevel isEqualToString:LOG_LEVEL_DEBUG])
    {
        if([messageLogLvel isEqualToString:LOG_LEVEL_DEBUG] || [messageLogLvel isEqualToString:LOG_LEVEL_INFO] || [messageLogLvel isEqualToString:LOG_LEVEL_WARNING] || [messageLogLvel isEqualToString:LOG_LEVEL_ERROR])
            return true;
        else
            return false;
    }
    else if([logRootLevel isEqualToString:LOG_LEVEL_INFO])
    {
        if([messageLogLvel isEqualToString:LOG_LEVEL_INFO] || [messageLogLvel isEqualToString:LOG_LEVEL_WARNING] || [messageLogLvel isEqualToString:LOG_LEVEL_ERROR])
            return true;
        else
            return false;
    }
    else if([logRootLevel isEqualToString:LOG_LEVEL_WARNING])
    {
        if([messageLogLvel isEqualToString:LOG_LEVEL_WARNING] || [messageLogLvel isEqualToString:LOG_LEVEL_ERROR])
            return true;
        else
            return false;
    }
    else if([logRootLevel isEqualToString:LOG_LEVEL_ERROR])
    {
        if([messageLogLvel isEqualToString:LOG_LEVEL_ERROR])
            return true;
        else
            return false;
    }
    
    return true;
}

- (NSString*)getRootLogLevelString:(DDLogLevel)logLevel
{
    switch (logLevel) {
        case DDLogLevelError    : return LOG_LEVEL_ERROR;
        case DDLogLevelWarning  : return LOG_LEVEL_WARNING;
        case DDLogLevelInfo     : return LOG_LEVEL_INFO;
        case DDLogLevelDebug    : return LOG_LEVEL_DEBUG;
        default                : return @"VERBOSE";
    }
}

@end