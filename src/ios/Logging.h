#import <Cordova/CDV.h>

#import "CocoaLumberjack.h"
#import "ClientFormatter.h"
#import "NativeFormatter.h"
#import "DeveloperFormatter.h"
#import "ClientLogFileManager.h"
#import "NativeLogFileManager.h"
#import "DeveloperLogFileManager.h"

@interface Logging : CDVPlugin

- (void) pluginInitialize;
- (void) logInfo:(CDVInvokedUrlCommand*)command;
- (void) logDebug:(CDVInvokedUrlCommand*)command;
- (void) logWarn:(CDVInvokedUrlCommand*)command;
- (void) logError:(CDVInvokedUrlCommand*)command;
- (void) logMessages:(CDVInvokedUrlCommand *)command;
- (void) setRootLogLevel:(CDVInvokedUrlCommand*)command;
- (void) getRootLogLevel:(CDVInvokedUrlCommand*)command;
- (void) getLogFilePaths:(CDVInvokedUrlCommand*)command;
- (void) makeFilesPublic:(CDVInvokedUrlCommand*)command;
- (void) removePublicFiles:(CDVInvokedUrlCommand*)command;
- (void) getArchivedLogFilePaths:(CDVInvokedUrlCommand*)command;
- (void) configure:(CDVInvokedUrlCommand*)command;
- (void) enableLogging:(CDVInvokedUrlCommand*)command;
- (void) disableLogging:(CDVInvokedUrlCommand*)command;
- (void) enableDestination:(CDVInvokedUrlCommand*)command;
- (void) disableDestination:(CDVInvokedUrlCommand*)command;
- (void) isLoggingEnabled:(CDVInvokedUrlCommand*)command;
- (void) zipLogFiles:(CDVInvokedUrlCommand*)command;
- (void) logNativeInfo:(NSString*)msg;
- (void) logNativeDebug:(NSString*)msg;
- (void) logNativeWarn:(NSString*)msg;
- (void) logNativeError:(NSString*)msg;

@end