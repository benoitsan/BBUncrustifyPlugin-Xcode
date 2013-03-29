//
//  BBUncrustify.m
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import "BBUncrustify.h"
#import <Cocoa/Cocoa.h>

static NSString * BBUUIDString() {
    NSString *uuidString = nil;
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    if (uuid) {
        uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    }
    return [uuidString autorelease];
}

@interface BBUncrustify ()

@end

@implementation BBUncrustify

+ (NSString *)uncrustifyCodeFragment:(NSString *)codeFragment {
    if (!codeFragment) return nil;

    NSURL *codeFragmentFileURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:BBUUIDString() isDirectory:NO];
    [[NSFileManager defaultManager] createDirectoryAtPath:[codeFragmentFileURL URLByDeletingLastPathComponent].path withIntermediateDirectories:YES attributes:nil error:nil];

    [codeFragment writeToURL:codeFragmentFileURL atomically:YES encoding:NSUTF8StringEncoding error:nil];

    [self uncrustifyFilesAtURLs:@[codeFragmentFileURL]];

    NSError *error = nil;
    NSString *result = [NSString stringWithContentsOfURL:codeFragmentFileURL encoding:NSUTF8StringEncoding error:&error];

    if (error) {
        NSLog(@"%@", error);
        return nil;
    }

    return result;
}

+ (NSURL *)configurationFileURL {
    NSURL *homeDirectoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
    
    NSURL *url;
    
    url = [homeDirectoryURL URLByAppendingPathComponent:@"uncrustify.cfg" isDirectory:NO];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        return url;
    }
    
    url = [homeDirectoryURL URLByAppendingPathComponent:@".uncrustifyconfig" isDirectory:NO];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        return url;
    }
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [bundle URLForResource:@"uncrustify" withExtension:@"cfg"];
}

+ (void)uncrustifyFilesAtURLs:(NSArray *)fileURLs {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];

    NSURL *configurationFileURL = [BBUncrustify configurationFileURL];
    NSLog(@"%@",configurationFileURL);
    
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
        }
    }];
}

@end
