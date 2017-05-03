#import "Logging.h"
#import "Objective-Zip.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

static NSString *const NO_MSG = @"No message provided";
static NSString *const NO_LOGGERS_MSG = @"No logger or loggers specified";
static NSString *const LOGGING_DISABLED = @"Logging is disabled";

static NSString *const CLIENT_DESTINATION = @"client";
static NSString *const APP_DESTINATION = @"app";
static NSString *const NATIVE_DESTINATION = @"native";

static NSString *const LOG_LEVEL_OFF = @"off";
static NSString *const LOG_LEVEL_INFO = @"info";
static NSString *const LOG_LEVEL_DEBUG = @"debug";
static NSString *const LOG_LEVEL_WARNING = @"warn";
static NSString *const LOG_LEVEL_ERROR = @"error";

static NSString *const CLIENT_LOG_FILE_NAME = @"client.log";
static NSString *const APP_LOG_FILE_NAME = @"app.log";
static NSString *const NATIVE_LOG_FILE_NAME = @"native.log";

static NSString *const LOG_FILES_ZIP_NAME = @"logs.zip";

static NSString *const LOGGING_ENABLED_KEY = @"loggingEnabled";
static NSString *const CLIENT_LOGGING_ENABLED_KEY = @"clientLoggingEnabled";
static NSString *const APP_LOGGING_ENABLED_KEY = @"appLoggingEnabled";
static NSString *const NATIVE_LOGGING_ENABLED_KEY = @"nativeLoggingEnabled";
static NSString *const CLIENT_ROOT_LOG_LEVEL_KEY = @"clientRootLogLevel";
static NSString *const APP_ROOT_LOG_LEVEL_KEY = @"appRootLogLevel";
static NSString *const NATIVE_ROOT_LOG_LEVEL_KEY = @"nativeRootLogLevel";
static NSString *const CLIENT_MAX_FILE_SIZE_KEY = @"clientMaxFileSize";
static NSString *const CLIENT_MAX_NUMBER_OF_LOG_FILES_KEY = @"clientMaxNumberOfLogFiles";
static NSString *const APP_MAX_FILE_SIZE_KEY = @"appMaxFileSize";
static NSString *const APP_MAX_NUMBER_OF_LOG_FILES_KEY = @"appMaxNumberOfLogFiles";
static NSString *const NATIVE_MAX_FILE_SIZE_KEY = @"nativeMaxFileSize";
static NSString *const NATIVE_MAX_NUMBER_OF_LOG_FILES_KEY = @"nativeMaxNumberOfLogFiles";

@implementation Logging
{
    NSMutableDictionary *loggers;
    NSString *documentsDirectoryPath;
    NSString *logFileDirectoryPath;
    BOOL loggingEnabled;
    BOOL appLoggingEnabled;
    BOOL clientLoggingEnabled;
    BOOL nativeLoggingEnabled;
}

