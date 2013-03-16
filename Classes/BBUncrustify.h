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

@end
