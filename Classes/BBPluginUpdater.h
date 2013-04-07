//
//  BBPluginUpdater.h
//  BBUncrustifyPlugin
//
//  Created by Benoît on 07/04/13.
//
//

#import <Sparkle/Sparkle.h>

// PS: Updater preferences can be found at path ~/Library/Preferences/com.pragmaticcode.UncrustifyPlugin.plist

// Automatically checking for update is disabled to avoid to pop the update panel when Xcode is launched.
// The strategy is to suggest an update when the plugin is really used.

@interface BBPluginUpdater : SUUpdater

+ (instancetype)sharedUpdater;

- (void)checkForUpdatesIfNeeded;

@end
