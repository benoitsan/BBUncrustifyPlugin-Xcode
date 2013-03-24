//
//  BBUncrustifyPlugin.m
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

#import "BBUncrustifyPlugin.h"
#import "BBXcode.h"
#import "BBUncrustify.h"
#import "MWSubstring.h"

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
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify" action:@selector(uncrustify:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];

            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify Selected Files" action:@selector(uncrustifySelectedFiles:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[editMenuItem submenu] addItem:menuItem];

            menuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify Selected Text" action:@selector(uncrustifySelectedText:) keyEquivalent:@""];
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

- (IBAction)uncrustifySelectedText:(id)sender {
    IDESourceCodeEditor *editor = [BBXcode currentEditor];
    NSTextView *sourceTextView = editor.textView;

    if ([sourceTextView isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) {
        NSMutableArray *substrings = [[NSMutableArray alloc] init];
        NSArray *selectedRanges = sourceTextView.selectedRanges;

        // Create substrings from selections
        for (NSValue *value in selectedRanges) {
            NSString *selectedString = [sourceTextView.textStorage.string substringWithRange:[value rangeValue]];
            MWSubstring *substring = [[MWSubstring alloc] initWithString:selectedString rangeValue:[value rangeValue]];

            // -- Insert at beginning to do substitutions from bottom-up, ie. no need to recalculate ranges.
            [substrings insertObject:substring atIndex:0];
        }

        // Do substitutions
        DVTSourceTextStorage *textStorage = (DVTSourceTextStorage *)sourceTextView.textStorage;
        NSUndoManager *undoManager = [editor undoManagerForTextView:sourceTextView];
        for (MWSubstring *substring in substrings) {
            NSString *uncrustifiedString = [BBUncrustify uncrustifyCodeFragment:substring.string];
            [textStorage replaceCharactersInRange:substring.range withString:uncrustifiedString withUndoManager:undoManager];
        }
    }
}

#pragma mark - NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if ([menuItem action] == @selector(uncrustify:)) {
        return ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]);
    } else if ([menuItem action] == @selector(uncrustifySelectedFiles:)) {
        return ([BBXcode selectedObjCFileNavigableItems].count > 0);
    } else if ([menuItem action] == @selector(uncrustifySelectedText:)) {
        if ([[[BBXcode currentEditor] textView] isKindOfClass:NSClassFromString(@"DVTSourceTextView")]) {
            return [[[BBXcode currentEditor] textView] selectedRange].length > 0;
        } else {
            return NO;
        }
    }

    return YES;
}

@end
