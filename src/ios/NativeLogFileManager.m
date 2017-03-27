//
//  NativeLogFileManager.m
//
//  Created by Richard Lewin on 25/11/2016.
//
//

#import "NativeLogFileManager.h"

static NSString *const FILE_NAME = @"native.log";

@implementation NativeLogFileManager

- (NSString *)newLogFileName
{
    NSError *error;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray *files = [[fm contentsOfDirectoryAtPath:self.logsDirectory error:&error] mutableCopy];
    if(!error)
    {
        if (files.count == self.maximumNumberOfLogFiles)
        {
            [fm removeItemAtPath:[self.logsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"native %d.log", files.count - 1]] error:nil];
        }
        
        files = [[fm contentsOfDirectoryAtPath:self.logsDirectory error:&error] mutableCopy];
        
        if(files.count > 0)
        {
            files[files.count-1] = @"native 0.log";
            files = [[files sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] mutableCopy];
            files[0] = FILE_NAME;
        }
        
        for (NSString *file in [files reverseObjectEnumerator])
        {
            NSString *filePath = [self.logsDirectory stringByAppendingPathComponent:file];
            NSString *fileNumberString = [self extractNumberFromText:file];
            int fileNumber = [fileNumberString intValue];
            
            NSString* testPath = [self.logsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"native %d.log", fileNumber + 1]];
            if (![fm fileExistsAtPath:testPath])
            {
                [fm moveItemAtPath:filePath toPath:testPath error:nil];
            }
        }
    }
    return FILE_NAME;
}

- (BOOL)isLogFile:(NSString *)fileName {
    return YES;
}

- (NSString*) getLogFilePath
{
    return [self.logsDirectory stringByAppendingPathComponent:FILE_NAME];
}

- (NSString *)extractNumberFromText:(NSString *)text
{
    NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[text componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
}

@end