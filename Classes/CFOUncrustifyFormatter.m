//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "CFOUncrustifyFormatter.h"
#import <Cocoa/Cocoa.h>
#import "BBMacros.h"

@implementation CFOUncrustifyFormatter

#pragma mark - CFOFormatterProtocol

+ (NSArray *)searchedURLsForExecutable {
    return @[
             [NSURL fileURLWithPath:@"/usr/local/bin/uncrustify"],
             [NSURL fileURLWithPath:@"/usr/bin/uncrustify"],
             ];
}

- (NSArray *)fragmentsByFormattingInputAtRanges:(NSArray *)ranges error:(NSError **)outError {
    
    NSError *error = nil;
    
    NSURL *executableURL = [[self class] resolvedExecutableURLWithError:&error];
    if (outError) *outError = error;
    
    if (!executableURL) {
        return nil;
    }
    
    NSURL *temporaryFolderURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:[[NSUUID UUID] UUIDString] isDirectory:YES];
    [[NSFileManager defaultManager] createDirectoryAtPath:temporaryFolderURL.path withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error) {
        if (outError) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Unable to create the temporary folder (`%@`) for Uncrustify. Error: %@.", nil), temporaryFolderURL.path, error.localizedDescription]};
            *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
        }
        return nil;
    }
    
    //[[NSWorkspace sharedWorkspace] openURL:temporaryFolderURL];
    
    NSArray *normalizedRanges = [self normalizedRangesForInputRanges:ranges];
    
    NSMutableArray *fragments = [NSMutableArray array];
    
    NSMutableArray *args = [NSMutableArray array];
    
    [args addObject:@"--no-backup"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.presentedURL.path]) {
        NSString *uti = [[NSWorkspace sharedWorkspace] typeOfFile:self.presentedURL.path error:&error];
        if (!uti) {
            if (outError) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Unable to find the UTI of the file `%@`. Error: %@.", nil), self.presentedURL.path, error.localizedDescription]};
                *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
            }
            return nil;
        }
        BOOL isObjectiveCFile = ([[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeObjectiveCSource]
                                 || [[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeCHeader]);
        if (isObjectiveCFile) {
            [args addObjectsFromArray:@[@"-l", @"OC"]];
        }
    }
    
    BOOL isFragmented = NO;
    
    if (normalizedRanges.count == 1) {
        NSRange range = [normalizedRanges.firstObject rangeValue];
        isFragmented = (range.length < self.inputString.length);
    }
    else {
        isFragmented = YES;
    }
    
    if (isFragmented) {
        [args addObject:@"--frag"];
    }
    
    if (self.configurationFileURL && [[NSFileManager defaultManager] fileExistsAtPath:self.configurationFileURL.path]) {
        
        NSURL *configurationFileURL = self.configurationFileURL;
        
        if (!isFragmented) {
            NSString *configuration = [[NSString alloc] initWithContentsOfURL:self.configurationFileURL encoding:NSUTF8StringEncoding error:&error];
            if (!configuration) {
                if (outError) {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Unable to load the Uncrustify configuration `%@`. Error: %@.", nil), self.configurationFileURL.path, error.localizedDescription]};
                    *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
                }
                return nil;
            }
            BOOL hasChanged = NO;
            NSString *modifiedConfiguration = [[self class] configurationByRemovingOptions:@[@"cmt_insert_file_"] fromConfiguration:configuration hasChanged:&hasChanged];

            if (hasChanged) {
                configurationFileURL = [temporaryFolderURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.cfg", [[NSUUID UUID] UUIDString]] isDirectory:NO];
                [modifiedConfiguration writeToURL:configurationFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
                if (error) {
                    if (outError) {
                        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Unable to write the Uncrustify configuration to `%@`. Error: %@.", nil), configurationFileURL.path, error.localizedDescription]};
                        *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
                    }
                    return nil;
                }
            }
        }
        
        [args addObjectsFromArray:@[@"-c", configurationFileURL.path]];

    }
    
    NSString *sourceFilename = (self.presentedURL) ? self.presentedURL.lastPathComponent : @"sourcecode";
    NSURL *sourceFileURL = [temporaryFolderURL URLByAppendingPathComponent:sourceFilename isDirectory:NO];

    [args addObject:sourceFileURL.path];
    
    for (NSValue *rangeValue in normalizedRanges) {
        NSRange range = [rangeValue rangeValue];
        
        NSString *substring = [self.inputString substringWithRange:range];
        [substring writeToURL:sourceFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) {
            if (outError) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Unable to write the temporary source code for Uncrustify to `%@`. Error: %@.", nil), sourceFileURL.path, error.localizedDescription]};
                *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
            }
            return nil;
        }
        
        NSPipe *errorPipe = NSPipe.pipe;
        
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = executableURL.path;
        task.arguments = args;
        
        task.standardError = errorPipe;
        
        [task launch];
        
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        
        [task waitUntilExit];
        
        int status = [task terminationStatus];
        
        if (status == 0) {
            
            NSString *formattedSubstring = [NSString stringWithContentsOfURL:sourceFileURL encoding:NSUTF8StringEncoding error:&error];
            if (!formattedSubstring) {
                if (outError) {
                    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Unable to read the uncrustified source code `%@`. Error: %@.", nil), sourceFileURL.path, error.localizedDescription]};
                    *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
                }
                return nil;
            }
            
            CFOFragment *fragment = [CFOFragment fragmentWithInputRange:range string:formattedSubstring];
            [fragments addObject:fragment];
            
        }
        else {
            if (outError) {
                NSString *errorString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
                if (errorString) {
                    // trick to avoid to have less verbose error messages.
                    errorString = [errorString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",temporaryFolderURL.path] withString:@""];
                }
                else {
                    errorString = NSLocalizedString(@"Unknown error while running the formatter.", nil);
                }
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Uncrustify Formatter error:\n%@", nil), errorString]};
                *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
            }
            [[NSFileManager defaultManager] removeItemAtURL:temporaryFolderURL error:nil];
            return nil;
        }
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:temporaryFolderURL error:nil];
    
    return [fragments copy];
}

#pragma mark - CFOUncrustifyFormatter

+ (NSString *)configurationByRemovingOptions:(NSArray *)options fromConfiguration:(NSString *)originalConfiguration hasChanged:(BOOL *)outHasChanged {
    __block BOOL hasChanged = NO;
    
    NSMutableString *mString = [NSMutableString string];
    
    [originalConfiguration enumerateSubstringsInRange:NSMakeRange(0, originalConfiguration.length) options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        NSString *line = [[substring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
        BOOL optionFound = NO;
        for (NSString * option in options) {
            NSRange range = [line rangeOfString:option options:NSCaseInsensitiveSearch | NSAnchoredSearch];
            optionFound = (range.location != NSNotFound);
            if (optionFound) {
                hasChanged = YES;
                break;
            }
        }
        if (!optionFound) {
            [mString appendString:substring];
            [mString appendString:@"\n"];
        }
    }];
    
    if (outHasChanged != NULL) {
        *outHasChanged = hasChanged;
    }
    
    return [NSString stringWithString:mString];
}

+ (NSData *)factoryStyleConfigurationWithComments:(BOOL)includeComments error:(NSError **)outError {
    NSError *error = nil;
    
    NSURL *executableURL = [[self class] resolvedExecutableURLWithError:&error];
    if (outError) *outError = error;
    
    if (!executableURL) {
        return nil;
    }
    
    NSMutableArray *args = [NSMutableArray array];
    
    if (includeComments) {
        [args addObject:@"--update-config-with-doc"];
    }
    else {
        [args addObject:@"--update-config"];
    }
    
    [args addObjectsFromArray:@[@"-c", @"/dev/null"]];
    
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
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Uncrustify Formatter error:\n%@", nil), errorString]};
            *outError = [NSError errorWithDomain:CFOErrorDomain code:CFOFormatterFailureError userInfo:userInfo];
        }
        return nil;
    }
    
    return nil;
}

@end
