//
// Created by Benoît on 11/01/14.
// Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

@import Foundation;

@interface XCFFormatterUtilities : NSObject

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL lookupFilenames:(NSArray *)lookupFilenames alternateURLs:(NSArray *)alternateURLs;

@end
