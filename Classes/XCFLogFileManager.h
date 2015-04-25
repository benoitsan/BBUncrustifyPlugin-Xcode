//
// XCFLogFileManager.h
// BBUncrustifyPlugin
//
// Created by Benoît Bourdon on 15/04/15.
//
//

#import "DDFileLogger.h"

// Subclass of DDLogFileManagerDefault is needed for customizing the log filename

extern NSString *const XCFLoggingFileApplicationName;

@interface XCFLogFileManager : DDLogFileManagerDefault

@end
