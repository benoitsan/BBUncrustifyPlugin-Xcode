//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFDefaults.h"
#import "CFOClangFormatter.h"

NSString * const XCFDefaultsKeySelectedFormatter = @"XCFSelectedFormatter";
NSString * const XCFDefaultsFormatterValueClang = @"clang";
NSString * const XCFDefaultsFormatterValueUncrustify = @"uncrustify";

NSString * const XCFDefaultsKeyXcodeIndentingEnabled = @"XCFXcodeIdentingEnabled";
NSString * const XCFDefaultsKeyFormatOnSaveEnabled = @"XCFFormatOnSaveEnabled";
NSString *const XCFDefaultsKeyFormatOnSaveFiletypes = @"XCFFormatOnSaveFiletypes";
NSString * const XCFDefaultsKeyClangStyle = @"XCFClangStyle";

NSString * const XCFDefaultsKeyClangFactoryBasedStyle = @"XCFClangFactoryBasedStyle";
NSString * const XCFDefaultsClangFactoryBasedStyleValueNone = @"none";

NSString * const XCFDefaultsKeyConfigurationEditorIdentifier = @"XCFConfigEditorIdentifier";
NSString * const XCFDefaultsKeyUncrustifyXEnabled = @"XCFUncrustifyXEnabled";

@implementation XCFDefaults

+ (NSDictionary*)defaultValues {

    return @{
         XCFDefaultsKeySelectedFormatter : XCFDefaultsFormatterValueUncrustify,
         XCFDefaultsKeyXcodeIndentingEnabled : @(NO),
         XCFDefaultsKeyFormatOnSaveEnabled : @(NO),
         XCFDefaultsKeyFormatOnSaveFiletypes : @"c;m;mm;cpp;h;hpp",
         XCFDefaultsKeyClangStyle : CFOClangStylePredefinedLLVM,
         XCFDefaultsKeyUncrustifyXEnabled : @(YES),
         XCFDefaultsKeyClangFactoryBasedStyle : CFOClangStylePredefinedLLVM
    };
    
}

+ (void)registerDefaults {
    
    [[[self class]defaultValues] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![[NSUserDefaults standardUserDefaults] objectForKey:key]) {
            [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
        }
    }];
    
}

+ (void)debug_clearPreferences {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeySelectedFormatter];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyXcodeIndentingEnabled];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyFormatOnSaveEnabled];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyFormatOnSaveFiletypes];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyClangStyle];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyClangFactoryBasedStyle];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyConfigurationEditorIdentifier];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyUncrustifyXEnabled];
}

@end