- (void)pluginInitialize
{
    documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    logFileDirectoryPath = [documentsDirectoryPath stringByAppendingPathComponent:@"logs"];
    loggingEnabled = NO;
    appLoggingEnabled = NO;
    clientLoggingEnabled = NO;
    nativeLoggingEnabled = NO;
    
    [self setupLoggers];
    
    NSString* clientRootLogLevel;
    NSString* appRootLogLevel;
    NSString* nativeRootLogLevel;
    long clientMaxFileSize;
    int clientMaxNumberOfLogFiles;
    long appMaxFileSize;
    int appMaxNumberOfLogFiles;
    long nativeMaxFileSize;
    int nativeMaxNumberOfLogFiles;
    
    if([self isFirstRun])
    {
        loggingEnabled = [[self.commandDelegate.settings objectForKey:[LOGGING_ENABLED_KEY lowercaseString]] boolValue];
        
        clientRootLogLevel = [self.commandDelegate.settings objectForKey:[CLIENT_ROOT_LOG_LEVEL_KEY lowercaseString]];
        appRootLogLevel = [self.commandDelegate.settings objectForKey:[APP_ROOT_LOG_LEVEL_KEY lowercaseString]];
        nativeRootLogLevel = [self.commandDelegate.settings objectForKey:[NATIVE_ROOT_LOG_LEVEL_KEY lowercaseString]];
    
        clientMaxFileSize = [[self.commandDelegate.settings objectForKey:[CLIENT_MAX_FILE_SIZE_KEY lowercaseString]] longLongValue];
        clientMaxNumberOfLogFiles = [[self.commandDelegate.settings objectForKey:[CLIENT_MAX_NUMBER_OF_LOG_FILES_KEY lowercaseString]] intValue];
    
        appMaxFileSize = [[self.commandDelegate.settings objectForKey:[APP_MAX_FILE_SIZE_KEY lowercaseString]] longLongValue];
        appMaxNumberOfLogFiles = [[self.commandDelegate.settings objectForKey:[APP_MAX_NUMBER_OF_LOG_FILES_KEY lowercaseString]] intValue];
    
        nativeMaxFileSize = [[self.commandDelegate.settings objectForKey:[NATIVE_MAX_FILE_SIZE_KEY lowercaseString]] longLongValue];
        nativeMaxNumberOfLogFiles = [[self.commandDelegate.settings objectForKey:[NATIVE_MAX_NUMBER_OF_LOG_FILES_KEY lowercaseString]] intValue];
    }
    else
    {
        loggingEnabled = [self getBoolFromPrefs:LOGGING_ENABLED_KEY];
        appLoggingEnabled = [self getBoolFromPrefs:APP_LOGGING_ENABLED_KEY];
        clientLoggingEnabled = [self getBoolFromPrefs:CLIENT_LOGGING_ENABLED_KEY];
        nativeLoggingEnabled = [self getBoolFromPrefs:NATIVE_LOGGING_ENABLED_KEY];
        
        clientRootLogLevel = [self getStringFromPrefs:CLIENT_ROOT_LOG_LEVEL_KEY];
        appRootLogLevel = [self getStringFromPrefs:APP_ROOT_LOG_LEVEL_KEY];
        nativeRootLogLevel = [self getStringFromPrefs:NATIVE_ROOT_LOG_LEVEL_KEY];
        
        clientMaxFileSize = [self getLongFromPrefs:CLIENT_MAX_FILE_SIZE_KEY];
        clientMaxNumberOfLogFiles = [self getIntFromPrefs:CLIENT_MAX_NUMBER_OF_LOG_FILES_KEY];
        
        appMaxFileSize = [self getLongFromPrefs:APP_MAX_FILE_SIZE_KEY];
        appMaxNumberOfLogFiles = [self getIntFromPrefs:APP_MAX_NUMBER_OF_LOG_FILES_KEY];
        
        nativeMaxFileSize = [self getLongFromPrefs:NATIVE_MAX_FILE_SIZE_KEY];
        nativeMaxNumberOfLogFiles = [self getIntFromPrefs:NATIVE_MAX_NUMBER_OF_LOG_FILES_KEY];
    }
    
    if(clientRootLogLevel != nil)
    {
        [self setRootLogLevelPrivate: clientRootLogLevel: CLIENT_DESTINATION];
    }
    
    if(appRootLogLevel != nil)
    {
        [self setRootLogLevelPrivate: appRootLogLevel: APP_DESTINATION];
    }
    
    if(nativeRootLogLevel != nil)
    {
        [self setRootLogLevelPrivate: nativeRootLogLevel: NATIVE_DESTINATION];
    }
    
    if(clientMaxFileSize > 0 || clientMaxNumberOfLogFiles > 0)
    {
        NSMutableDictionary *clientSettings = [[NSMutableDictionary alloc] init];
        if(clientMaxFileSize > 0)
        {
            [clientSettings setObject:[NSNumber numberWithLong:clientMaxFileSize] forKey:@"maxFileSize"];
        }
        if(clientMaxNumberOfLogFiles > 0)
        {
            [clientSettings setObject:[NSNumber numberWithInt:clientMaxNumberOfLogFiles] forKey:@"maxNumberOfFiles"];
        }
        [self configurePrivate: clientSettings :CLIENT_DESTINATION];
    }
    
    if(appMaxFileSize > 0 || appMaxNumberOfLogFiles > 0)
    {
        NSMutableDictionary *appSettings = [[NSMutableDictionary alloc] init];
        if(appMaxFileSize > 0)
        {
            [appSettings setObject:[NSNumber numberWithLong:appMaxFileSize] forKey:@"maxFileSize"];
        }
        if(appMaxNumberOfLogFiles > 0)
        {
            [appSettings setObject:[NSNumber numberWithInt:appMaxNumberOfLogFiles] forKey:@"maxNumberOfFiles"];
        }
        [self configurePrivate: appSettings :APP_DESTINATION];
    }
    
    if(nativeMaxFileSize > 0 || nativeMaxNumberOfLogFiles > 0)
    {
        NSMutableDictionary *nativeSettings = [[NSMutableDictionary alloc] init];
        if(nativeMaxFileSize > 0)
        {
            [nativeSettings setObject:[NSNumber numberWithLong:nativeMaxFileSize] forKey:@"maxFileSize"];
        }
        if(nativeMaxNumberOfLogFiles > 0)
        {
            [nativeSettings setObject:[NSNumber numberWithInt:nativeMaxNumberOfLogFiles] forKey:@"maxNumberOfFiles"];
        }
        [self configurePrivate: nativeSettings :NATIVE_DESTINATION];
    }
}

