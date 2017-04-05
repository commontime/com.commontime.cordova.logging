//
//  MyFormatter.h
//
//  Created by Richard Lewin on 29/11/2016.
//
//

#import <Foundation/Foundation.h>
#import "DDContextFilterLogFormatter.h"
#import "CustomLog.h"

@interface AppFormatter : NSObject <DDLogFormatter> {
    int loggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}

- (void) setRootLogLevel:(DDLogLevel*)logLevel;
- (NSString*)getRootLogLevel;

@end