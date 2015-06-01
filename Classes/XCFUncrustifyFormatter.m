//
// Created by Benoît on 11/01/14.
// Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFUncrustifyFormatter.h"
#import "XCFFormatterUtilities.h"

@implementation XCFUncrustifyFormatter

#pragma mark - Overrided

+ (NSArray *)searchedURLsForExecutable
{
	static NSArray *array = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSURL *url = [bundle URLForResource:@"uncrustify" withExtension:@""];
		
		array = [[super searchedURLsForExecutable] arrayByAddingObject:url];
	});
	
	return array;
}

#pragma mark -

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL
{
	NSArray *lookupFilenames = @[@"uncrustify.cfg", @"_uncrustify.cfg", @".uncrustify.cfg", @".uncrustifyconfig"];
	
	static NSArray *alternateURLs = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		NSMutableArray *array = [NSMutableArray array];
		
		NSURL *homeDirectoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
		
		for (NSString *lookupFilename in lookupFilenames) {
			[array addObject:[homeDirectoryURL URLByAppendingPathComponent:lookupFilename isDirectory:NO]];
		}
		
		[array addObject:[[homeDirectoryURL URLByAppendingPathComponent:@".uncrustify" isDirectory:YES] URLByAppendingPathComponent:@"uncrustify.cfg" isDirectory:NO]];

		alternateURLs = [array copy];
	});
	
	return [XCFFormatterUtilities configurationFileURLForPresentedURL:presentedURL lookupFilenames:lookupFilenames alternateURLs:alternateURLs];
}

@end
