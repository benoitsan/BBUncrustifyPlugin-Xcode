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

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static BBUncrustifyPlugin *uncrustifyPlugin = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uncrustifyPlugin = [[self alloc] init];
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
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify Active File" action:@selector(uncrustifyActiveFile:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify Selected Lines" action:@selector(uncrustifySelectedLines:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];

            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify And Reindent Selected Lines" action:@selector(uncrustifyAndReindentSelectedLines:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];

            menuItem = [[NSMenuItem alloc] initWithTitle:@"Open with UncrustifyX" action:@selector(openWithUncrustifyX:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];
            
            [BBPluginUpdater sharedUpdater].delegate = self;
            
            NSLog(@"BBUncrustifyPlugin (V%@) loaded",[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]);
        }
    }
    return self;
}

#pragma mark - Actions

- (IBAction)uncrustifySelectedFiles:(id)sender {
    NSArray *fileNavigableItems = [BBXcode selectedObjCFileNavigableItems];
    for (IDEFileNavigableItem *fileNavigableItem in fileNavigableItems) {
        NSDocument *document = [IDEDocumentController retainedEditorDocumentForNavigableItem:fileNavigableItem error:nil];
        if ([document isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            IDESourceCodeDocument *sourceCodeDocument = (IDESourceCodeDocument *)document;
            BOOL uncrustified = [BBXcode uncrustifyCodeOfDocument:sourceCodeDocument];
            if (uncrustified) {
                [document saveDocument:nil];
            }
        }
        [IDEDocumentController releaseEditorDocument:document];
    }
    
    [[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)uncrustifyActiveFile:(id)sender {
    if (![[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return;
    }

    IDESourceCodeEditor *editor = [BBXcode currentEditor];
    IDESourceCodeDocument *document = [editor sourceCodeDocument];
    [BBXcode uncrustifyCodeOfDocument:document];
    
    [[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)uncrustifySelectedLines:(id)sender {
    if (![[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return;
    }
    
    IDESourceCodeEditor *editor = [BBXcode currentEditor];
    IDESourceCodeDocument *document = [editor sourceCodeDocument];
    NSArray *selectedRanges = [editor.textView selectedRanges];
    [BBXcode uncrustifyCodeAtRanges:selectedRanges document:document];
    
    [[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)uncrustifyAndReindentSelectedLines:(id)sender {
    [self uncrustifySelectedLines:sender];

    if (![[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return;
    }

    IDESourceCodeEditor *editor = [BBXcode currentEditor];
    NSTextView *textView = editor.textView;

    // Archive pasteboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSArray *pasteboardItems = [pasteboard pasteboardItems];
	NSMutableArray *archivePasteboardItems = [NSMutableArray arrayWithCapacity:[pasteboardItems count]];

	for (NSPasteboardItem *item in [pasteboard pasteboardItems]) {
        NSPasteboardItem *archiveItem = [[[NSPasteboardItem alloc] init] autorelease];

		for (NSString *type in [item types]) {
			NSData *itemData = [[[item dataForType:type] mutableCopy] autorelease];

            [archiveItem setData:itemData forType:type];

            [archivePasteboardItems addObject:item];
		}
	}

    // Let Xcode re-indent the cleaned code
    [textView selectAll:sender];
    [textView copy:sender];
    [textView paste:sender];
    [textView setSelectedRange:NSMakeRange([[textView string] length], 0)];

    // Restore pasteboard
	[pasteboard clearContents];
	[pasteboard writeObjects:archivePasteboardItems];
}

- (IBAction)openWithUncrustifyX:(id)sender {
    NSURL *appURL = [BBUncrustify uncrustifyXApplicationURL];
    
    NSURL *configurationFileURL = [BBUncrustify configurationFileURL];
    NSURL *builtInConfigurationFileURL = [BBUncrustify builtInConfigurationFileURL];
    if ([configurationFileURL isEqual:builtInConfigurationFileURL]) {
        configurationFileURL = [BBUncrustify proposedConfigurationFileURLs][0];
        NSAlert *alert = [NSAlert alertWithMessageText:@"Custom Configuration File Not Found" defaultButton:@"Create Configuration File & Open UncrustifyX" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Do you want to create a configuration file at this path \n%@",configurationFileURL.path];
        if ([alert runModal] == NSAlertDefaultReturn) {
            [[NSFileManager defaultManager] copyItemAtPath:builtInConfigurationFileURL.path toPath:configurationFileURL.path error:nil];
        }
        else {
            configurationFileURL = nil;
        }
    }
    
    if (configurationFileURL) {
        if ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
            IDESourceCodeEditor *editor = [BBXcode currentEditor];
            IDESourceCodeDocument *document = [editor sourceCodeDocument];
            DVTSourceTextStorage *textStorage = [document textStorage];
            [[NSPasteboard pasteboardWithName:@"BBUncrustifyPlugin-source-code"] clearContents];
            if (textStorage.string) {
                [[NSPasteboard pasteboardWithName:@"BBUncrustifyPlugin-source-code"] writeObjects:@[textStorage.string]];
            }
        }
        NSDictionary* configuration = @{NSWorkspaceLaunchConfigurationArguments : @[@"-bbuncrustifyplugin", @"-configpath", configurationFileURL.path]};
        [[NSWorkspace sharedWorkspace]launchApplicationAtURL:appURL options:0 configuration:configuration error:nil];
    }
    
    [[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}


#pragma mark - NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(uncrustifySelectedFiles:)) {
        return ([BBXcode selectedObjCFileNavigableItems].count > 0);
    }
    else if ([menuItem action] == @selector(uncrustifyActiveFile:)) {
        return ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]);
    }
    else if (([menuItem action] == @selector(uncrustifySelectedLines:)) || ([menuItem action] == @selector(uncrustifyAndReindentSelectedLines:))) {
        BOOL validated = NO;
        if ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
            IDESourceCodeEditor *editor = [BBXcode currentEditor];
            NSArray *selectedRanges = [editor.textView selectedRanges];

            validated = (selectedRanges.count > 0);
        }
        return validated;
    }
    else if ([menuItem action] == @selector(openWithUncrustifyX:)) {
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
