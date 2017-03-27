//
//  ClientFileManager.h
//
//  Created by Richard Lewin on 25/11/2016.
//
//

#import "DDFileLogger.h"

@interface ClientLogFileManager : DDLogFileManagerDefault

- (NSString *)newLogFileName;
- (BOOL)isLogFile;
- (NSString*) getLogFilePath;

@end
