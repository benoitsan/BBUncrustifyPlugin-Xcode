//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFPreferencesWindowController.h"
#import "XCFDefaults.h"
#import "XCFClangFormatter.h"
#import "XCFUncrustifyFormatter.h"

static NSString * const kFormatterKeyTitle = @"title";
static NSString * const kFormatterKeyIdentifier = @"identifier";

static NSString * const kFormatterStyleKeyTitle = @"title";
static NSString * const kFormatterStyleKeyIdentifier = @"identifier";

@interface XCFPreferencesWindowController ()
@property (nonatomic, readonly) NSArray *formatters;

@property (nonatomic, weak) IBOutlet NSPopUpButton *clangStylePopUpButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *configurationEditorPopUpButton;
@property (nonatomic, weak) IBOutlet NSView *clangFactoryConfigurationAccessoryView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *clangStyleForFactoryConfigurationPopupButton;
@property (nonatomic, weak) IBOutlet NSTextField *pluginVersionTextField;

@end

@implementation XCFPreferencesWindowController

@synthesize formatters = _formatters;

- (void)awakeFromNib {
    [self updateClangStyles];
    [self updateConfigurationsEditors];
    
    
    self.pluginVersionTextField.stringValue = [NSString stringWithFormat:@"Version %@",[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"]];
}

- (NSArray *)formatters {
    if (!_formatters) {
        _formatters = @[
            @{kFormatterKeyTitle : @"Clang", kFormatterKeyIdentifier : XCFDefaultsFormatterValueClang},
            @{kFormatterKeyTitle : @"Uncrustify", kFormatterKeyIdentifier : XCFDefaultsFormatterValueUncrustify}
        ];
    }
    return _formatters;
}


- (void)updateClangStyles {
    
    NSArray *predefinedStyles = [[CFOClangFormatter predefinedStyles] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [self.clangStylePopUpButton removeAllItems];
    
    NSMenuItem *menuItem = nil;
    
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Predefined Styles:", nil) action:nil keyEquivalent:@""];
    [menuItem setEnabled:NO];
    [self.clangStylePopUpButton.menu addItem:menuItem];
    
    for (NSString *style in predefinedStyles) {
        menuItem = [[NSMenuItem alloc] initWithTitle:style action:nil keyEquivalent:@""];
        menuItem.representedObject = style;
        [self.clangStylePopUpButton.menu addItem:menuItem];
    }
    
    [self.clangStylePopUpButton.menu addItem:[NSMenuItem separatorItem]];
    
    menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Custom Style (File)", nil) action:nil keyEquivalent:@""];
    menuItem.representedObject = CFOClangStyleFile;
    [self.clangStylePopUpButton.menu addItem:menuItem];
    
    NSString *selectedStyle = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeyClangStyle];
    for (menuItem in self.clangStylePopUpButton.itemArray) {
        if (menuItem.representedObject && [menuItem.representedObject isEqualToString:selectedStyle]) {
            [self.clangStylePopUpButton selectItem:menuItem];
            break;
        }
    }
    
}

- (void)updateConfigurationsEditors {
    
    [self.configurationEditorPopUpButton removeAllItems];
    
    NSArray *identifiers = CFBridgingRelease(LSCopyAllRoleHandlersForContentType((CFStringRef)@"public.text", kLSRolesAll));
    
    NSString *selectedIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeyConfigurationEditorIdentifier];
    
    if (selectedIdentifier && ![identifiers containsObject:selectedIdentifier]) {
        identifiers = [identifiers arrayByAddingObject:selectedIdentifier];
    }
    
    NSMutableArray *applications = [NSMutableArray array];

    for (NSString *identifier in identifiers) {
        NSURL *url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:identifier];
        NSString *name = nil;
        NSImage *icon = nil;
        if (url) {
            name = [[NSFileManager defaultManager] displayNameAtPath:url.path];
            icon = [[NSWorkspace sharedWorkspace] iconForFile:url.path];
            icon.size = NSMakeSize(16.0, 16.0);
        }
        if (name && icon) {
            NSDictionary *dic = @{@"identifier" : identifier, @"name" : name, @"icon" : icon};
            [applications addObject:dic];
        }
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [applications sortUsingDescriptors:@[descriptor]];
    
    for (NSDictionary *application in applications) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:application[@"name"] action:nil keyEquivalent:@""];
        menuItem.image = application[@"icon"];
        menuItem.representedObject = application[@"identifier"];
        [self.configurationEditorPopUpButton.menu addItem:menuItem];
    }
    
    if (applications.count > 0) {
        [self.configurationEditorPopUpButton.menu addItem:[NSMenuItem separatorItem]];
    }
    
    {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Select Application…", nil) action:nil keyEquivalent:@""];
        menuItem.representedObject = nil;
        [self.configurationEditorPopUpButton.menu addItem:menuItem];
    }
    
    [self.configurationEditorPopUpButton selectItem:self.configurationEditorPopUpButton.itemArray.lastObject];
    
    if (selectedIdentifier) {
        for (NSMenuItem *menuItem in self.configurationEditorPopUpButton.itemArray) {
            if (menuItem.representedObject && [menuItem.representedObject isEqualToString:selectedIdentifier]) {
                [self.configurationEditorPopUpButton selectItem:menuItem];
                break;
            }
        }
    }
}

