//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFPlugin.h"
#import "XCFXcodeFormatter.h"
#import "XCFDefaults.h"
#import "XCFPreferencesWindowController.h"
#import "BBPluginUpdater.h"
#import "BBMacros.h"

@interface XCFPlugin()
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

            NSMenu *formatCodeMenu = [[NSMenu alloc] initWithTitle:@"Format Code"];

            NSMenuItem *menuItem;
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Format Selected Files" action:@selector(formatSelectedFiles:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [formatCodeMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"Format Active File" action:@selector(formatActiveFile:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [formatCodeMenu addItem:menuItem];

            menuItem = [[NSMenuItem alloc] initWithTitle:@"Format Selected Lines" action:@selector(formatSelectedLines:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [formatCodeMenu addItem:menuItem];

            [formatCodeMenu addItem:[NSMenuItem separatorItem]];

            menuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Configuration…" action:@selector(launchConfigurationEditor:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [formatCodeMenu addItem:menuItem];
            
            menuItem = [[NSMenuItem alloc] initWithTitle:@"BBUncrustifyPlugin Preferences…" action:@selector(showPreferences:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [formatCodeMenu addItem:menuItem];

            NSMenuItem *formatCodeMenuItem = [[NSMenuItem alloc] initWithTitle:@"Format Code" action:nil keyEquivalent:@""];
            [formatCodeMenuItem setSubmenu:formatCodeMenu];
            [[editMenuItem submenu] addItem:formatCodeMenuItem];

            [BBPluginUpdater sharedUpdater].delegate = self;
            
            BBLogRelease(@"Version %@ loaded", [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]);
        }
    }
    return self;
}

#pragma mark - Actions

- (IBAction)formatSelectedFiles:(id)sender {
    [XCFXcodeFormatter formatSelectedFilesWithEnumerationBlock:^(NSURL *url, NSError *error, BOOL *stop) {
        if (error) {
            [[NSAlert alertWithError:error] runModal];
        }
    }];
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

- (IBAction)launchConfigurationEditor:(id)sender {
    NSError *error = nil;
    [XCFXcodeFormatter launchConfigurationEditorWithError:&error];
    if (error) {
        if ([error.domain isEqualToString:XCFErrorDomain] && error.code == XCFFormatterMissingConfigurationError) {
            
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Configuration File Not Found", nil)
                                             defaultButton:NSLocalizedString(@"Open Preferences…", nil)
                                           alternateButton:NSLocalizedString(@"Cancel", nil)
                                               otherButton:nil
                                 informativeTextWithFormat:error.localizedDescription,nil];
            
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
