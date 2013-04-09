//
//  BBUncrustify.m
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import "BBUncrustify.h"
#import <Cocoa/Cocoa.h>

static NSString * const BBUncrustifyXBundleIdentifier = @"nz.co.xwell.UncrustifyX";

NSString * const BBUncrustifyOptionEvictCommentInsertion = @"evictCommentInsertion";
NSString * const BBUncrustifyOptionSourceFilename = @"sourceFilename";

static NSString * BBUUIDString() {
    NSString *uuidString = nil;
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    if (uuid) {
        uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    }
    return [NSMakeCollectable(uuidString) autorelease];
}

@interface BBUncrustify ()

@end

@implementation BBUncrustify

+ (NSString *)uncrustifyCodeFragment:(NSString *)codeFragment options:(NSDictionary *)options {
    if (!codeFragment) return nil;
    
    NSString *sourceFileName = options[BBUncrustifyOptionSourceFilename];
    if (!sourceFileName || sourceFileName.length == 0) {
        sourceFileName = @"source";
    }
    
    NSURL *codeFragmentFileURL = [[[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:BBUUIDString() isDirectory:YES] URLByAppendingPathComponent:sourceFileName isDirectory:NO];
    [[NSFileManager defaultManager] createDirectoryAtPath:[codeFragmentFileURL URLByDeletingLastPathComponent].path withIntermediateDirectories:YES attributes:nil error:nil];

    [codeFragment writeToURL:codeFragmentFileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];

    NSURL *configurationFileURL = [BBUncrustify configurationFileURL];

    if ([options[BBUncrustifyOptionEvictCommentInsertion] boolValue]) {
        NSString *configuration = [[NSString alloc] initWithContentsOfURL:configurationFileURL encoding:NSUTF8StringEncoding error:nil];
        BOOL hasChanged = NO;
        NSString *modifiedConfiguration = [BBUncrustify configurationByRemovingOptions:@[@"cmt_insert_file_"] fromConfiguration:configuration hasChanged:& hasChanged];
        if (hasChanged) {
            configurationFileURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.cfg",BBUUIDString()] isDirectory:NO];
            [modifiedConfiguration writeToURL:configurationFileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
    
    [self uncrustifyFilesAtURLs:@[codeFragmentFileURL] configurationFileURL:configurationFileURL];

    NSError *error = nil;
    NSString *result = [NSString stringWithContentsOfURL:codeFragmentFileURL encoding:NSUTF8StringEncoding error:&error];

    if (error) {
        NSLog(@"%@", error);
        return nil;
    }

    return result;
}

+ (NSString *)configurationByRemovingOptions:(NSArray *)options fromConfiguration:(NSString *)originalConfiguration hasChanged:(BOOL *)outHasChanged {
    __block BOOL hasChanged = NO;
    
    NSMutableString *mString = [NSMutableString string];
    
    [originalConfiguration enumerateSubstringsInRange:NSMakeRange(0, originalConfiguration.length) options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        NSString *line = [[substring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
        BOOL optionFound = NO;
        for (NSString *option in options) {
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
    
    if (outHasChanged!=NULL) {
        *outHasChanged = hasChanged;
    }
    
    return [NSString stringWithString:mString];
}

+ (NSURL *)builtInConfigurationFileURL {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [bundle URLForResource:@"uncrustify" withExtension:@"cfg"];
}

+ (NSArray *)proposedConfigurationFileURLs {
    NSURL *homeDirectoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
    NSArray *array = @[[homeDirectoryURL URLByAppendingPathComponent:@".uncrustifyconfig" isDirectory:NO], [homeDirectoryURL URLByAppendingPathComponent:@"uncrustify.cfg" isDirectory:NO]];
    return array;
}

+ (NSURL *)configurationFileURL {
    for (NSURL * url in [BBUncrustify proposedConfigurationFileURLs]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            return url;
        }
    }
    return [BBUncrustify builtInConfigurationFileURL];
}

+ (void)uncrustifyFilesAtURLs:(NSArray *)fileURLs configurationFileURL:(NSURL *)configurationFileURL {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSLog(@"uncrustify configuration file: %@",configurationFileURL);
    
    NSURL *executableFileURL = [bundle URLForResource:@"uncrustify" withExtension:@""];

    BOOL filesExists = [[NSFileManager defaultManager] fileExistsAtPath:configurationFileURL.path] && [[NSFileManager defaultManager] fileExistsAtPath:configurationFileURL.path];

    if (!filesExists) {
        return;
    }

    [fileURLs enumerateObjectsWithOptions:0 usingBlock:^(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
            NSMutableArray *args = NSMutableArray.array;
            [args addObjectsFromArray:@[@"-l", @"OC", @"--frag", @"--no-backup"]];
            [args addObjectsFromArray:@[@"-c", configurationFileURL.path, fileURL.path]];

            NSPipe *outputPipe = NSPipe.pipe;
            NSPipe *errorPipe = NSPipe.pipe;

            NSTask *task = [[NSTask alloc] init];
            task.launchPath = executableFileURL.path;
            task.arguments = args;

            task.standardOutput = outputPipe;
            task.standardError = errorPipe;

            [outputPipe.fileHandleForReading readToEndOfFileInBackgroundAndNotify];
            [errorPipe.fileHandleForReading readToEndOfFileInBackgroundAndNotify];

            [task launch];
            [task waitUntilExit];
            [task release];
        }
    }];
}

+ (NSURL *)uncrustifyXApplicationURL {
    return [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:BBUncrustifyXBundleIdentifier];
}

@end
