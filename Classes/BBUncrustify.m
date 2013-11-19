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
NSString * const BBUncrustifyOptionSupplementalConfigurationFolders = @"supplementalConfigurationFolders";

static NSString * BBUUIDString() {
#if __has_feature(objc_arc)
    return [[NSUUID UUID] UUIDString]; // ARC is used for Xcode 5.1+, we can use NSUUID available on OS X 10.8+
#else
    NSString *uuidString = nil;
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    if (uuid) {
        uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    }
    return [NSMakeCollectable(uuidString) autorelease];
#endif
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
    
    NSArray *additionalLookupFolderURLs = options[BBUncrustifyOptionSupplementalConfigurationFolders];
    if (additionalLookupFolderURLs.count > 0) {
        NSLog(@"uncrustify additional lookup folders: %@", additionalLookupFolderURLs);
    }
    NSURL *configurationFileURL = [BBUncrustify resolvedConfigurationFileURLWithAdditionalLookupFolderURLs:additionalLookupFolderURLs];
    
    NSLog(@"uncrustify configuration file: %@", configurationFileURL);
    
    if ([options[BBUncrustifyOptionEvictCommentInsertion] boolValue]) {
        NSString *configuration = [[NSString alloc] initWithContentsOfURL:configurationFileURL encoding:NSUTF8StringEncoding error:nil];
        BOOL hasChanged = NO;
        NSString *modifiedConfiguration = [BBUncrustify configurationByRemovingOptions:@[@"cmt_insert_file_"] fromConfiguration:configuration hasChanged:&hasChanged];
#if !__has_feature(objc_arc)
        [configuration release];
#endif
        if (hasChanged) {
            configurationFileURL = [[NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.cfg", BBUUIDString()] isDirectory:NO];
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

+ (NSURL *)builtInConfigurationFileURL {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [bundle URLForResource:@"uncrustify" withExtension:@"cfg"];
}

+ (NSArray *)makeConfigurationFileURLsFromFolderURLs:(NSArray *)folderURLs {
    NSMutableArray *mArray = [NSMutableArray array];
    for (NSURL *folderURL in folderURLs) {
        [mArray addObject:[folderURL URLByAppendingPathComponent:@".uncrustifyconfig" isDirectory:NO]];
        [mArray addObject:[folderURL URLByAppendingPathComponent:@"uncrustify.cfg" isDirectory:NO]];
        [mArray addObject:[[folderURL URLByAppendingPathComponent:@".uncrustify" isDirectory:YES] URLByAppendingPathComponent:@"uncrustify.cfg" isDirectory:NO]];
    }
    return [NSArray arrayWithArray:mArray];
}

+ (NSArray *)userConfigurationFileURLs {
    NSURL *homeDirectoryURL = [NSURL fileURLWithPath:NSHomeDirectory()];
    return [BBUncrustify makeConfigurationFileURLsFromFolderURLs:@[homeDirectoryURL]];
}

+ (NSURL *)resolvedConfigurationFileURLWithAdditionalLookupFolderURLs:(NSArray *)lookupFolderURLs { // additionalLocations can be nil (optional parameter)
    // folders are ordered by priority
    NSMutableArray *configurationURLs = [NSMutableArray array];
    if (lookupFolderURLs) {
        [configurationURLs addObjectsFromArray:[BBUncrustify makeConfigurationFileURLsFromFolderURLs:lookupFolderURLs]];
    }
    [configurationURLs addObjectsFromArray:[BBUncrustify userConfigurationFileURLs]];
    
    for (NSURL *url in configurationURLs) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            return url;
        }
    }
    return [BBUncrustify builtInConfigurationFileURL];
}

+ (NSURL *)builtInExecutableFileURL {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	return [bundle URLForResource:@"uncrustify" withExtension:@""];
}

+ (NSArray *)userExecutableFileURLs {
    NSMutableArray *mArray = [NSMutableArray array];
    [mArray addObject:[NSURL fileURLWithPath:@"/usr/local/bin/uncrustify"]];
    [mArray addObject:[NSURL fileURLWithPath:@"/usr/bin/uncrustify"]];
    return mArray;
}

+ (NSURL *)resolvedExecutableFileURL { 
    // folders are ordered by priority
    for (NSURL *url in [self userExecutableFileURLs]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
            return url;
        }
    }
    return [BBUncrustify builtInExecutableFileURL];
}

+ (void)uncrustifyFilesAtURLs:(NSArray *)fileURLs configurationFileURL:(NSURL *)configurationFileURL {
    //NSLog(@"uncrustify configuration file: %@",configurationFileURL);
    
    NSURL *executableFileURL = [self resolvedExecutableFileURL];
    
    BOOL filesExists = [[NSFileManager defaultManager] fileExistsAtPath:configurationFileURL.path] && [[NSFileManager defaultManager] fileExistsAtPath:configurationFileURL.path];
    
    if (!filesExists) {
        return;
    }
    
    [fileURLs enumerateObjectsWithOptions:0 usingBlock:^(NSURL *fileURL, NSUInteger idx, BOOL *stop) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
            NSMutableArray *args = NSMutableArray.array;
            
            NSString *uti = [[NSWorkspace sharedWorkspace] typeOfFile:fileURL.path error:nil];
            BOOL isObjectiveCFile = ([[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeObjectiveCSource] || [[NSWorkspace sharedWorkspace] type:uti conformsToType:(NSString *)kUTTypeCHeader]);
            if (isObjectiveCFile) {
                [args addObjectsFromArray:@[@"-l", @"OC"]];
            }
            
            [args addObjectsFromArray:@[@"--frag", @"--no-backup"]];
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
#if !__has_feature(objc_arc)
            [task release];
#endif
        }
    }];
}

+ (NSURL *)uncrustifyXApplicationURL {
    return [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:BBUncrustifyXBundleIdentifier];
}

@end
