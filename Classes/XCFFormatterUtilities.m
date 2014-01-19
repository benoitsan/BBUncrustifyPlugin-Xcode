//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFFormatterUtilities.h"

@interface XCFFormatterUtilities : NSObject

@end

@implementation XCFFormatterUtilities

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL lookupFilenames:(NSArray *)lookupFilenames alternateURLs:(NSArray *)alternateURLs {
    NSParameterAssert(presentedURL);
    
    NSURL *directoryURL = [presentedURL URLByDeletingLastPathComponent];
    
    while(directoryURL != nil){
        
        for (NSString *lookupFilename in lookupFilenames) {
            NSURL *url = [directoryURL URLByAppendingPathComponent:lookupFilename isDirectory:NO];
            if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
                return url;
            }
        }
        
        NSURL *parentURL = nil;
        if(![directoryURL getResourceValue:&parentURL forKey:NSURLParentDirectoryURLKey error:nil]){
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

@implementation CFOClangFormatter(XCFAdditions)

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL {
    NSArray *lookupFilenames = @[@"_clang-format", @".clang-format"];
    
    return [XCFFormatterUtilities configurationFileURLForPresentedURL:presentedURL lookupFilenames:lookupFilenames alternateURLs:nil];
}

@end

@implementation CFOUncrustifyFormatter(XCFAdditions)

+ (NSURL *)builtinConfigurationFileURL {
    static NSURL *builtInConfigurationFileURL = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        builtInConfigurationFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"uncrustify" withExtension:@"cfg"];
    });
    return builtInConfigurationFileURL;
}

+ (NSURL *)configurationFileURLForPresentedURL:(NSURL *)presentedURL {
    
    NSArray *lookupFilenames = @[@"uncrustify.cfg", @".uncrustifyconfig"];

    static NSArray *alternateURLs = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *array = [NSMutableArray array];
        
        NSURL *homeDirectoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
        for (NSString *lookupFilename in lookupFilenames) {
            [array addObject:[homeDirectoryURL URLByAppendingPathComponent:lookupFilename isDirectory:NO]];
        }
        
        [array addObject:[[homeDirectoryURL URLByAppendingPathComponent:@".uncrustify" isDirectory:YES] URLByAppendingPathComponent:@"uncrustify.cfg" isDirectory:NO]];
        
        NSURL *builtInConfigurationFileURL = [[self class] builtinConfigurationFileURL];
        if (builtInConfigurationFileURL) {
            [array addObject:builtInConfigurationFileURL];
        }
        
        alternateURLs = [array copy];
        
    });
    
    return [XCFFormatterUtilities configurationFileURLForPresentedURL:presentedURL lookupFilenames:lookupFilenames alternateURLs:alternateURLs];
}

@end
