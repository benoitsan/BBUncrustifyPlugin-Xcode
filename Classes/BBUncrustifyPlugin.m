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

@implementation BBUncrustifyPlugin

#pragma mark - Setup and Teardown

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[self alloc] init];
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
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Open with UncrustifyX" action:@selector(openWithUncrustifyX:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];
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
}

- (IBAction)uncrustifyActiveFile:(id)sender {
    if (![[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return;
    }

    IDESourceCodeEditor *editor = [BBXcode currentEditor];
    IDESourceCodeDocument *document = [editor sourceCodeDocument];
    [BBXcode uncrustifyCodeOfDocument:document];
}

- (IBAction)uncrustifySelectedLines:(id)sender {
    if (![[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return;
    }
    
    IDESourceCodeEditor *editor = [BBXcode currentEditor];
    IDESourceCodeDocument *document = [editor sourceCodeDocument];
    DVTSourceTextStorage *textStorage = [document textStorage];
    NSArray *selectedRanges = [editor.textView selectedRanges];
    [BBXcode uncrustifyCodeAtRanges:selectedRanges document:document];
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
            if (textStorage.string) {
                [[NSPasteboard pasteboardWithName:@"BBUncrustifyPlugin-source-code"] writeObjects:@[textStorage.string]];
            }
            else {
                [[NSPasteboard pasteboardWithName:@"BBUncrustifyPlugin-source-code"] clearContents];
            }
        }
        NSDictionary* configuration = @{NSWorkspaceLaunchConfigurationArguments : @[[NSString stringWithFormat:@"-bbuncrustifyplugin -configpath %@",configurationFileURL.path]]};
        [[NSWorkspace sharedWorkspace]launchApplicationAtURL:appURL options:0 configuration:configuration error:nil];
    }
}


#pragma mark - NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(uncrustifySelectedFiles:)) {
        return ([BBXcode selectedObjCFileNavigableItems].count > 0);
    }
    else if ([menuItem action] == @selector(uncrustifyActiveFile:)) {
        return ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]);
    }
    else if ([menuItem action] == @selector(uncrustifySelectedLines:)) {
        BOOL validated = NO;
        if ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
            IDESourceCodeEditor *editor = [BBXcode currentEditor];
            IDESourceCodeDocument *document = [editor sourceCodeDocument];
            DVTSourceTextStorage *textStorage = [document textStorage];
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

@end
