//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFUncrustifyFormatter.h"

@implementation XCFUncrustifyFormatter

+ (NSArray *)searchedURLsForExecutable {
    static NSArray *array = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSURL *url = [bundle URLForResource:@"uncrustify" withExtension:@""];
        
        array = [[super searchedURLsForExecutable] arrayByAddingObject:url];
        
    });
    
    return array;
}

@end
