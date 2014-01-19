//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "BBPluginUpdater.h"

@implementation BBPluginUpdater

+ (instancetype)sharedUpdater {
    return (BBPluginUpdater *)[self updaterForBundle:[NSBundle bundleForClass:[self class]]];
}

- (id)init {
    return [self initForBundle:[NSBundle bundleForClass:[self class]]];
}

- (void)checkForUpdatesIfNeeded {
    NSDate *lastCheckDate = [self lastUpdateCheckDate];
    if (!lastCheckDate) {
        lastCheckDate = [NSDate distantPast];
    }
    
    NSTimeInterval intervalSinceCheck = [[NSDate date] timeIntervalSinceDate:lastCheckDate];
    
    NSTimeInterval updateCheckInterval = [self updateCheckInterval];
    
    //NSLog(@"SPARKLE - intervalSinceCheck %f", intervalSinceCheck);
    //NSLog(@"SPARKLE - updateCheckInterval %f", updateCheckInterval);
    
    if (intervalSinceCheck > updateCheckInterval) {
        //NSLog(@"SPARKLE - checkForUpdates");
        [self checkForUpdatesInBackground]; // this method pops the update panel if an update is available but does nothing is the version is up-to-date.
    }
}

@end
