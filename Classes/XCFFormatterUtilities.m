//
// Created by Benoît on 11/01/14.
// Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFFormatterUtilities.h"

@implementation XCFFormatterUtilities

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL lookupFilenames:(NSArray *)lookupFilenames alternateURLs:(NSArray *)alternateURLs
{
	NSParameterAssert(presentedURL);
	
	NSURL *directoryURL = [presentedURL URLByDeletingLastPathComponent];
	
	while (directoryURL != nil) {
		for (NSString *lookupFilename in lookupFilenames) {
			NSURL *url = [directoryURL URLByAppendingPathComponent:lookupFilename isDirectory:NO];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
				return url;
			}
		}
		
		NSURL *parentURL = nil;
		
		if (![directoryURL getResourceValue:&parentURL forKey:NSURLParentDirectoryURLKey error:nil]) {
			break;
		}
		
		directoryURL = parentURL;
	}
	
	for (NSURL *alternateURL in alternateURLs) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:alternateURL.path]) {
			return alternateURL;
		}
	}
	
	return nil;
}

@end
