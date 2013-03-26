//
//  BBUncrustifyPlugin.m
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import "BBUncrustifyPlugin.h"
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
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify" action:@selector(uncrustify:) keyEquivalent:@"u"];
            menuItem.keyEquivalentModifierMask = NSControlKeyMask;
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];

            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify Selected Files" action:@selector(uncrustifySelectedFiles:) keyEquivalent:@"u"];
            menuItem.keyEquivalentModifierMask = NSControlKeyMask | NSAlternateKeyMask;
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];
        }
    }
    return self;
}

#pragma mark - Actions

- (IBAction)uncrustify:(id)sender {
    if (![[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return;
    }

    IDESourceCodeEditor *editor = [BBXcode currentEditor];
    IDESourceCodeDocument *document = [editor sourceCodeDocument];
    [BBXcode uncrustifyCodeOfDocument:document];
}

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

#pragma mark - NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(uncrustify:)) {
        return ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]);
    } else if ([menuItem action] == @selector(uncrustifySelectedFiles:)) {
        return ([BBXcode selectedObjCFileNavigableItems].count > 0);
    }
    return YES;
}

@end
