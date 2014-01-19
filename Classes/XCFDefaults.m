//
//  Created by Benoît on 11/01/14.
//  Copyright (c) 2014 Pragmatic Code. All rights reserved.
//

#import "XCFDefaults.h"
#import "CFOClangFormatter.h"

NSString *const XCFDefaultsKeySelectedFormatter = @"XCFSelectedFormatter";
NSString *const XCFDefaultsFormatterValueClang = @"clang";
NSString *const XCFDefaultsFormatterValueUncrustify = @"uncrustify";

NSString *const XCFDefaultsKeyXcodeIndentingEnabled = @"XCFXcodeIdentingEnabled";
NSString *const XCFDefaultsKeyClangStyle = @"XCFClangStyle";

NSString *const XCFDefaultsKeyClangFactoryBasedStyle = @"XCFClangFactoryBasedStyle";
NSString *const XCFDefaultsClangFactoryBasedStyleValueNone = @"none";

NSString *const XCFDefaultsKeyFormatOnSave = @"XCFDefaultsKeyFormatOnSave";

NSString *const XCFDefaultsKeyConfigurationEditorIdentifier = @"XCFConfigEditorIdentifier";
NSString *const XCFDefaultsKeyUncrustifyXEnabled = @"XCFUncrustifyXEnabled";

@implementation XCFDefaults

+ (NSDictionary *)defaultValues {
	return @{
             XCFDefaultsKeySelectedFormatter : XCFDefaultsFormatterValueUncrustify,
             XCFDefaultsKeyXcodeIndentingEnabled : @(NO),
             XCFDefaultsKeyClangStyle : CFOClangStylePredefinedLLVM,
             XCFDefaultsKeyUncrustifyXEnabled : @(YES),
             XCFDefaultsKeyClangFactoryBasedStyle : CFOClangStylePredefinedLLVM,
             XCFDefaultsKeyFormatOnSave : @(YES)
             };
}

+ (void)registerDefaults {
	[[[self class]defaultValues] enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
	    if (![[NSUserDefaults standardUserDefaults] objectForKey:key]) {
	        [[NSUserDefaults standardUserDefaults] setObject:obj forKey:key];
		}
	}];
}

+ (void)debug_clearPreferences {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeySelectedFormatter];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyXcodeIndentingEnabled];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyClangStyle];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyClangFactoryBasedStyle];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyFormatOnSave];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyConfigurationEditorIdentifier];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:XCFDefaultsKeyUncrustifyXEnabled];
}

@end