- (void)logInfo:(CDVInvokedUrlCommand*)command
{
    if(!loggingEnabled)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:LOGGING_DISABLED];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString *msg = [command.arguments objectAtIndex:0];
    
    if([self isNilOrEmpty:msg])
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NO_MSG];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSArray *loggerArray = [self createLoggerArrayFromArgument: [command.arguments objectAtIndex:1]];
    
    if(loggerArray == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NO_LOGGERS_MSG];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    [self logInfoPrivate: msg: loggerArray];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)logDebug:(CDVInvokedUrlCommand*)command
{
    if(!loggingEnabled)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:LOGGING_DISABLED];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString *msg = [command.arguments objectAtIndex:0];
    
    if([self isNilOrEmpty:msg])
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NO_MSG];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSArray *loggerArray = [self createLoggerArrayFromArgument: [command.arguments objectAtIndex:1]];
    
    if(loggerArray == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NO_LOGGERS_MSG];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    [self logDebugPrivate: msg: loggerArray];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)logWarn:(CDVInvokedUrlCommand*)command
{
    if(!loggingEnabled)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:LOGGING_DISABLED];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString *msg = [command.arguments objectAtIndex:0];
    
    if([self isNilOrEmpty:msg])
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NO_MSG];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSArray *loggerArray = [self createLoggerArrayFromArgument: [command.arguments objectAtIndex:1]];
    
    if(loggerArray == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NO_LOGGERS_MSG];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    [self logWarnPrivate: msg: loggerArray];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)logError:(CDVInvokedUrlCommand*)command
{
    if(!loggingEnabled)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:LOGGING_DISABLED];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSString *msg = [command.arguments objectAtIndex:0];
    
    if([self isNilOrEmpty:msg])
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NO_MSG];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    NSArray *loggerArray = [self createLoggerArrayFromArgument: [command.arguments objectAtIndex:1]];
    
    if(loggerArray == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:NO_LOGGERS_MSG];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    [self logErrorPrivate: msg: loggerArray];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)logMessages:(CDVInvokedUrlCommand *)command
{
    if(!loggingEnabled)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:LOGGING_DISABLED];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }

    NSDictionary *messages = [command.arguments objectAtIndex:0];
    for(NSDictionary *message in messages)
    {
        NSString *logLevel = message[@"logLevel"];
        
        NSArray *loggerArray = [self createLoggerArrayFromArgument: message[@"destination"]];
        
        if(loggerArray == nil)
            continue;
        
        if([logLevel caseInsensitiveCompare:LOG_LEVEL_INFO] == NSOrderedSame)
        {
            [self logInfoPrivate:message[@"message"] :loggerArray];
        }
        else if([logLevel caseInsensitiveCompare:LOG_LEVEL_DEBUG] == NSOrderedSame)
        {
            [self logDebugPrivate:message[@"message"] :loggerArray];
        }
        else if([logLevel caseInsensitiveCompare:LOG_LEVEL_WARNING] == NSOrderedSame)
        {
            [self logWarnPrivate:message[@"message"] :loggerArray];
        }
        else if([logLevel caseInsensitiveCompare:LOG_LEVEL_ERROR] == NSOrderedSame)
        {
            [self logErrorPrivate:message[@"message"] :loggerArray];
        }
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString: @"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setRootLogLevel:(CDVInvokedUrlCommand*)command
{
    NSString *desiredLevel = [command.arguments objectAtIndex:0];
    NSString *destination = [command.arguments objectAtIndex:1];
    
    if([self isNilOrEmpty:desiredLevel])
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No log level specified"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    if(destination == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No destination specified"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }

    bool set = [self setRootLogLevelPrivate: desiredLevel: destination];
    
    if(set)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
    }
    else
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to set root level"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
    }
}

- (void)getRootLogLevel:(CDVInvokedUrlCommand*)command
{
    NSString *destination = [command.arguments objectAtIndex:0];
    
    if(destination == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No destination specified"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }

    NSString *level = [self getRootLogLevelPrivate:destination];
    
    if(level != nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:level];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];

    }
    else
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Destination not found"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;

    }
}

