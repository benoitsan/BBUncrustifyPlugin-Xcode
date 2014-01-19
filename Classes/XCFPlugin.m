//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFPlugin.h"
#import "XCFXcodeFormatter.h"
#import "XCFDefaults.h"
#import "XCFPreferencesWindowController.h"
#import "BBPluginUpdater.h"
#import "NSDocument+BBUncrustify.h"

@interface XCFPlugin ()
@property (nonatomic, readonly) XCFPreferencesWindowController *preferencesWindowController;
@end

@implementation XCFPlugin {}

@synthesize preferencesWindowController = _preferencesWindowController;

#pragma mark - Setup and Teardown

static XCFPlugin *sharedPlugin = nil;

+ (void)pluginDidLoad:(NSBundle *)plugin {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    sharedPlugin = [[self alloc] init];
	    [XCFDefaults registerDefaults];
	});
}

- (XCFPreferencesWindowController *)preferencesWindowController {
	if (!_preferencesWindowController) {
		_preferencesWindowController = [[XCFPreferencesWindowController alloc] init];
	}
	return _preferencesWindowController;
}

- (id)init {
	self  = [super init];
	if (self) {
		NSMenuItem *editMenuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
		if (editMenuItem) {
			[[editMenuItem submenu] addItem:[NSMenuItem separatorItem]];

			NSMenuItem *menuItem;
			menuItem = [[NSMenuItem alloc] initWithTitle:@"Format Selected Files" action:@selector(formatSelectedFiles:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[[editMenuItem submenu] addItem:menuItem];

			menuItem = [[NSMenuItem alloc] initWithTitle:@"Format Active File" action:@selector(formatActiveFile:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[[editMenuItem submenu] addItem:menuItem];

			menuItem = [[NSMenuItem alloc] initWithTitle:@"Format Selected Lines" action:@selector(formatSelectedLines:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[[editMenuItem submenu] addItem:menuItem];

			menuItem = [[NSMenuItem alloc] initWithTitle:@"Format On Save" action:@selector(toggleFormatOnSave:) keyEquivalent:@""];
			[menuItem setTarget:self];
			BOOL bChecked = [[NSUserDefaults standardUserDefaults] boolForKey:XCFDefaultsKeyFormatOnSave];
			[NSDocument setApplyFormatOnSave:bChecked];
			[menuItem setState:bChecked ? NSOnState:NSOffState];
			[[editMenuItem submenu] addItem:menuItem];

			menuItem = [NSMenuItem separatorItem];
			[[editMenuItem submenu] addItem:menuItem];

			menuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Configuration" action:@selector(launchConfigurationEditor:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[[editMenuItem submenu] addItem:menuItem];

			menuItem = [[NSMenuItem alloc] initWithTitle:@"BBUncrustifyPlugin Preferences…" action:@selector(showPreferences:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[[editMenuItem submenu] addItem:menuItem];

			[BBPluginUpdater sharedUpdater].delegate = self;

			NSLog(@"BBUncrustifyPlugin (V%@) loaded", [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]);
		}
	}
	return self;
}

#pragma mark - Actions

- (IBAction)formatSelectedFiles:(id)sender {
	NSError *error = nil;
	[XCFXcodeFormatter formatSelectedFilesWithError:&error];
	if (error) {
		[[NSAlert alertWithError:error] runModal];
	}
	[[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)formatActiveFile:(id)sender {
	//[self.preferencesWindowController showWindow:nil];
	NSError *error = nil;
	[XCFXcodeFormatter formatActiveFileWithError:&error];
	if (error) {
		[[NSAlert alertWithError:error] runModal];
	}
	[[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)formatSelectedLines:(id)sender {
	NSError *error = nil;
	[XCFXcodeFormatter formatSelectedLinesWithError:&error];
	if (error) {
		[[NSAlert alertWithError:error] runModal];
	}
	[[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)toggleFormatOnSave:(id)sender {
	//toggle it
	BOOL bChecked = [sender state] ? NSOnState : NSOffState;
	bChecked = !bChecked;
	[sender setState:bChecked ? NSOnState:NSOffState];

	//save the new state
	[NSDocument setApplyFormatOnSave:bChecked];
	[[NSUserDefaults standardUserDefaults] setBool:bChecked forKey:XCFDefaultsKeyFormatOnSave];
}

- (IBAction)launchConfigurationEditor:(id)sender {
	NSError *error = nil;
	[XCFXcodeFormatter launchConfigurationEditorWithError:&error];
	if (error) {
		if ([error.domain isEqualToString:XCFErrorDomain] && error.code == XCFFormatterMissingConfigurationError) {
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Configuration File Not Found", nil)
			                                 defaultButton:NSLocalizedString(@"Open Preferences…", nil)
			                               alternateButton:NSLocalizedString(@"Cancel", nil)
			                                   otherButton:nil
			                     informativeTextWithFormat:error.localizedDescription, nil];

			if ([alert runModal] == NSAlertDefaultReturn) {
				[self.preferencesWindowController showWindow:nil];
			}
		}
		else {
			[[NSAlert alertWithError:error] runModal];
		}
	}
	[[BBPluginUpdater sharedUpdater] checkForUpdatesIfNeeded];
}

- (IBAction)showPreferences:(id)sender {
	[self.preferencesWindowController showWindow:nil];
}

#pragma mark - NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	if ([menuItem action] == @selector(formatSelectedFiles:)) {
		return [XCFXcodeFormatter canFormatSelectedFiles];
	}
	else if ([menuItem action] == @selector(formatActiveFile:)) {
		return [XCFXcodeFormatter canFormatActiveFile];
	}
	else if ([menuItem action] == @selector(formatSelectedLines:)) {
		return [XCFXcodeFormatter canFormatSelectedLines];
	}
	else if ([menuItem action] == @selector(launchConfigurationEditor:)) {
		NSString *formatter = @"";
		NSString *selectedFormatter = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeySelectedFormatter];
		if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueClang]) {
			formatter = @"Clang";
		}
		else if ([selectedFormatter isEqualToString:XCFDefaultsFormatterValueUncrustify]) {
			formatter = @"Uncrustify";
		}

		menuItem.title = [NSString stringWithFormat:@"Edit %@ Configuration", formatter];

		return [XCFXcodeFormatter canLaunchConfigurationEditor];
	}
	return YES;
}

#pragma mark - SUUpdater Delegate

- (NSString *)pathToRelaunchForUpdater:(SUUpdater *)updater {
	return [[NSBundle mainBundle].bundleURL path];
}

@end
