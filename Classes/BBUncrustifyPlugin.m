//
//  BBUncrustifyPlugin.m
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import "BBUncrustifyPlugin.h"
#import "BBUncrustify.h"
#import "BBXcode.h"
#import "BBPluginUpdater.h"

@implementation BBUncrustifyPlugin {}

#pragma mark - Setup and Teardown

static BBUncrustifyPlugin *sharedPlugin = nil;

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlugin = [[self alloc] init];
    });
}

- (id)init {
    self  = [super init];
    if (self) {
        NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
        if (editMenuItem) {
            [[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];
            
            NSMenuItem *menuItem;
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify Selected Files" action:@selector(uncrustifySelectedFiles:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];
            [menuItem release];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify Active File" action:@selector(uncrustifyActiveFile:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];
            [menuItem release];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify Selected Lines" action:@selector(uncrustifySelectedLines:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];
            [menuItem release];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Open with UncrustifyX" action:@selector(openWithUncrustifyX:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];
            [menuItem release];
            
            [BBPluginUpdater sharedUpdater].delegate = self;
            
            NSLog(@"BBUncrustifyPlugin (V%@) loaded", [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]);
        }
    }
    return self;
}

#pragma mark - Actions

- (IBAction)uncrustifySelectedFiles:(id)sender {
    NSArray *fileNavigableItems = [BBXcode selectedSourceCodeFileNavigableItems];
    IDEWorkspace *currentWorkspace = [BBXcode currentWorkspaceDocument].workspace;
    for (IDEFileNavigableItem *fileNavigableItem in fileNavigableItems) {
        NSDocument *document = [IDEDocumentController retainedEditorDocumentForNavigableItem:fileNavigableItem error:nil];
        if ([document isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            IDESourceCodeDocument *sourceCodeDocument = (IDESourceCodeDocument *)document;
            BOOL uncrustified = [BBXcode uncrustifyCodeOfDocument:sourceCodeDocument inWorkspace:currentWorkspace];
            if (uncrustified) {
                [document saveDocument:nil];
            }
        }
        [IDEDocumentController releaseEditorDocument:document];
    }
    
    [[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)uncrustifyActiveFile:(id)sender {
    IDESourceCodeDocument *document = [BBXcode currentSourceCodeDocument];
    if (!document) return;
    
    NSTextView *textView = [BBXcode currentSourceCodeTextView];
    
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    // We try to restore the original cursor position after the uncrustification. We compute a percentage value
    // expressing the actual selected line compared to the total number of lines of the document. After the uncrustification,
    // we restore the position taking into account the modified number of lines of the document.
    
    NSRange originalCharacterRange = [textView selectedRange];
    NSRange originalLineRange = [textStorage lineRangeForCharacterRange:originalCharacterRange];
    NSRange originalDocumentLineRange = [textStorage lineRangeForCharacterRange:NSMakeRange(0, textStorage.string.length)];
    
    CGFloat verticalRelativePosition = (CGFloat)originalLineRange.location / (CGFloat)originalDocumentLineRange.length;
    
    IDEWorkspace *currentWorkspace = [BBXcode currentWorkspaceDocument].workspace;
    [BBXcode uncrustifyCodeOfDocument:document inWorkspace:currentWorkspace];
    
    NSRange newDocumentLineRange = [textStorage lineRangeForCharacterRange:NSMakeRange(0, textStorage.string.length)];
    NSUInteger restoredLine = roundf(verticalRelativePosition * (CGFloat)newDocumentLineRange.length);
    
    NSRange newCharacterRange = [textStorage characterRangeForLineRange:NSMakeRange(restoredLine, 0)];
    
    if (newCharacterRange.location < textStorage.string.length) {
        [[BBXcode currentSourceCodeTextView] setSelectedRanges:@[[NSValue valueWithRange:newCharacterRange]]];
        [textView scrollRangeToVisible:newCharacterRange];
    }
    
    [[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)uncrustifySelectedLines:(id)sender {
    IDESourceCodeDocument *document = [BBXcode currentSourceCodeDocument];
    NSTextView *textView = [BBXcode currentSourceCodeTextView];
    if (!document || !textView) return;
    IDEWorkspace *currentWorkspace = [BBXcode currentWorkspaceDocument].workspace;
    NSArray *selectedRanges = [textView selectedRanges];
    [BBXcode uncrustifyCodeAtRanges:selectedRanges document:document inWorkspace:currentWorkspace];
    
    [[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)openWithUncrustifyX:(id)sender {
    NSURL *appURL = [BBUncrustify uncrustifyXApplicationURL];
    
    NSURL *configurationFileURL = [BBUncrustify resolvedConfigurationFileURLWithAdditionalLookupFolderURLs:nil];
    NSURL *builtInConfigurationFileURL = [BBUncrustify builtInConfigurationFileURL];
    if ([configurationFileURL isEqual:builtInConfigurationFileURL]) {
        configurationFileURL = [BBUncrustify userConfigurationFileURLs][0];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Custom Configuration File Not Found" defaultButton:@"Create Configuration File & Open UncrustifyX" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Do you want to create a configuration file at this path \n%@", configurationFileURL.path];
        if ([alert runModal] == NSAlertDefaultReturn) {
            [[NSFileManager defaultManager] copyItemAtPath:builtInConfigurationFileURL.path toPath:configurationFileURL.path error:nil];
        } else {
            configurationFileURL = nil;
        }
    }
    
    if (configurationFileURL) {
        IDESourceCodeDocument *document = [BBXcode currentSourceCodeDocument];
        if (document) {
            DVTSourceTextStorage *textStorage = [document textStorage];
            [[NSPasteboard pasteboardWithName:@"BBUncrustifyPlugin-source-code"] clearContents];
            if (textStorage.string) {
                [[NSPasteboard pasteboardWithName:@"BBUncrustifyPlugin-source-code"] writeObjects:@[textStorage.string]];
            }
        }
        NSDictionary *configuration = @{ NSWorkspaceLaunchConfigurationArguments: @[@"-bbuncrustifyplugin", @"-configpath", configurationFileURL.path] };
        [[NSWorkspace sharedWorkspace]launchApplicationAtURL:appURL options:0 configuration:configuration error:nil];
    }
    
    [[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

#pragma mark - NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(uncrustifySelectedFiles:)) {
        return ([BBXcode selectedSourceCodeFileNavigableItems].count > 0);
    } else if ([menuItem action] == @selector(uncrustifyActiveFile:)) {
        IDESourceCodeDocument *document = [BBXcode currentSourceCodeDocument];
        return (document != nil);
    } else if ([menuItem action] == @selector(uncrustifySelectedLines:)) {
        BOOL validated = NO;
        IDESourceCodeDocument *document = [BBXcode currentSourceCodeDocument];
        NSTextView *textView = [BBXcode currentSourceCodeTextView];
        if (document && textView) {
            NSArray *selectedRanges = [textView selectedRanges];
            validated = (selectedRanges.count > 0);
        }
        return validated;
    } else if ([menuItem action] == @selector(openWithUncrustifyX:)) {
        BOOL appExists = NO;
        NSURL *appURL = [BBUncrustify uncrustifyXApplicationURL];
        if (appURL) appExists = [[NSFileManager defaultManager] fileExistsAtPath:appURL.path];
        [menuItem setHidden:!appExists];
    }
    return YES;
}

#pragma mark - SUUpdater Delegate

- (NSString *)pathToRelaunchForUpdater:(SUUpdater *)updater {
    return [[NSBundle mainBundle].bundleURL path];
}

@end
