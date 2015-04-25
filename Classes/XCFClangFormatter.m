//
// Created by Benoît on 11/01/14.
// Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFClangFormatter.h"
#import "XCFFormatterUtilities.h"

@implementation XCFClangFormatter

#pragma mark - Overrided

+ (NSArray *)searchedURLsForExecutable
{
	static NSArray *array = nil;
	
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSURL *url = [bundle URLForResource:@"clang-format" withExtension:@""];
		
		array = [[super searchedURLsForExecutable] arrayByAddingObject:url];
	});
	
	return array;
}

#pragma mark -

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL
{
	NSArray *lookupFilenames = @[@"_clang-format", @".clang-format"];
	
	return [XCFFormatterUtilities configurationFileURLForPresentedURL:presentedURL lookupFilenames:lookupFilenames alternateURLs:nil];
}

@end