- (IBAction)downloadUncrustifXAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/ryanmaxwell/UncrustifyX"]];
}


- (IBAction)aboutPluginAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/benoitsan/BBUncrustifyPlugin-Xcode"]];
}


- (IBAction)selectConfigurationEditorAction:(NSPopUpButton *)sender {
    if (sender.selectedItem.representedObject) {
        [[NSUserDefaults standardUserDefaults] setObject:sender.selectedItem.representedObject forKey:XCFDefaultsKeyConfigurationEditorIdentifier];
    }
    else {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        openPanel.allowedFileTypes = @[(NSString *)kUTTypeApplication];
        openPanel.prompt = NSLocalizedString(@"Select", nil);
        [openPanel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSOKButton) {
                NSBundle * appBundle = [NSBundle bundleWithURL:openPanel.URL];
                NSString *identifier = [appBundle bundleIdentifier];
                if (identifier) {
                    [[NSUserDefaults standardUserDefaults] setObject:identifier forKey:XCFDefaultsKeyConfigurationEditorIdentifier];
                }
            }
            [self updateConfigurationsEditors];
        }];
    }
}

- (IBAction)selectClangStyleAction:(NSPopUpButton *)sender {
    [[NSUserDefaults standardUserDefaults] setObject:sender.selectedItem.representedObject forKey:XCFDefaultsKeyClangStyle];
}

- (IBAction)createConfigurationFileAction:(NSPopUpButton *)sender {
    if (sender.selectedItem.tag == 1) { // CLANG
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        savePanel.nameFieldStringValue = @"_clang-format";
        savePanel.accessoryView = self.clangFactoryConfigurationAccessoryView;
        
        { // Setup Accessory View
            NSPopUpButton *stylePopUpButton = self.clangStyleForFactoryConfigurationPopupButton;
            
            [stylePopUpButton removeAllItems];
            
            NSMenuItem *menuItem = nil;
            
            menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"None", nil) action:nil keyEquivalent:@""];
            menuItem.representedObject = XCFDefaultsClangFactoryBasedStyleValueNone;
            [stylePopUpButton.menu addItem:menuItem];
            
            [stylePopUpButton.menu addItem:[NSMenuItem separatorItem]];
            
            NSArray *predefinedStyles = [[CFOClangFormatter predefinedStyles] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
            
            for (NSString *style in predefinedStyles) {
                menuItem = [[NSMenuItem alloc] initWithTitle:style action:nil keyEquivalent:@""];
                menuItem.representedObject = style;
                [stylePopUpButton.menu addItem:menuItem];
            }
            
            NSString *selectedStyle = [[NSUserDefaults standardUserDefaults] stringForKey:XCFDefaultsKeyClangFactoryBasedStyle];
            for (menuItem in stylePopUpButton.itemArray) {
                if (menuItem.representedObject && [menuItem.representedObject isEqualToString:selectedStyle]) {
                    [stylePopUpButton selectItem:menuItem];
                    break;
                }
            }
            
        }
        
        [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
            
            if (result == NSOKButton) {
                
                NSString *selectedStyle = self.clangStyleForFactoryConfigurationPopupButton.selectedItem.representedObject;
                [[NSUserDefaults standardUserDefaults] setObject:selectedStyle forKey:XCFDefaultsKeyClangFactoryBasedStyle];
                
                NSString *clangStyle = ([selectedStyle isEqualToString:XCFDefaultsClangFactoryBasedStyleValueNone]) ? nil : selectedStyle;
                NSError *error = nil;
                NSData *data = [XCFClangFormatter factoryStyleConfigurationBasedOnStyle:clangStyle error:&error];
                if (data) {
                    [data writeToURL:savePanel.URL options:NSDataWritingAtomic error:&error];
                }
                
                if (error) {
                    [[NSAlert alertWithError:error] runModal];
                }
                
            }
            
        }];
    }
    else if (sender.selectedItem.tag == 2) { // Uncrustify
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        savePanel.nameFieldStringValue = @"uncrustify.cfg";
        
        [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
            
            if (result == NSOKButton) {
                
                NSError *error = nil;
                NSData *data = [XCFUncrustifyFormatter factoryStyleConfigurationWithComments:YES error:&error];
                if (data) {
                    [data writeToURL:savePanel.URL options:NSDataWritingAtomic error:&error];
                }
                
                if (error) {
                    [[NSAlert alertWithError:error] runModal];
                }
                
            }
            
        }];
    }
}


- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (NSString *)windowNibName {
    return NSStringFromClass(self.class);
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
