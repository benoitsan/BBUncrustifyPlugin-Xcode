//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const CFOErrorDomain;

enum {
    CFOFileReadError,
    CFOFormatterFailureError,
    CFOFormatterTimeOutError
};


@interface CFOFragment : NSObject

@property (nonatomic, readonly) NSRange inputRange;
@property (nonatomic, readonly) NSString *string;

+ (instancetype)fragmentWithInputRange:(NSRange)inputRange string:(NSString *)string;

@end


@protocol CFOFormatterProtocol <NSObject>

+ (NSArray *)searchedURLsForExecutable;
- (NSArray *)fragmentsByFormattingInputAtRanges:(NSArray *)ranges error:(NSError **)error;

@end


// CFOFormatter: An abstract "code formatter". Should not be used directly.

@interface CFOFormatter : NSObject <CFOFormatterProtocol>

@property (nonatomic, readonly) NSString *inputString;
@property (nonatomic, readonly) NSURL *presentedURL;

+ (NSArray *)searchedURLsForExecutable;
+ (NSURL *)resolvedExecutableURLWithError:(NSError **)outError;

- (id)initWithInputAtURL:(NSURL *)url error:(NSError **)error;
- (id)initWithInputString:(NSString *)string presentedURL:(NSURL *)presentedURL;

- (NSArray *)fragmentsByFormattingInputAtRanges:(NSArray *)ranges error:(NSError **)error;
- (NSString *)stringByFormattingInputAtRanges:(NSArray *)ranges error:(NSError **)error;
- (NSString *)stringByFormattingInputWithError:(NSError **)error;

- (NSArray *)normalizedRangesForInputRanges:(NSArray *)inputRanges;

@end


