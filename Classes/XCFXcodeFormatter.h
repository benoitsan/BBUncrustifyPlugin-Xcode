//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XCFConstants.h"

@class IDESourceCodeDocument;

@interface XCFXcodeFormatter : NSObject

+ (BOOL)canFormatSelectedFiles;
+ (void)formatSelectedFilesWithError:(NSError **)outError;
+ (void)formatSelectedFilesWithEnumerationBlock:(void(^)(NSURL *url, NSError *error, BOOL *stop))enumerationBlock;

+ (BOOL)canFormatActiveFile;
+ (void)formatActiveFileWithError:(NSError **)outError;

+ (BOOL)canFormatSelectedLines;
+ (void)formatSelectedLinesWithError:(NSError **)outError;

+ (BOOL)canLaunchConfigurationEditor;
+ (void)launchConfigurationEditorWithError:(NSError **)outError;

+ (void)formatDocument:(IDESourceCodeDocument *)document withError:(NSError **)outError;

@end
