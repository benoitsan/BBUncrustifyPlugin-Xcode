//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import <Sparkle/Sparkle.h>

// PS: Updater preferences can be found at path ~/Library/Preferences/com.pragmaticcode.UncrustifyPlugin.plist

// Automatically checking for update is disabled to avoid to pop the update panel when Xcode is launched.
// The strategy is to suggest an update when the plugin is really used.

@interface BBPluginUpdater : SUUpdater

+ (instancetype)sharedUpdater;

- (void)checkForUpdatesIfNeeded;

@end
