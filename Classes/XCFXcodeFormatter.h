//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSDocument.h>
#import "XCFConstants.h"

@interface XCFXcodeFormatter : NSObject

+ (BOOL)canFormatSelectedFiles;
+ (void)formatSelectedFilesWithError:(NSError **)outError;

+ (BOOL)canFormatActiveFile;
+ (void)formatActiveFileWithError:(NSError **)outError;

+ (BOOL)canFormatSelectedLines;
+ (void)formatSelectedLinesWithError:(NSError **)outError;

+ (BOOL)canLaunchConfigurationEditor;
+ (void)launchConfigurationEditorWithError:(NSError **)outError;

+ (BOOL)canFormatDocument:(NSDocument *)document;
+ (void)formatDocument:(NSDocument *)document withError:(NSError **)outError;

@end
