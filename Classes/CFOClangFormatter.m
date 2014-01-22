//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "CFOClangFormatter.h"
#import "DiffMatchPatch.h"
#import "BBMacros.h"

NSString * const CFOClangStyleFile = @"file";
NSString * const CFOClangStylePredefinedLLVM = @"LLVM";
NSString * const CFOClangStylePredefinedGoogle = @"Google";
NSString * const CFOClangStylePredefinedChromium = @"Chromium";
NSString * const CFOClangStylePredefinedMozilla = @"Mozilla";
NSString * const CFOClangStylePredefinedWebKit = @"WebKit";

NSString * const CFOClangDumpConfigurationOptionsStyle = @"style";

@implementation CFOClangFormatter

#pragma mark - Setup and Teardown

- (id)initWithInputString:(NSString *)string presentedURL:(NSURL *)presentedURL {
    self = [super initWithInputString:string presentedURL:presentedURL];
    if (self) {
        _style = CFOClangStylePredefinedLLVM;
    }
    return self;
}

#pragma mark - CFOFormatterProtocol

+ (NSArray *)searchedURLsForExecutable {
    return @[
             [NSURL fileURLWithPath:@"/usr/local/bin/clang-format"],
             [NSURL fileURLWithPath:@"/usr/bin/clang-format"],
             ];
}

- (NSArray *)fragmentsByFormattingInputAtRanges:(NSArray *)ranges error:(NSError **)outError {
    
    NSError *error = nil;
    
    NSURL *executableURL = [[self class] resolvedExecutableURLWithError:&error];
    if (outError) *outError = error;
    
    if (!executableURL) {
        return nil;
    }
    
    NSArray *normalizedRanges = [self normalizedRangesForInputRanges:ranges];
    
    NSMutableArray *fragments = [NSMutableArray array];
    
    NSMutableArray *args = [NSMutableArray array];
    
    [args addObject:[NSString stringWithFormat:@"-assume-filename=%@",self.presentedURL.path]];
    [args addObject:[NSString stringWithFormat:@"-style=%@",self.style]];
    
    for (NSValue *rangeValue in normalizedRanges) {
        NSRange range = [rangeValue rangeValue];
        [args addObject:[NSString stringWithFormat:@"-offset=%lu",(unsigned long)range.location]];
        [args addObject:[NSString stringWithFormat:@"-length=%lu",(unsigned long)range.length]];
    }
    
    NSPipe *inputPipe = NSPipe.pipe;
    NSPipe *outputPipe = NSPipe.pipe;
    NSPipe *errorPipe = NSPipe.pipe;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = executableURL.path;
    task.arguments = args;
    
    task.standardInput = inputPipe;
    task.standardOutput = outputPipe;
    task.standardError = errorPipe;
    
    [task launch];
    
    [[inputPipe fileHandleForWriting] writeData:[self.inputString dataUsingEncoding:NSUTF8StringEncoding]];
    [[inputPipe fileHandleForWriting] closeFile];

    // Seems like there is a bug in clang-format. I found a source file where the process never completes.
    // (It's not a Cocoa issue since executing the formatting in command line has the same result).
    BOOL taskTimeOutReached = NO;
    NSDate *terminateDate = [[NSDate date] dateByAddingTimeInterval:2.0];
    while ([task isRunning])   {
        if ([[NSDate date] compare:terminateDate] == NSOrderedDescending)   {
            BBLogRelease(@"Error: terminating task with timeout.");
            [task terminate];
            taskTimeOutReached = YES;
        }
        [NSThread sleepForTimeInterval:.01];
    }
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
    
    int status = [task terminationStatus];
    
    if (status == 0) {
        
        if (errorData.length > 0) {
            NSString *warning = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            BBLogRelease(@"Parser Warning: %@", warning);
        }
        
        
        NSString *formattedString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        
        DiffMatchPatch *dmp = [[DiffMatchPatch alloc] init];
        
        
        NSMutableArray *diffs = [dmp diff_mainOfOldString:self.inputString andNewString:formattedString];
        
        NSUInteger j = 0;
        
        NSMutableArray *replacementFragments = [NSMutableArray array];
        
        for (Diff *diff in diffs) {
            if (diff.operation == DIFF_INSERT) {
                CFOFragment *fragment = [CFOFragment fragmentWithInputRange:NSMakeRange(j, 0) string:diff.text];
                [replacementFragments addObject:fragment];
            }
            else if (diff.operation == DIFF_DELETE) {
                CFOFragment *fragment = [CFOFragment fragmentWithInputRange:NSMakeRange(j, diff.text.length) string:@""];
                [replacementFragments addObject:fragment];
                j += diff.text.length;
            }
            else if (diff.operation == DIFF_EQUAL) {
                j += diff.text.length;
            }
        }
        
        if (replacementFragments.count > 0) {
            NSRange modifiedRange = [replacementFragments.firstObject inputRange];
            if (replacementFragments.count > 1) {
                modifiedRange.length = NSMaxRange([replacementFragments.lastObject inputRange]) - modifiedRange.location;
            }
            
            NSRange destinationRange = modifiedRange;//NSMakeRange([replacementFragments.firstObject inputRange].location, 0);
            
            for (CFOFragment *fragment in replacementFragments) {
                destinationRange.length += (fragment.string.length - fragment.inputRange.length);
            }
            
            NSString *formattedSubstring = [formattedString substringWithRange:destinationRange];
            
            CFOFragment *fragment = [CFOFragment fragmentWithInputRange:modifiedRange string:formattedSubstring];
            [fragments addObject:fragment];
        }
        
    }
    else {
        if (outError) {
            if (taskTimeOutReached) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"Clang Formatter error:\nTask was terminated because the time-out was reached.", nil)};
                *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterTimeOutError userInfo:userInfo];
            }
            else {
                NSString *errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
                if (errorString.length == 0) {
                    errorString = NSLocalizedString(@"Unknown Error", nil);
                }
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Clang Formatter error:\n%@", nil), errorString]};
                *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
            }
        }
        return nil;
    }
    
    return [fragments copy];
}

