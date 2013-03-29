//
//  BBUncrustify.h
//  BBUncrustifyPlugin
//
//  Created by Benoît on 16/03/13.
//
//

// Code inspired by https://github.com/ryanmaxwell/UncrustifyX

#import <Foundation/Foundation.h>

@interface BBUncrustify : NSObject

+ (NSString *)uncrustifyCodeFragment:(NSString *)codeFragment;
+ (void)uncrustifyFilesAtURLs:(NSArray *)fileURLs;
+ (NSURL *)uncrustifyXApplicationURL;
+ (NSURL *)configurationFileURL; // returns the config file URL actually used by Uncrustify.
+ (NSURL *)builtInConfigurationFileURL; // returns the default config file URL of the plugin.
+ (NSArray *)proposedConfigurationFileURLs; // returns suggested custom config file URLs.
@end