- (void)getLogFilePaths:(CDVInvokedUrlCommand*)command
{
    NSDictionary *paths = [self getLogFilePathsPrivate];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary:paths];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSDictionary*)getLogFilePathsPrivate
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSMutableDictionary *paths = [[NSMutableDictionary alloc] init];
    
    DDFileLogger *logger = [loggers objectForKey:CLIENT_DESTINATION];
    NSString *clientLoggerFilePath = [(ClientLogFileManager*)logger.logFileManager getLogFilePath];
    NSDictionary *clientFileAttributes = [manager attributesOfItemAtPath:clientLoggerFilePath error:nil];
    unsigned long long clientFileSize = [clientFileAttributes fileSize];
    if (clientFileAttributes && clientFileSize > 0)
    {
        [paths setValue:clientLoggerFilePath forKey:CLIENT_DESTINATION];
    }
    
    logger = [loggers objectForKey:APP_DESTINATION];
    NSString *appLoggerFilePath = [(AppLogFileManager*)logger.logFileManager getLogFilePath];
    NSDictionary *appAttributes = [manager attributesOfItemAtPath:appLoggerFilePath error:nil];
    unsigned long long appFileSize = [appAttributes fileSize];
    if (appAttributes && appFileSize > 0)
    {
        [paths setValue:appLoggerFilePath forKey:APP_DESTINATION];
    }
    
    logger = [loggers objectForKey:NATIVE_DESTINATION];
    NSString *nativeLoggerFilePath = [(NativeLogFileManager*)logger.logFileManager getLogFilePath];
    NSDictionary *nativeAttributes = [manager attributesOfItemAtPath:nativeLoggerFilePath error:nil];
    unsigned long long nativeFileSize = [nativeAttributes fileSize];
    if (nativeAttributes && nativeFileSize > 0)
    {
        [paths setValue:nativeLoggerFilePath forKey:NATIVE_DESTINATION];
    }
    
    return paths;
}

- (void)getArchivedLogFilePaths:(CDVInvokedUrlCommand *)command
{
    NSDictionary *paths = [self getArchivedLogFilePathsPrivate];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsDictionary:paths];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSDictionary*)getArchivedLogFilePathsPrivate
{
    NSMutableDictionary *paths = [[NSMutableDictionary alloc] init];
    
    DDFileLogger *logger = [loggers objectForKey:CLIENT_DESTINATION];
    NSString *logFileDir = [(ClientLogFileManager*)logger.logFileManager logsDirectory];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logFileDir error:nil];
    NSMutableArray *clientPaths = [[NSMutableArray alloc] init];
    for(NSString *file in files)
    {
        if(![file isEqualToString:CLIENT_LOG_FILE_NAME])
        {
            [clientPaths addObject:[logFileDir stringByAppendingPathComponent:file]];
        }
    }
    if(clientPaths.count > 0)
    {
        [paths setObject:clientPaths forKey:CLIENT_DESTINATION];
    }
    
    logger = [loggers objectForKey:APP_DESTINATION];
    logFileDir = [(AppLogFileManager*)logger.logFileManager logsDirectory];
    files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logFileDir error:nil];
    NSMutableArray *appPaths = [[NSMutableArray alloc] init];
    for(NSString *file in files)
    {
        if(![file isEqualToString:APP_LOG_FILE_NAME])
        {
            [appPaths addObject:[logFileDir stringByAppendingPathComponent:file]];
        }
    }
    if(appPaths.count > 0)
    {
        [paths setObject:appPaths forKey:APP_DESTINATION];
    }
    
    logger = [loggers objectForKey:NATIVE_DESTINATION];
    logFileDir = [(NativeLogFileManager*)logger.logFileManager logsDirectory];
    files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logFileDir error:nil];
    NSMutableArray *nativePaths = [[NSMutableArray alloc] init];

    for(NSString *file in files)
    {
        if(![file isEqualToString:NATIVE_LOG_FILE_NAME])
        {
            [nativePaths addObject:[logFileDir stringByAppendingPathComponent:file]];
        }
    }
    if(nativePaths.count > 0)
    {
        [paths setObject:nativePaths forKey:NATIVE_DESTINATION];
    }
    
    return paths;
}

