//
// XCFLoggingUtilities.m
// BBUncrustifyPlugin
//
// Created by Benoît Bourdon on 15/04/15.
//
//

#import "XCFLoggingUtilities.h"
#import "XCFLogFileManager.h"

DDLogLevel ddLogLevel;

@implementation XCFLoggingUtilities

+ (void)setUpLogger
{
	ddLogLevel = DDLogLevelDebug;
	
	XCFLogFileManager *fileManager = [[XCFLogFileManager alloc] initWithLogsDirectory:self.fileLoggerDirectoryURL.path];
	
	DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:fileManager];
	fileLogger.maximumFileSize = 1 * 1024 * 1024;   // 1 MB
	fileLogger.rollingFrequency = 4 * 60 * 60 * 24; // 4 days
	fileLogger.logFileManager.maximumNumberOfLogFiles = 2;
	
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:fileLogger];
}

+ (NSURL *)fileLoggerDirectoryURL
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *basePath = ([paths count] > 0) ? paths[0] : NSTemporaryDirectory();
	NSURL *logsDirectoryURL = [[[NSURL fileURLWithPath:basePath isDirectory:YES] URLByAppendingPathComponent:@"Logs" isDirectory:YES] URLByAppendingPathComponent:XCFLoggingFileApplicationName isDirectory:YES];
	
	return logsDirectoryURL;
}

+ (NSURL *)mostRecentLogFileURL
{
	NSArray *urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:self.fileLoggerDirectoryURL includingPropertiesForKeys:@[NSURLIsRegularFileKey, NSURLTypeIdentifierKey, NSURLContentModificationDateKey] options:0 error:nil];
	
	NSURL *foundURL = nil;
	NSDate *foundURLModificationDate = nil;
	
	for (NSURL *url in urls) {
		NSNumber *isRegularFileValue = nil;
		[url getResourceValue:&isRegularFileValue forKey:NSURLIsRegularFileKey error:nil];
		
		if (isRegularFileValue.boolValue) {
			NSDate *date = nil;
			NSString *uti = nil;
			[url getResourceValue:&date forKey:NSURLContentModificationDateKey error:nil];
			[url getResourceValue:&uti forKey:NSURLTypeIdentifierKey error:nil];
			
			if (uti && [[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeLog]) {
				if (date && [date isGreaterThanOrEqualTo:foundURLModificationDate]) {
					foundURL = url;
					foundURLModificationDate = date;
				}
			}
		}
	}
	
	return foundURL;
}

@end
