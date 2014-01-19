//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "CFOFormatter.h"

extern NSString * const CFOClangStyleFile;
extern NSString * const CFOClangStylePredefinedLLVM;
extern NSString * const CFOClangStylePredefinedGoogle;
extern NSString * const CFOClangStylePredefinedChromium;
extern NSString * const CFOClangStylePredefinedMozilla;
extern NSString * const CFOClangStylePredefinedWebKit;

extern NSString * const CFOClangDumpConfigurationOptionsStyle;

@interface CFOClangFormatter : CFOFormatter

+ (NSArray *)predefinedStyles;
+ (NSData *)factoryStyleConfigurationBasedOnStyle:(NSString *)style error:(NSError **)error;

@property (nonatomic) NSString *style;

@end