- (void) makeFilesPublic:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsArray:[command.arguments objectAtIndex:0]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) removePublicFiles:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)configure:(CDVInvokedUrlCommand *)command
{
    NSDictionary *settings = [command.arguments objectAtIndex:0];
    NSObject *destination = [command.arguments objectAtIndex:1];
    
    if(settings == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No settings specified"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    [self configurePrivate: settings :destination];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)enableLogging:(CDVInvokedUrlCommand *)command
{
    loggingEnabled = YES;
    [self putBoolInPrefs:LOGGING_ENABLED_KEY :YES];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)disableLogging:(CDVInvokedUrlCommand *)command
{
    loggingEnabled = NO;
    [self putBoolInPrefs:LOGGING_ENABLED_KEY :YES];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)enableDestination:(CDVInvokedUrlCommand *)command
{
    NSString *destination = [command.arguments objectAtIndex:0];

    if(destination == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No destination specified"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    [self enableDestinationPrivate:destination];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)disableDestination:(CDVInvokedUrlCommand *)command
{
    NSString *destination = [command.arguments objectAtIndex:0];

    if(destination == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No destination specified"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    [self disableDestinationPrivate:destination];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void)isLoggingEnabled:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:loggingEnabled];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) isDestinationEnabled:(CDVInvokedUrlCommand*)command;
{
    NSString *destination = [command.arguments objectAtIndex:0];
    
    if(destination == nil)
    {
        CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No destination specified"];
        [self.commandDelegate sendPluginResult: pluginResult callbackId:command.callbackId];
        return;
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[self isDestinationEnabledPrivate:destination]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)zipLogFiles:(CDVInvokedUrlCommand*)command
{
    NSMutableArray *filePathsToZip = [[NSMutableArray alloc] init];
    
    NSDictionary *pathInfo = [self getLogFilePathsPrivate];
    
    for (NSString *key in pathInfo)
    {
        NSString *filePath = [pathInfo objectForKey:key];
        [filePathsToZip addObject:filePath];
    }
    
    if(![[command.arguments objectAtIndex:0] isEqual:[NSNull null]] )
    {
        if([[command.arguments objectAtIndex:0] boolValue]) // includeArchivedLogs
        {
            NSDictionary *archivedPathInfo = [self getArchivedLogFilePathsPrivate];
            for (NSString *key in archivedPathInfo)
            {
                NSArray *archivedLogFilePaths = [archivedPathInfo objectForKey:key];
                if(archivedLogFilePaths.count > 0)
                    [filePathsToZip addObjectsFromArray:archivedLogFilePaths];
            }
        }
    }
    
    NSString *zipFilePath = [NSString stringWithFormat:@"%@/%@", logFileDirectoryPath, LOG_FILES_ZIP_NAME];
    
    [[NSFileManager defaultManager] removeItemAtPath:zipFilePath error:nil];
    
    if(filePathsToZip.count == 0)
    {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR messageAsString:@"No log files available to zip."];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    OZZipFile *zipFile = [[OZZipFile alloc] initWithFileName:zipFilePath mode:OZZipFileModeCreate];
    
    for(NSString *filePath in filePathsToZip)
    {
        NSString *fileNameCopy = [filePath stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        
        if(fileNameCopy != nil)
        {
            OZZipWriteStream *stream = [zipFile writeFileInZipWithName:[filePath lastPathComponent] compressionLevel:OZZipCompressionLevelBest];
            NSError* error2 = nil;
            NSData *fileData = [NSData dataWithContentsOfFile: fileNameCopy options: 0 error: &error2];
            if (fileData == nil)
            {
                NSLog(@"Failed to write file, error %@", error2);
            }
            else
            {
                [stream writeData:fileData];
            }
            [stream finishedWriting];
        }
    }
    
    [zipFile close];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsString:zipFilePath];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (bool)setRootLogLevelPrivate:(NSString*)desiredLevel : (NSString*)destination
{
    DDLogLevel *level = nil;
    if([desiredLevel caseInsensitiveCompare:LOG_LEVEL_OFF] == NSOrderedSame)
    {
        [self disableDestinationPrivate: destination];
        return YES;
    }
    else
    {
        [self enableDestinationPrivate: destination];
    }
    if([desiredLevel caseInsensitiveCompare:LOG_LEVEL_INFO] == NSOrderedSame)
    {
        level = DDLogLevelInfo;
    }
    else if([desiredLevel caseInsensitiveCompare:LOG_LEVEL_DEBUG] == NSOrderedSame)
    {
        level = DDLogLevelDebug;
    }
    else if([desiredLevel caseInsensitiveCompare:LOG_LEVEL_WARNING] == NSOrderedSame)
    {
        level = DDLogLevelWarning;
    }
    else if([desiredLevel caseInsensitiveCompare:LOG_LEVEL_ERROR] == NSOrderedSame)
    {
        level = DDLogLevelError;
    }
    if(level != nil)
    {
        NSArray *loggerArray = [self createLoggerArrayFromArgument: destination];
        
        if(loggers != nil)
        {
            for(NSString *destination in loggerArray)
            {
                DDFileLogger *fileLogger = [loggers objectForKey:destination];
                
                if(fileLogger == nil)
                    continue;
                
                if([destination caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
                {
                    [(AppFormatter*)fileLogger.logFormatter setRootLogLevel:level];
                    [self putObjectInPrefs:APP_ROOT_LOG_LEVEL_KEY :desiredLevel];
                }
                else if([destination caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
                {
                    [(ClientFormatter*)fileLogger.logFormatter setRootLogLevel:level];
                    [self putObjectInPrefs:CLIENT_ROOT_LOG_LEVEL_KEY :desiredLevel];
                }
                else if([destination caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
                {
                    [(NativeFormatter*)fileLogger.logFormatter setRootLogLevel:level];
                    [self putObjectInPrefs:NATIVE_ROOT_LOG_LEVEL_KEY :desiredLevel];
                }
            }
        }
        
        return YES;
    }
    else
    {
        return NO;
    }
}

- (NSString*)getRootLogLevelPrivate:(NSString*)destination
{
    DDFileLogger *fileLogger = [loggers objectForKey:destination];
    if([destination caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
    {
        return [[(AppFormatter*)fileLogger.logFormatter getRootLogLevel] lowercaseString];
    }
    else if([destination caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
    {
        return [[(ClientFormatter*)fileLogger.logFormatter getRootLogLevel] lowercaseString];
    }
    else if([destination caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
    {
        return [[(NativeFormatter*)fileLogger.logFormatter getRootLogLevel] lowercaseString];
    }
    return nil;
}

- (void)enableDestinationPrivate:(NSString*)destination
{
    if([destination caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
    {
        appLoggingEnabled = YES;
        [self putBoolInPrefs:APP_LOGGING_ENABLED_KEY :YES];
    }
    else if([destination caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
    {
        clientLoggingEnabled = YES;
        [self putBoolInPrefs:CLIENT_LOGGING_ENABLED_KEY :YES];
    }
    else if([destination caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
    {
        nativeLoggingEnabled = YES;
        [self putBoolInPrefs:NATIVE_LOGGING_ENABLED_KEY :YES];
    }
}

- (void)disableDestinationPrivate:(NSString*)destination
{
    if([destination caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
    {
        appLoggingEnabled = NO;
        [self putBoolInPrefs:APP_LOGGING_ENABLED_KEY :NO];
    }
    else if([destination caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
    {
        clientLoggingEnabled = NO;
        [self putBoolInPrefs:CLIENT_LOGGING_ENABLED_KEY :NO];
    }
    else if([destination caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
    {
        nativeLoggingEnabled = NO;
        [self putBoolInPrefs:NATIVE_LOGGING_ENABLED_KEY :NO];
    }
}
                                     
- (BOOL)isDestinationEnabledPrivate:(NSString*)destination
{
    if([destination caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
    {
        return appLoggingEnabled;
    }
    else if([destination caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
    {
        return clientLoggingEnabled;
    }
    else if([destination caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
    {
        return nativeLoggingEnabled;
    }
    return NO;
}

- (bool)configurePrivate:(NSDictionary*)settings : (NSObject*)destination
{
    NSArray *loggerArray = nil;
    
    if(![destination isEqual:[NSNull null]])
    {
        loggerArray = [self createLoggerArrayFromArgument: destination];
    }
    else
    {
        loggerArray = [[NSArray alloc] initWithObjects:CLIENT_DESTINATION, APP_DESTINATION, NATIVE_DESTINATION, nil];
    }
    
    long maxFileSize = [settings[@"maxFileSize"] longValue];
    int maxNumberOfFiles = [settings[@"maxNumberOfFiles"] intValue];
    
    for(NSString *destination in loggerArray)
    {
        DDFileLogger *fileLogger = [loggers objectForKey:destination];
        
        if(fileLogger == nil)
            continue;
        
        if(maxNumberOfFiles > 0)
        {
            if(maxNumberOfFiles < [fileLogger.logFileManager maximumNumberOfLogFiles])
            {
                NSError *error;
                NSFileManager *fm = [NSFileManager defaultManager];
                NSMutableArray *files = [fm contentsOfDirectoryAtPath:[fileLogger.logFileManager logsDirectory] error:&error];
                if(!error)
                {
                    if(files.count > maxNumberOfFiles)
                    {
                        for(int index = maxNumberOfFiles ; index < files.count ; index++)
                        {
                            if([destination isEqualToString:CLIENT_DESTINATION])
                            {
                                [fm removeItemAtPath:[[fileLogger.logFileManager logsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"client %d.log", index]] error:nil];
                            }
                            else if([destination isEqualToString:APP_DESTINATION])
                            {
                                [fm removeItemAtPath:[[fileLogger.logFileManager logsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"app %d.log", index]] error:nil];
                            }
                            else if([destination isEqualToString:NATIVE_DESTINATION])
                            {
                                [fm removeItemAtPath:[[fileLogger.logFileManager logsDirectory] stringByAppendingPathComponent:[NSString stringWithFormat:@"native %d.log", index]] error:nil];
                            }
                        }
                    }
                }
            }
            [fileLogger.logFileManager setMaximumNumberOfLogFiles:maxNumberOfFiles];
            if([destination isEqualToString:CLIENT_DESTINATION])
            {
                [self putIntInPrefs:CLIENT_MAX_NUMBER_OF_LOG_FILES_KEY: maxNumberOfFiles];
            }
            else if([destination isEqualToString:APP_DESTINATION])
            {
                [self putIntInPrefs:APP_MAX_NUMBER_OF_LOG_FILES_KEY: maxNumberOfFiles];
            }
            else if([destination isEqualToString:NATIVE_DESTINATION])
            {
                [self putIntInPrefs:NATIVE_MAX_NUMBER_OF_LOG_FILES_KEY: maxNumberOfFiles];
            }
        }
        
        if(maxFileSize > 0)
        {
            [fileLogger setMaximumFileSize:maxFileSize];
            if([destination isEqualToString:CLIENT_DESTINATION])
            {
                [self putLongInPrefs:CLIENT_MAX_FILE_SIZE_KEY: maxFileSize];
            }
            else if([destination isEqualToString:APP_DESTINATION])
            {
                [self putLongInPrefs:APP_MAX_FILE_SIZE_KEY: maxFileSize];
            }
            else if([destination isEqualToString:NATIVE_DESTINATION])
            {
                [self putLongInPrefs:NATIVE_MAX_FILE_SIZE_KEY: maxFileSize];
            }
        }
    }
}

- (void) logNativeInfo:(NSString*)msg
{
    NSArray *loggerArray = [[NSArray alloc] initWithObjects: NATIVE_DESTINATION, nil];
    [self logInfoPrivate:msg :loggerArray];
}

- (void) logNativeDebug:(NSString*)msg;
{
    NSArray *loggerArray = [[NSArray alloc] initWithObjects: NATIVE_DESTINATION, nil];
    [self logDebugPrivate:msg :loggerArray];
}

- (void) logNativeWarn:(NSString*)msg;
{
    NSArray *loggerArray = [[NSArray alloc] initWithObjects: NATIVE_DESTINATION, nil];
    [self logWarnPrivate:msg :loggerArray];
}

- (void) logNativeError:(NSString*)msg;
{
    NSArray *loggerArray = [[NSArray alloc] initWithObjects: NATIVE_DESTINATION, nil];
    [self logErrorPrivate:msg :loggerArray];
}

- (void) logInfoPrivate:(NSString*)msg:(NSArray*)loggerArray
{
    if(!loggingEnabled)
        return;
    
    if(loggers != nil)
    {
        for(NSString *logger in loggerArray)
        {
            if([logger caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
            {
                if(clientLoggingEnabled)
                {
                    ClientLogInfo(msg);
                }
            }
            else if([logger caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
            {
                if(appLoggingEnabled)
                {
                    AppLogInfo(msg);
                }
            }
            else if([logger caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
            {
                if(nativeLoggingEnabled)
                {
                    NativeLogInfo(msg);
                }
            }
        }
    }
}

- (void) logDebugPrivate:(NSString*)msg:(NSArray*)loggerArray
{
    if(!loggingEnabled)
        return;
    
    if(loggers != nil)
    {
        for(NSString *logger in loggerArray)
        {
            if([logger caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
            {
                if(clientLoggingEnabled)
                {
                    ClientLogDebug(msg);
                }
            }
            else if([logger caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
            {
                if(appLoggingEnabled)
                {
                    AppLogDebug(msg);
                }
            }
            else if([logger caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
            {
                if(nativeLoggingEnabled)
                {
                    NativeLogDebug(msg);
                }
            }
        }
    }
}

- (void) logWarnPrivate:(NSString*)msg:(NSArray*)loggerArray
{
    if(!loggingEnabled)
        return;
    
    if(loggers != nil)
    {
        for(NSString *logger in loggerArray)
        {
            if([logger caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
            {
                if(clientLoggingEnabled)
                {
                    ClientLogWarn(msg);
                }
            }
            else if([logger caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
            {
                if(appLoggingEnabled)
                {
                    AppLogWarn(msg);
                }
            }
            else if([logger caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
            {
                if(nativeLoggingEnabled)
                {
                    NativeLogWarn(msg);
                }
            }
        }
    }
}

- (void) logErrorPrivate:(NSString*)msg:(NSArray*)loggerArray
{
    if(!loggingEnabled)
        return;
    
    if(loggers != nil)
    {
        for(NSString *logger in loggerArray)
        {
            if([logger caseInsensitiveCompare:CLIENT_DESTINATION] == NSOrderedSame)
            {
                if(clientLoggingEnabled)
                {
                    ClientLogError(msg);
                }
            }
            else if([logger caseInsensitiveCompare:APP_DESTINATION] == NSOrderedSame)
            {
                if(appLoggingEnabled)
                {
                    AppLogError(msg);
                }
            }
            else if([logger caseInsensitiveCompare:NATIVE_DESTINATION] == NSOrderedSame)
            {
                if(nativeLoggingEnabled)
                {
                    NativeLogError(msg);
                }
            }
        }
    }
}

- (NSArray *)createLoggerArrayFromArgument:(NSObject*)argument
{
    NSArray *loggerArray = nil;
    
    if([argument isKindOfClass:[NSArray class]])
    {
        loggerArray = (NSArray*) argument;
    }
    else if([argument isKindOfClass:[NSString class]])
    {
        loggerArray = [[NSArray alloc] initWithObjects:argument, nil];
    }
    
    return loggerArray;
}

- (void) setupLoggers
{
    if(loggers != nil)
        return;
    
    loggers = [[NSMutableDictionary alloc] init];
    
    DDFileLogger *appFileLogger = [[DDFileLogger alloc] initWithLogFileManager:[[AppLogFileManager alloc] initWithLogsDirectory:[logFileDirectoryPath stringByAppendingPathComponent:APP_DESTINATION]]];
    [appFileLogger setMaximumFileSize:(1000000)];
    [appFileLogger setRollingFrequency:(0)];
    [appFileLogger.logFileManager setMaximumNumberOfLogFiles:5];
    AppFormatter *appFormatter = [[AppFormatter alloc] init];
    [appFormatter setRootLogLevel:DDLogLevelError];
    [appFileLogger setLogFormatter:appFormatter];
    [loggers setObject:appFileLogger forKey:APP_DESTINATION];
    [DDLog addLogger:appFileLogger];
    
    DDFileLogger *clientFileLogger = [[DDFileLogger alloc] initWithLogFileManager:[[ClientLogFileManager alloc] initWithLogsDirectory:[logFileDirectoryPath stringByAppendingPathComponent:CLIENT_DESTINATION]]];
    [clientFileLogger setMaximumFileSize:(1000000)];
    [clientFileLogger setRollingFrequency:(0)];
    [clientFileLogger.logFileManager setMaximumNumberOfLogFiles:5];
    ClientFormatter *clientFormatter = [[ClientFormatter alloc] init];
    [clientFormatter setRootLogLevel:DDLogLevelError];
    [clientFileLogger setLogFormatter:clientFormatter];
    [loggers setObject:clientFileLogger forKey:CLIENT_DESTINATION];
    [DDLog addLogger:clientFileLogger];
    
    DDFileLogger *nativeFileLogger = [[DDFileLogger alloc] initWithLogFileManager:[[NativeLogFileManager alloc] initWithLogsDirectory:[logFileDirectoryPath stringByAppendingPathComponent:NATIVE_DESTINATION]]];
    [nativeFileLogger setMaximumFileSize:(1000000)];
    [nativeFileLogger setRollingFrequency:(0)];
    [nativeFileLogger.logFileManager setMaximumNumberOfLogFiles:5];
    NativeFormatter *nativeFormatter = [[NativeFormatter alloc] init];
    [nativeFormatter setRootLogLevel:DDLogLevelError];
    [nativeFileLogger setLogFormatter:nativeFormatter];
    [loggers setObject:nativeFileLogger forKey:NATIVE_DESTINATION];
    [DDLog addLogger:nativeFileLogger];
}

- (BOOL) isNilOrEmpty:(NSString*)aString
{
    return !(aString && aString.length);
}

- (BOOL) isFirstRun
{
    NSString *prefsKey = @"hasRun";
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    if ([preferences objectForKey:prefsKey] == nil)
    {
        [preferences setBool:YES forKey:prefsKey];
        [preferences synchronize];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void) putObjectInPrefs: (NSString*)key : (NSObject*)value
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setObject:value forKey:key];
    [preferences synchronize];
}

- (void) putBoolInPrefs: (NSString*)key : (BOOL)value
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setBool:value forKey:key];
    [preferences synchronize];
}

- (void) putIntInPrefs: (NSString*)key : (int)value
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setObject:[NSNumber numberWithInt:value] forKey:key];
    [preferences synchronize];
}

- (void) putLongInPrefs: (NSString*)key : (long)value
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setObject:[NSNumber numberWithLong:value] forKey:key];
    [preferences synchronize];
}

- (NSString*) getStringFromPrefs: (NSString*)key
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    return [preferences stringForKey:key];
}

- (BOOL) getBoolFromPrefs: (NSString*)key
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    return [preferences boolForKey:key];
}

- (int) getIntFromPrefs: (NSString*)key
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    return [[preferences objectForKey:key] intValue];
}

- (long) getLongFromPrefs: (NSString*)key
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    return [[preferences objectForKey:key] longValue];
}

@end