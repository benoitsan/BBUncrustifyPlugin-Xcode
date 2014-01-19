//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "CFOFormatter.h"

NSString * const CFOErrorDomain = @"com.pragmaticcode.codeformatter";

NSArray * CFOSortAndMergeContinuousRanges(NSArray *ranges) {
    
    // this method merges the continuous ranges and sort them from the lowest to the highest
    
    if (ranges.count == 0) return nil;
    
    NSMutableIndexSet *mIndexes = [NSMutableIndexSet indexSet];
    for (NSValue *rangeValue in ranges) {
        NSRange range = [rangeValue rangeValue];
        [mIndexes addIndexesInRange:range];
    }
    
    NSMutableArray *mergedRanges = [NSMutableArray array];
    [mIndexes enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        [mergedRanges addObject:[NSValue valueWithRange:range]];
    }];
    return [NSArray arrayWithArray:mergedRanges];
}

#pragma mark -

@implementation CFOFragment

+ (instancetype)fragmentWithInputRange:(NSRange)inputRange string:(NSString *)string {
    return [[self alloc] initWithInputRange:inputRange string:string];
}

- (id)initWithInputRange:(NSRange)inputRange string:(NSString *)string {
    self = [super init];
    if (self) {
        _inputRange = inputRange;
        _string = string;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> - input range:%@, string:%@", NSStringFromClass([self class]), self, NSStringFromRange(_inputRange), _string];
}

@end


#pragma mark -

@implementation CFOFormatter

#pragma mark Setup and Teardown

- (id)initWithInputAtURL:(NSURL *)url error:(NSError **)outError {
    NSParameterAssert(url);
    
    NSError *error = nil;
    NSString *inputString = [NSString stringWithContentsOfURL:url usedEncoding:nil error:&error];
    if (error){
        if (outError) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Unable to read the file `%@`.", nil), url.path]};
            *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFileReadError userInfo:userInfo];
        }
        return nil;
    }
    return [self initWithInputString:inputString presentedURL:url];
}

- (id)initWithInputString:(NSString *)string presentedURL:(NSURL *)presentedURL {
    NSParameterAssert(string);
    NSParameterAssert(presentedURL);
    
    self = [super init];
    if (self) {
        _inputString = string;
        _presentedURL = presentedURL;
    }
    return self;
}

#pragma mark - Input Formatting Methods

- (NSArray *)fragmentsByFormattingInputAtRanges:(NSArray *)ranges error:(NSError **)error {
    return nil; // implemented by subclass
}

- (NSString *)stringByFormattingInputAtRanges:(NSArray *)ranges error:(NSError **)outError {
    NSError *error = nil;
    NSArray *fragments = [self fragmentsByFormattingInputAtRanges:ranges error:&error];
    if (!error) {
        NSMutableString *mString = [NSMutableString stringWithString:self.inputString];
        [fragments enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(CFOFragment *fragment, NSUInteger idx, BOOL *stop) {
            [mString replaceCharactersInRange:fragment.inputRange withString:fragment.string];
        }];
        return [mString copy];
    }
    else if (outError) {
        *outError = error;
    }
    return nil;
}

- (NSString *)stringByFormattingInputWithError:(NSError **)error {
    return [self stringByFormattingInputAtRanges:@[[NSValue valueWithRange:NSMakeRange(0, self.inputString.length)]] error:error];
}


#pragma mark - Executable

+ (NSArray *)searchedURLsForExecutable {
    return nil; // implemented by subclass
}

+ (NSURL *)resolvedExecutableURLWithError:(NSError **)outError {
    
    NSArray *searchedURLs = [[self class] searchedURLsForExecutable];
    for (NSURL *url in searchedURLs) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            return url;
        }
    }
    
    if (outError) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"The Formatter binary was not found at any of these paths:\n- %@", nil), [[searchedURLs valueForKey:@"path"] componentsJoinedByString:@"\n- "]]};
        *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
    }
    
    return nil;
}

#pragma mark - Helpers for subclasses

- (NSArray *)normalizedRangesForInputRanges:(NSArray *)inputRanges {
    
    NSMutableArray *lineInputRanges = [NSMutableArray array];
    
    for (NSValue *inputRangeValue in inputRanges) {
        NSRange range = [inputRangeValue rangeValue];
        
        if (NSMaxRange(range) > self.inputString.length) {
            @throw [NSException exceptionWithName:NSRangeException
                                           reason:[NSString stringWithFormat:@"Range %@ out of bounds; string length %lu", NSStringFromRange(range), (unsigned long)self.inputString.length]
                                         userInfo:nil];
        }
        
        NSRange lineRange = [self.inputString lineRangeForRange:range];
        [lineInputRanges addObject:[NSValue valueWithRange:lineRange]];
    }
    
    NSArray *normalizedLineRanges = CFOSortAndMergeContinuousRanges(lineInputRanges);

    if (normalizedLineRanges.count > 0) {
        return [normalizedLineRanges copy];
    }
    return nil;
}

@end












