#pragma mark - CFOClangFormatter

+ (NSArray *)predefinedStyles {
    return @[CFOClangStylePredefinedLLVM, CFOClangStylePredefinedGoogle, CFOClangStylePredefinedChromium, CFOClangStylePredefinedMozilla, CFOClangStylePredefinedWebKit];
}

+ (NSData *)factoryStyleConfigurationBasedOnStyle:(NSString *)style error:(NSError **)outError {
    NSError *error = nil;
    
    NSURL *executableURL = [[self class] resolvedExecutableURLWithError:&error];
    if (outError) *outError = error;
    
    if (!executableURL) {
        return nil;
    }
    
    NSMutableArray *args = [NSMutableArray array];
    
    [args addObject:@"-dump-config"];
    if (style) {
        [args addObject:[NSString stringWithFormat:@"-style=%@",style]];
    }
    
    NSPipe *outputPipe = NSPipe.pipe;
    NSPipe *errorPipe = NSPipe.pipe;
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = executableURL.path;
    task.arguments = args;
    
    task.standardOutput = outputPipe;
    task.standardError = errorPipe;
    
    [task launch];
    
    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
    
    [task waitUntilExit];
    
    int status = [task terminationStatus];
    
    if (status == 0) {
        
        if (errorData.length > 0) {
            NSString *warning = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            BBLogRelease(@"Parser Warning: %@", warning);
        }
        
        return outputData;
    }
    else {
        if (outError) {
            NSString *errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            if (!errorString) {
                errorString = NSLocalizedString(@"Unknown Error", nil);
            }
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Clang Formatter error:\n%@", nil), errorString]};
            *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
        }
        return nil;
    }
    
    return nil;
}

@end
