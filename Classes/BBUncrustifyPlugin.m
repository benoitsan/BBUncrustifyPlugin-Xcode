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
			NSMenuItem *pluginMenuItem = [[NSMenuItem alloc] initWithTitle:@"Uncrustify" action:@selector(uncrustify:) keyEquivalent:@""];
			[pluginMenuItem setTarget:self];
			[[editMenuItem submenu] addItem:pluginMenuItem];
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
    DVTSourceTextStorage *textStorage = [document textStorage];
    
    //NSLog(@"current selection %@",editor.currentSelectedDocumentLocations);
    
    if (textStorage.string.length > 0) {
        NSString* uncrustifiedCode = [BBUncrustify uncrustifyCodeFragment:textStorage.string];
        [textStorage replaceCharactersInRange:NSMakeRange(0, textStorage.string.length) withString:uncrustifiedCode withUndoManager:[document undoManager]];
    }
}

#pragma mark - NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem action] == @selector(uncrustify:)) {
		return ([[BBXcode currentEditor] isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]);
	}
	return YES;
}

@end
